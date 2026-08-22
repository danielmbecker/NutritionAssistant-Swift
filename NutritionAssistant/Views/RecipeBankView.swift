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
                            Text(recipe.name)
                                .font(.headline)
                            
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
                            
                            Text("\(recipe.totalCalories) kcal | F: \(String(format: "%g", recipe.totalFat))g | C: \(String(format: "%g", recipe.totalCarb))g | P: \(String(format: "%g", recipe.totalProtein))g")
                                .font(.caption).italic()
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            recipeToEdit = recipe
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
            .sheet(item: $recipeToEdit) { recipe in
                RecipeWeightsHalfSheetSelector(
                    initialIngredients: recipe.ingredients,
                    onNext: { customIngredients in
                        customizedIngredients = customIngredients
                        adjustedAmount = recipe.measurementType == .fraction ? 1.0 : customIngredients.reduce(0) { $0 + $1.recipeWeight }
                        // Small delay to allow the first sheet to dismiss smoothly before the next appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            recipeToLog = recipe
                        }
                    }
                )
            }
            .sheet(item: $recipeToLog) { recipe in
                RadialHalfSheetSelector(
                    title: "How much \(recipe.name)?",
                    subtitle: "Input your served portion",
                    unit: recipe.measurementType == .fraction ? "Serving" : "g",
                    value: $adjustedAmount,
                    baseValue: recipe.measurementType == .fraction ? 1.0 : customizedIngredients.reduce(0) { $0 + $1.recipeWeight },
                    onDismiss: { recipeToLog = nil },
                    onSave: {
                        logRecipe(recipe, customIngredients: customizedIngredients, amount: adjustedAmount)
                        recipeToLog = nil
                    }
                )
            }
        }
    }
    
    private func logRecipe(_ recipe: RecipeItem, customIngredients: [RecipeIngredient], amount: Double) {
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
        
        let loggedItem = ConsumedItem(
            timestamp: now,
            logicalDate: now.logicalDay(startHour: dayStartHour),
            name: recipe.name,
            servingSize: amount,
            servingUnit: servingUnit,
            calories: Int(round(totalCalories * ratio)),
            fat: totalFat * ratio,
            saturatedFat: totalSaturatedFat * ratio,
            transFat: totalTransFat * ratio,
            protein: totalProtein * ratio,
            carb: totalCarb * ratio,
            dietaryFiber: totalDietaryFiber * ratio,
            addedSugar: totalAddedSugar * ratio,
            category: .preparedFoods,
            isRecipe: true,
            recipeCategory: recipe.category,
            recipeIngredients: customIngredients
        )
        
        modelContext.insert(loggedItem)
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
