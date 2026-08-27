import SwiftUI
import SwiftData

enum RecipeListItem: Identifiable {
    case single(RecipeItem)
    case group(String, [RecipeItem])
    
    var id: String {
        switch self {
        case .single(let recipe): return recipe.id.uuidString
        case .group(let name, _): return name
        }
    }
    
    var name: String {
        switch self {
        case .single(let recipe): return recipe.name
        case .group(let name, _): return name
        }
    }
}

struct RecipeBankView: View {
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecipeItem.name) private var recipes: [RecipeItem]
    
    @State private var recipeToEdit: RecipeItem?
    @State private var recipeToLog: RecipeItem?
    @State private var customizedIngredients: [RecipeIngredient] = []
    @State private var adjustedAmount: Double = 0.0
    
    @State private var recipeToFullEdit: RecipeItem?
    @State private var recipeToCreateVariation: RecipeItem?
    @State private var expandedItemIDs: Set<String> = []
    @State private var recipeNeedingWeight: RecipeItem?
    @State private var showingWeightAlert = false
    // Extras flow state
    @State private var recipeToAddExtras: RecipeItem?
    @State private var portionBaseCalories: Int = 0
    @State private var portionBaseFat: Double = 0
    @State private var portionBaseSaturatedFat: Double = 0
    @State private var portionBaseTransFat: Double = 0
    @State private var portionBaseProtein: Double = 0
    @State private var portionBaseCarb: Double = 0
    @State private var portionBaseDietaryFiber: Double = 0
    @State private var portionBaseAddedSugar: Double = 0
    
    // Pre-defined additives sequential flow state
    @State private var additivesToConfirm: [RecipeIngredient] = []
    @State private var confirmedAdditives: [RecipeIngredient] = []
    @State private var additiveConfirmationIndex: Int = 0
    @State private var currentAdditiveToConfirm: RecipeIngredient?
    @State private var adjustedAdditiveAmount: Double = 0.0
    @State private var recipeBeingLogged: RecipeItem?
    
    // Batch-level totals for the current customizedIngredients — scaled to 1 serving
    private var customizedServingRatio: Double {
        guard let recipe = recipeToLog ?? recipeToEdit ?? recipeToAddExtras else { return 1.0 }
        guard let serving = recipe.servingSize, serving > 0 else { return 1.0 }
        
        if recipe.measurementType == .weight {
            let customTBW = recipe.customBatchWeight ?? customizedIngredients.reduce(0.0) { $0 + $1.recipeWeight }
            return customTBW > 0 ? (serving / customTBW) : 1.0
        } else {
            if serving < 1.0 { return serving }
            else { return 1.0 / serving }
        }
    }
    
    private var groupedRecipes: [RecipeListItem] {
        var groups: [String: [RecipeItem]] = [:]
        var singles: [RecipeItem] = []
        
        for recipe in recipes {
            if let groupName = recipe.recipeVariationGroup, !groupName.isEmpty {
                groups[groupName, default: []].append(recipe)
            } else {
                singles.append(recipe)
            }
        }
        
        var result: [RecipeListItem] = singles.map { .single($0) }
        for (groupName, items) in groups {
            result.append(.group(groupName, items))
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    private var servingBaseCalories: Int {
        let total = customizedIngredients.reduce(0.0) { sum, ing in
            let r = ing.servingSize > 0 ? (ing.recipeWeight / ing.servingSize) : 1.0
            return sum + (Double(ing.calories) * r)
        }
        return Int(round(total * customizedServingRatio))
    }
    private var servingBaseFat: Double {
        let total = customizedIngredients.reduce(0.0) { sum, ing in
            let r = ing.servingSize > 0 ? (ing.recipeWeight / ing.servingSize) : 1.0
            return sum + (ing.fat * r)
        }
        return total * customizedServingRatio
    }
    private var servingBaseCarb: Double {
        let total = customizedIngredients.reduce(0.0) { sum, ing in
            let r = ing.servingSize > 0 ? (ing.recipeWeight / ing.servingSize) : 1.0
            return sum + (ing.carb * r)
        }
        return total * customizedServingRatio
    }
    private var servingBaseProtein: Double {
        let total = customizedIngredients.reduce(0.0) { sum, ing in
            let r = ing.servingSize > 0 ? (ing.recipeWeight / ing.servingSize) : 1.0
            return sum + (ing.protein * r)
        }
        return total * customizedServingRatio
    }
    
    var body: some View {
        NavigationStack {
            List {
                if recipes.isEmpty {
                    Text("No recipes saved yet. Create one in the Add Recipe tab!")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(groupedRecipes) { item in
                        switch item {
                        case .single(let recipe):
                            recipeRow(recipe)
                        case .group(let groupName, let items):
                            groupRow(groupName: groupName, items: items)
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
            // "Log Edited Recipe" path: weights editor → portion selector
            .sheet(item: $recipeToEdit) { recipe in
                RecipeWeightsHalfSheetSelector(
                    initialIngredients: recipe.ingredients,
                    onNext: { customIngredients in
                        customizedIngredients = customIngredients
                        adjustedAmount = recipe.measurementType == .fraction ? 1.0 : (recipe.servingSize ?? recipe.customBatchWeight ?? customIngredients.reduce(0) { $0 + $1.recipeWeight })
                        // Small delay to allow the first sheet to dismiss smoothly before the next appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            recipeToLog = recipe
                        }
                    }
                )
            }
            // Shared portion selector — used by both "Log Recipe" and "Log Edited Recipe"
            .sheet(item: $recipeToLog) { recipe in
                RadialHalfSheetSelector(
                    title: "How much \(recipe.name)?",
                    subtitle: "Input your served portion",
                    unit: recipe.measurementType == .fraction ? "Serving" : "g",
                    value: $adjustedAmount,
                    baseValue: recipe.measurementType == .fraction ? 1.0 : (recipe.servingSize ?? recipe.customBatchWeight ?? customizedIngredients.reduce(0) { $0 + $1.recipeWeight }),
                    onDismiss: { recipeToLog = nil },
                    onSave: {
                        if !recipe.additives.isEmpty {
                            recipeBeingLogged = recipe
                            additivesToConfirm = recipe.additives
                            confirmedAdditives = []
                            additiveConfirmationIndex = 0
                            recipeToLog = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                currentAdditiveToConfirm = additivesToConfirm[0]
                                adjustedAdditiveAmount = currentAdditiveToConfirm?.recipeWeight ?? 0
                            }
                        } else {
                            logRecipe(recipe, customIngredients: customizedIngredients, amount: adjustedAmount)
                            recipeToLog = nil
                        }
                    },
                    onAddExtras: {
                        // Compute portion-scaled base macros for display in the extras sheet
                        computePortionBaseMacros(customIngredients: customizedIngredients, amount: adjustedAmount, recipe: recipe)
                        recipeToLog = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            recipeToAddExtras = recipe
                        }
                    },
                    baseCalories: servingBaseCalories,
                    baseFat: servingBaseFat,
                    baseCarb: servingBaseCarb,
                    baseProtein: servingBaseProtein
                )
            }
            // Extras sheet — optional step after portion selection
            .sheet(item: $recipeToAddExtras) { recipe in
                AddExtrasHalfSheetSelector(
                    recipeName: recipe.name,
                    baseCalories: portionBaseCalories,
                    baseFat: portionBaseFat,
                    baseSaturatedFat: portionBaseSaturatedFat,
                    baseTransFat: portionBaseTransFat,
                    baseProtein: portionBaseProtein,
                    baseCarb: portionBaseCarb,
                    baseDietaryFiber: portionBaseDietaryFiber,
                    baseAddedSugar: portionBaseAddedSugar,
                    onSave: { extras in
                        logRecipe(recipe, customIngredients: customizedIngredients, amount: adjustedAmount, additives: extras)
                        recipeToAddExtras = nil
                    }
                )
            }
            .sheet(item: $currentAdditiveToConfirm) { additive in
                RadialHalfSheetSelector(
                    title: "How much \(additive.name)?",
                    subtitle: "Confirm extra for your recipe",
                    unit: additive.servingUnit,
                    value: $adjustedAdditiveAmount,
                    baseValue: additive.recipeWeight,
                    onDismiss: { currentAdditiveToConfirm = nil },
                    onSave: {
                        var confirmedAdditive = additive
                        confirmedAdditive.recipeWeight = adjustedAdditiveAmount
                        confirmedAdditives.append(confirmedAdditive)
                        
                        currentAdditiveToConfirm = nil
                        additiveConfirmationIndex += 1
                        
                        if additiveConfirmationIndex < additivesToConfirm.count {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                currentAdditiveToConfirm = additivesToConfirm[additiveConfirmationIndex]
                                adjustedAdditiveAmount = currentAdditiveToConfirm?.recipeWeight ?? 0
                            }
                        } else {
                            if let recipe = recipeBeingLogged {
                                logRecipe(recipe, customIngredients: customizedIngredients, amount: adjustedAmount, additives: confirmedAdditives)
                            }
                            recipeBeingLogged = nil
                        }
                    }
                )
            }
            .confirmationDialog("Final weight not yet entered", isPresented: $showingWeightAlert, titleVisibility: .visible) {
                Button("Enter final weight now") {
                    if let r = recipeNeedingWeight {
                        r.measurementType = .weight
                        r.finalWeightPostponed = false
                        recipeToFullEdit = r
                    }
                }
                Button("Switch to Fractional Recipe") {
                    if let r = recipeNeedingWeight {
                        r.measurementType = .fraction
                        r.finalWeightPostponed = false
                        recipeToFullEdit = r
                    }
                }
                Button("Cancel", role: .cancel) {
                    recipeNeedingWeight = nil
                }
            }
            .sheet(item: $recipeToFullEdit) { r in
                AddRecipieView(isDirty: .constant(false), existingRecipe: r)
            }
            .sheet(item: $recipeToCreateVariation) { r in
                AddRecipieView(isDirty: .constant(false), variationSource: r)
            }
        }
    }
    
    private func logRecipe(_ recipe: RecipeItem, customIngredients: [RecipeIngredient], amount: Double, additives: [RecipeIngredient] = []) {
        let servingUnit: String
        let ratio: Double
        
        if recipe.measurementType == .fraction {
            servingUnit = "Serving"
            let baseRatio: Double
            if let serving = recipe.servingSize, serving > 0 {
                baseRatio = serving < 1.0 ? serving : (1.0 / serving)
            } else {
                baseRatio = 1.0
            }
            ratio = amount * baseRatio
        } else {
            servingUnit = "g"
            let customTBW = recipe.customBatchWeight ?? customIngredients.reduce(0) { $0 + $1.recipeWeight }
            ratio = customTBW > 0 ? (amount / customTBW) : 1.0
        }
        let now = Date()
        
        // Batch ingredients — scaled by portion ratio
        var totalCalories: Double = 0
        var totalFat: Double = 0
        var totalSaturatedFat: Double = 0
        var totalTransFat: Double = 0
        var totalProtein: Double = 0
        var totalCarb: Double = 0
        var totalDietaryFiber: Double = 0
        var totalAddedSugar: Double = 0
        
        for ingredient in customIngredients {
            let ingredientRatio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            totalCalories += Double(ingredient.calories) * ingredientRatio
            totalFat += ingredient.fat * ingredientRatio
            totalSaturatedFat += ingredient.saturatedFat * ingredientRatio
            totalTransFat += ingredient.transFat * ingredientRatio
            totalProtein += ingredient.protein * ingredientRatio
            totalCarb += ingredient.carb * ingredientRatio
            totalDietaryFiber += ingredient.dietaryFiber * ingredientRatio
            totalAddedSugar += ingredient.addedSugar * ingredientRatio
        }
        
        // Additives — already plate-sized, no batch scaling applied
        var additivesCalories: Double = 0
        var additivesFat: Double = 0
        var additivesSaturatedFat: Double = 0
        var additivesTransFat: Double = 0
        var additivesProtein: Double = 0
        var additivesCarb: Double = 0
        var additivesDietaryFiber: Double = 0
        var additivesAddedSugar: Double = 0
        
        for additive in additives {
            let additiveRatio = additive.servingSize > 0 ? (additive.recipeWeight / additive.servingSize) : 1.0
            additivesCalories += Double(additive.calories) * additiveRatio
            additivesFat += additive.fat * additiveRatio
            additivesSaturatedFat += additive.saturatedFat * additiveRatio
            additivesTransFat += additive.transFat * additiveRatio
            additivesProtein += additive.protein * additiveRatio
            additivesCarb += additive.carb * additiveRatio
            additivesDietaryFiber += additive.dietaryFiber * additiveRatio
            additivesAddedSugar += additive.addedSugar * additiveRatio
        }
        
        let loggedItem = ConsumedItem(
            timestamp: now,
            logicalDate: now.logicalDay(startHour: dayStartHour),
            name: recipe.name,
            servingSize: amount,
            servingUnit: servingUnit,
            calories: Int(round(totalCalories * ratio + additivesCalories)),
            fat: totalFat * ratio + additivesFat,
            saturatedFat: totalSaturatedFat * ratio + additivesSaturatedFat,
            transFat: totalTransFat * ratio + additivesTransFat,
            protein: totalProtein * ratio + additivesProtein,
            carb: totalCarb * ratio + additivesCarb,
            dietaryFiber: totalDietaryFiber * ratio + additivesDietaryFiber,
            addedSugar: totalAddedSugar * ratio + additivesAddedSugar,
            category: "Prepared Foods",
            isRecipe: true,
            recipeCategory: recipe.category,
            recipeIngredients: customIngredients,
            recipeAdditives: additives.isEmpty ? nil : additives,
            recipeCustomBatchWeight: recipe.customBatchWeight,
            recipeRatio: ratio
        )
        
        modelContext.insert(loggedItem)
    }
    
    private func computePortionBaseMacros(customIngredients: [RecipeIngredient], amount: Double, recipe: RecipeItem) {
        let ratio: Double
        if recipe.measurementType == .fraction {
            let baseRatio: Double
            if let serving = recipe.servingSize, serving > 0 {
                baseRatio = serving < 1.0 ? serving : (1.0 / serving)
            } else {
                baseRatio = 1.0
            }
            ratio = amount * baseRatio
        } else {
            let customTBW = recipe.customBatchWeight ?? customIngredients.reduce(0) { $0 + $1.recipeWeight }
            ratio = customTBW > 0 ? (amount / customTBW) : 1.0
        }
        
        var cal: Double = 0, fat: Double = 0, satFat: Double = 0, transFat: Double = 0
        var protein: Double = 0, carb: Double = 0, fiber: Double = 0, sugar: Double = 0
        
        for ingredient in customIngredients {
            let ir = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            cal += Double(ingredient.calories) * ir
            fat += ingredient.fat * ir
            satFat += ingredient.saturatedFat * ir
            transFat += ingredient.transFat * ir
            protein += ingredient.protein * ir
            carb += ingredient.carb * ir
            fiber += ingredient.dietaryFiber * ir
            sugar += ingredient.addedSugar * ir
        }
        
        portionBaseCalories = Int(round(cal * ratio))
        portionBaseFat = fat * ratio
        portionBaseSaturatedFat = satFat * ratio
        portionBaseTransFat = transFat * ratio
        portionBaseProtein = protein * ratio
        portionBaseCarb = carb * ratio
        portionBaseDietaryFiber = fiber * ratio
        portionBaseAddedSugar = sugar * ratio
    }
    
    @ViewBuilder
    private func recipeRow(_ recipe: RecipeItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recipe.name)
                    .font(.headline)
                Spacer()
                if recipe.finalWeightPostponed {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            recipeNeedingWeight = recipe
                            showingWeightAlert = true
                        }
                }
            }
            
            if expandedItemIDs.contains(recipe.id.uuidString) {
                HStack {
                    Text("\(recipe.ingredients.count) ingredients")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if recipe.measurementType == .fraction {
                        let serving = recipe.servingSize ?? 1.0
                        let baseRatio = (serving > 0 && serving < 1.0) ? serving : (serving > 0 ? (1.0 / serving) : 1.0)
                        let totalServings = Int(round(1.0 / baseRatio))
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Recipe makes \(totalServings) servings")
                            Text("Serving Size: \(totalServings == 1 ? "1" : "1/\(totalServings)")")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        let batch = recipe.customBatchWeight ?? recipe.totalBatchWeight
                        let serving = recipe.servingSize ?? batch
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Recipe: makes \(String(format: "%.1f", batch))g")
                            Text("Serving Size: \(String(format: "%.1f", serving))g")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Text("\(recipe.servingCalories) kcal | F: \(recipe.servingFat.formatted(.number.precision(.fractionLength(0))))g | C: \(recipe.servingCarb.formatted(.number.precision(.fractionLength(0))))g | P: \(recipe.servingProtein.formatted(.number.precision(.fractionLength(0))))g")
                    .font(.caption).italic()
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if expandedItemIDs.contains(recipe.id.uuidString) {
                expandedItemIDs.remove(recipe.id.uuidString)
            } else {
                expandedItemIDs.insert(recipe.id.uuidString)
            }
        }
        .contextMenu {
            Button {
                customizedIngredients = recipe.ingredients
                adjustedAmount = recipe.measurementType == .fraction ? 1.0 : (recipe.servingSize ?? recipe.totalBatchWeight)
                recipeToLog = recipe
            } label: {
                Label("Log Recipe", systemImage: "fork.knife")
            }
            
            if recipe.customBatchWeight == nil {
                Button {
                    recipeToEdit = recipe
                } label: {
                    Label("Log Edited Recipe", systemImage: "pencil")
                }
            }
            
            Divider()
            
            Button {
                recipeToCreateVariation = recipe
            } label: {
                Label("Add New Recipe Variation", systemImage: "plus.rectangle.on.rectangle")
            }
            
            Divider()
            
            Button {
                recipeToFullEdit = recipe
            } label: {
                Label("Edit This Recipe", systemImage: "square.and.pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                delete(recipe)
            } label: {
                Label("Delete Recipe", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                delete(recipe)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func groupRow(groupName: String, items: [RecipeItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "square.stack.3d.down.right.fill")
                    .foregroundColor(.accentColor)
                Text(groupName)
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                if expandedItemIDs.contains(groupName) {
                    expandedItemIDs.remove(groupName)
                } else {
                    expandedItemIDs.insert(groupName)
                }
            }
            
            if expandedItemIDs.contains(groupName) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { recipe in
                        Divider()
                            .padding(.vertical, 8)
                        recipeRow(recipe)
                    }
                }
                .padding(.leading, 16)
                .padding(.top, 4)
            }
        }
    }
    
    private func delete(_ recipe: RecipeItem) {
        withAnimation {
            modelContext.delete(recipe)
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RecipeItem.self, configurations: config)
        
        let jsonString = """
        {
          "recipes": [
            {
              "type": "Recipe",
              "ingredients": [
                {
                  "dietaryFiber": 3,
                  "id": "C2201691-C968-4188-B46C-99EA86200D50",
                  "addedSugar": 0,
                  "protein": 1,
                  "fat": 0.5,
                  "saturatedFat": 0,
                  "brandName": "Unbranded",
                  "servingSize": 152,
                  "calories": 50,
                  "category": "Fruits",
                  "recipeWeight": 152,
                  "foodItemID": "F1EEA8E1-CF33-4681-B399-E5E1B7028862",
                  "servingUnit": "g",
                  "carb": 12,
                  "name": "Strawberries",
                  "transFat": 0
                },
                {
                  "dietaryFiber": 1,
                  "id": "BE64A9ED-CBBD-407F-A281-F45D464FB02D",
                  "addedSugar": 21,
                  "protein": 2,
                  "fat": 11,
                  "saturatedFat": 4,
                  "brandName": "Unbranded",
                  "servingSize": 37,
                  "calories": 200,
                  "category": "Sugars",
                  "recipeWeight": 37,
                  "foodItemID": "8796EB62-4861-40EC-B707-A249737A4E62",
                  "servingUnit": "g",
                  "carb": 22,
                  "name": "Nutella",
                  "transFat": 0
                },
                {
                  "dietaryFiber": 3.1,
                  "id": "BD11FCBC-AFE1-4034-9978-129E33315E21",
                  "addedSugar": 0,
                  "protein": 1.5,
                  "fat": 0.5,
                  "saturatedFat": 0,
                  "brandName": "Unbranded",
                  "servingSize": 118,
                  "calories": 105,
                  "category": "Fruits",
                  "recipeWeight": 118,
                  "foodItemID": "84DBDABB-DD2A-44E9-B50F-0251D67322BE",
                  "servingUnit": "g",
                  "carb": 27,
                  "name": "Banana",
                  "transFat": 0
                },
                {
                  "dietaryFiber": 4,
                  "id": "360040F9-98A0-4991-8FDF-07E0D51EADAF",
                  "addedSugar": 1,
                  "protein": 6,
                  "fat": 15,
                  "saturatedFat": 1,
                  "brandName": "Unbranded",
                  "servingSize": 30,
                  "calories": 170,
                  "category": "Nuts & Seeds",
                  "recipeWeight": 30,
                  "foodItemID": "E5CA73BF-7469-44B6-BDB7-04D249E2A66F",
                  "servingUnit": "g",
                  "carb": 6,
                  "name": "Almonds",
                  "transFat": 0
                },
                {
                  "dietaryFiber": 0,
                  "id": "C7F8AB74-5D50-4B9B-AEB4-B2054399382C",
                  "addedSugar": 0,
                  "protein": 9,
                  "fat": 5,
                  "saturatedFat": 3,
                  "brandName": "Lucern",
                  "servingSize": 240,
                  "calories": 130,
                  "category": "Dairy",
                  "recipeWeight": 240,
                  "foodItemID": "DBDD84D4-35EC-4064-85CA-CD8513270207",
                  "servingUnit": "g",
                  "carb": 13,
                  "name": "Milk",
                  "transFat": 0
                },
                {
                  "calories": 80,
                  "servingUnit": "g",
                  "transFat": 0,
                  "fat": 0,
                  "carb": 0,
                  "foodItemID": "3A78B444-55F9-40D8-AD72-68BD63EC65EA",
                  "addedSugar": 0,
                  "recipeWeight": 20,
                  "id": "7FC795C0-3F4C-4E7C-8C41-691E8A34829F",
                  "servingSize": 20,
                  "brandName": "Unbranded",
                  "name": "Collagen",
                  "category": "Supplements",
                  "saturatedFat": 0,
                  "protein": 20,
                  "dietaryFiber": 0
                }
              ],
              "measurementType": "Fraction",
              "category": "Entrees",
              "id": "8B07A28E-5D63-4B67-9256-051E46D3F0FF",
              "name": "Protein shake"
            },
            {
              "type": "Recipe",
              "ingredients": [
                {
                  "calories": 100,
                  "servingUnit": "g",
                  "transFat": 0,
                  "fat": 0,
                  "carb": 7,
                  "foodItemID": "98ED235A-C254-41D1-A798-4CB074CD8D6A",
                  "addedSugar": 0,
                  "recipeWeight": 170,
                  "id": "D8DC4080-7343-4D85-9118-843448D737C0",
                  "servingSize": 170,
                  "brandName": "Kirkland",
                  "name": "Greek Yogurt 0%",
                  "category": "Dairy",
                  "saturatedFat": 0,
                  "protein": 18,
                  "dietaryFiber": 0
                },
                {
                  "calories": 4,
                  "servingUnit": "g",
                  "transFat": 0,
                  "fat": 0,
                  "carb": 1,
                  "foodItemID": "683E5496-7115-4780-9527-3A89B70AA6E8",
                  "addedSugar": 0,
                  "recipeWeight": 1,
                  "id": "E0681A18-1CB0-4F3F-BA90-D6B510DB0A8F",
                  "servingSize": 1,
                  "brandName": "Unbranded",
                  "name": "Brown Sugar",
                  "category": "Sugars",
                  "saturatedFat": 0,
                  "protein": 0,
                  "dietaryFiber": 0
                },
                {
                  "calories": 85,
                  "servingUnit": "g",
                  "transFat": 0,
                  "fat": 0.5,
                  "carb": 21,
                  "foodItemID": "DE5247D3-D32B-40AC-8099-1C8657A0919F",
                  "addedSugar": 0,
                  "recipeWeight": 148,
                  "id": "D52DE1FD-705B-4B8F-92C1-5FD63F729C05",
                  "servingSize": 148,
                  "brandName": "Unbranded",
                  "name": "Blueberries",
                  "category": "Fruits",
                  "saturatedFat": 0,
                  "protein": 1,
                  "dietaryFiber": 3.5
                },
                {
                  "calories": 170,
                  "servingUnit": "g",
                  "transFat": 0,
                  "fat": 15,
                  "carb": 6,
                  "foodItemID": "E5CA73BF-7469-44B6-BDB7-04D249E2A66F",
                  "addedSugar": 1,
                  "recipeWeight": 30,
                  "id": "2DA00B35-F36A-4490-B64C-660E261F912C",
                  "servingSize": 30,
                  "brandName": "Unbranded",
                  "name": "Almonds",
                  "category": "Nuts & Seeds",
                  "saturatedFat": 1,
                  "protein": 6,
                  "dietaryFiber": 4
                }
              ],
              "measurementType": "Fraction",
              "category": "Entrees",
              "id": "0C75BF1E-B4DE-43E9-8636-7C8168D7DA03",
              "name": "Yogurt Bowl"
            }
          ]
        }
        """
        
        struct PreviewData: Decodable {
            let recipes: [RecipeItemDTO]
        }
        
        if let data = jsonString.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(PreviewData.self, from: data) {
                for dto in decoded.recipes {
                    let recipe = RecipeItem(from: dto)
                    container.mainContext.insert(recipe)
                }
            }
        }
        
        return RecipeBankView()
            .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container")
    }
}
