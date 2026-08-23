import SwiftUI

struct RecipeWeightsHalfSheetSelector: View {
    @Environment(\.dismiss) private var dismiss
    
    let initialIngredients: [RecipeIngredient]
    let onNext: ([RecipeIngredient]) -> Void
    
    @State private var editableIngredients: [RecipeIngredient] = []
    @FocusState private var focusedField: UUID?
    @State private var showingAddFoodSheet = false
    
    private var totalCalories: Int {
        let total = editableIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (Double(ingredient.calories) * ratio)
        }
        return Int(round(total))
    }
    
    private var totalFat: Double {
        editableIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.fat * ratio)
        }
    }
    
    private var totalCarb: Double {
        editableIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.carb * ratio)
        }
    }
    
    private var totalProtein: Double {
        editableIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.protein * ratio)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($editableIngredients) { $ingredient in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.name)
                                    .fontWeight(.semibold)
                                
                                // Computed macros for this specific ingredient's current weight
                                let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
                                let cal = Int(round(Double(ingredient.calories) * ratio))
                                let f = ingredient.fat * ratio
                                let c = ingredient.carb * ratio
                                let p = ingredient.protein * ratio
                                
                                Text("\(cal) kcal | F: \(String(format: "%g", f))g | C: \(String(format: "%g", c))g | P: \(String(format: "%g", p))g")
                                    .font(.caption).italic()
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Editable weight field
                            HStack(spacing: 4) {
                                TextField("Weight", value: $ingredient.recipeWeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: ingredient.id)
                                    .frame(width: 60)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                
                                Text(ingredient.servingUnit)
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = ingredient.id
                        }
                    }
                    .onDelete { offsets in
                        editableIngredients.remove(atOffsets: offsets)
                    }
                    Button(action: { showingAddFoodSheet = true }) {
                        Label("Add Ingredient", systemImage: "plus")
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 4)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Customize Batch Ingredients")
                            .font(.subheadline)
                        Text("\(totalCalories) kcal | F: \(String(format: "%g", totalFat))g | C: \(String(format: "%g", totalCarb))g | P: \(String(format: "%g", totalProtein))g")
                            .font(.caption).italic()
                            .textCase(.none)
                    }
                }
            }
            .sheet(isPresented: $showingAddFoodSheet) {
                AddFoodToRecipeSheet(ingredients: $editableIngredients)
            }
            .navigationTitle("Adjust Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Spacer()
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            
            // Next Button at bottom
            VStack {
                Button(action: {
                    dismiss()
                    onNext(editableIngredients)
                }) {
                    Text("Next: Select Portion")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground).shadow(radius: 2))
        }
        .onAppear {
            // Create mutable copies of the ingredients
            editableIngredients = initialIngredients
        }
        .presentationDetents([.medium, .large])
    }
}
