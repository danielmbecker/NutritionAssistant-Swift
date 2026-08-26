import SwiftUI
import SwiftData

struct RecipeBankView: View {
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecipeItem.name) private var recipes: [RecipeItem]
    
    @State private var recipeToEdit: RecipeItem?
    @State private var recipeToLog: RecipeItem?
    @State private var customizedIngredients: [RecipeIngredient] = []
    @State private var adjustedAmount: Double = 0.0
    
    @State private var recipeToFullEdit: RecipeItem?
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
                    ForEach(recipes) { recipe in
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
                            
                            HStack {
                                Text("\(recipe.ingredients.count) ingredients")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if recipe.measurementType == .fraction {
                                    Text("Fractional (1 Serving)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Batch Weight: \(String(format: "%.1f", recipe.totalBatchWeight))g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("\(recipe.servingCalories) kcal | F: \(recipe.servingFat.formatted(.number.precision(.fractionLength(0))))g | C: \(recipe.servingCarb.formatted(.number.precision(.fractionLength(0))))g | P: \(recipe.servingProtein.formatted(.number.precision(.fractionLength(0))))g")
                                .font(.caption).italic()
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .contextMenu {
                            if recipe.measurementType == .fraction {
                                // --- Fraction recipe actions ---
                                Button {
                                    customizedIngredients = recipe.ingredients
                                    adjustedAmount = 1.0
                                    recipeToLog = recipe
                                } label: {
                                    Label("Log Recipe", systemImage: "fork.knife")
                                }
                                
                                Button {
                                    recipeToEdit = recipe
                                } label: {
                                    Label("Log Edited Recipe", systemImage: "pencil")
                                }
                                
                                Button {
                                    print("Add New Recipe Variation")
                                } label: {
                                    Label("Add New Recipe Variation", systemImage: "plus.rectangle.on.rectangle")
                                }
                            } else {
                                // --- Weight recipe actions ---
                                Button {
                                    customizedIngredients = recipe.ingredients
                                    adjustedAmount = recipe.servingSize ?? recipe.totalBatchWeight
                                    recipeToLog = recipe
                                } label: {
                                    Label("Log Recipe", systemImage: "fork.knife")
                                }
                                
                                Button {
                                    print("Add New Recipe Variation")
                                } label: {
                                    Label("Add New Recipe Variation", systemImage: "plus.rectangle.on.rectangle")
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                recipeToFullEdit = recipe
                            } label: {
                                Label("Edit This Recipe", systemImage: "square.and.pencil")
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
                        logRecipe(recipe, customIngredients: customizedIngredients, amount: adjustedAmount)
                        recipeToLog = nil
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
                AddIngredientsHalfSheetSelector(
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
        }
    }
    
    private func logRecipe(_ recipe: RecipeItem, customIngredients: [RecipeIngredient], amount: Double, additives: [RecipeIngredient] = []) {
        let baseTotalWeight: Double
        let servingUnit: String
        
        if recipe.measurementType == .fraction {
            baseTotalWeight = 1.0
            servingUnit = "Serving"
        } else {
            baseTotalWeight = customIngredients.reduce(0) { $0 + $1.recipeWeight }
            servingUnit = "g"
        }
        
        let ratio = baseTotalWeight > 0 ? (amount / baseTotalWeight) : 1.0
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
            category: .preparedFoods,
            isRecipe: true,
            recipeCategory: recipe.category,
            recipeIngredients: customIngredients,
            recipeAdditives: additives.isEmpty ? nil : additives
        )
        
        modelContext.insert(loggedItem)
    }
    
    private func computePortionBaseMacros(customIngredients: [RecipeIngredient], amount: Double, recipe: RecipeItem) {
        let baseTotalWeight: Double
        if recipe.measurementType == .fraction {
            baseTotalWeight = 1.0
        } else {
            baseTotalWeight = customIngredients.reduce(0) { $0 + $1.recipeWeight }
        }
        let ratio = baseTotalWeight > 0 ? (amount / baseTotalWeight) : 1.0
        
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
        return RecipeBankView()
            .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container")
    }
}
