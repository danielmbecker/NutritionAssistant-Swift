//
//  AddIngredientsHalfSheetSelector.swift
//  NutritionAssistant
//

import SwiftUI
import SwiftData

struct AddIngredientsHalfSheetSelector: View {
    @Environment(\.dismiss) private var dismiss
    
    let recipeName: String
    let baseCalories: Int
    let baseFat: Double
    let baseSaturatedFat: Double
    let baseTransFat: Double
    let baseProtein: Double
    let baseCarb: Double
    let baseDietaryFiber: Double
    let baseAddedSugar: Double
    let onSave: ([RecipeIngredient]) -> Void
    
    @State private var extraIngredients: [RecipeIngredient] = []
    @FocusState private var focusedField: UUID?
    @State private var showingAddFoodSheet = false
    
    // MARK: - Computed Totals (Base + Extras)
    
    private var extrasCalories: Int {
        let total = extraIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (Double(ingredient.calories) * ratio)
        }
        return Int(round(total))
    }
    
    private var extrasFat: Double {
        extraIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.fat * ratio)
        }
    }
    
    private var extrasCarb: Double {
        extraIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.carb * ratio)
        }
    }
    
    private var extrasProtein: Double {
        extraIngredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.protein * ratio)
        }
    }
    
    private var totalCalories: Int { baseCalories + extrasCalories }
    private var totalFat: Double { baseFat + extrasFat }
    private var totalCarb: Double { baseCarb + extrasCarb }
    private var totalProtein: Double { baseProtein + extrasProtein }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Base Recipe Row (Read-Only)
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(recipeName)
                                    .fontWeight(.semibold)
                            }
                            
                            Text("\(baseCalories) kcal | F: \(String(format: "%g", baseFat))g | C: \(String(format: "%g", baseCarb))g | P: \(String(format: "%g", baseProtein))g")
                                .font(.caption).italic()
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                } header: {
                    Text("Base Portion")
                        .font(.subheadline)
                }
                
                // MARK: - Extras List (Editable)
                Section {
                    ForEach($extraIngredients) { $ingredient in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.name)
                                    .fontWeight(.semibold)
                                
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
                        extraIngredients.remove(atOffsets: offsets)
                    }
                    
                    Button(action: { showingAddFoodSheet = true }) {
                        Label("Add Ingredient", systemImage: "plus")
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 4)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Extras")
                            .font(.subheadline)
                        Text("\(totalCalories) kcal | F: \(String(format: "%g", totalFat))g | C: \(String(format: "%g", totalCarb))g | P: \(String(format: "%g", totalProtein))g")
                            .font(.caption).italic()
                            .textCase(.none)
                    }
                }
            }
            .sheet(isPresented: $showingAddFoodSheet) {
                AddFoodToRecipeSheet(ingredients: $extraIngredients)
            }
            .navigationTitle("Review & Add Extras")
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
            
            // Log Meal Button at bottom
            VStack {
                Button(action: {
                    dismiss()
                    onSave(extraIngredients)
                }) {
                    Text("Log Meal")
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
        .presentationDetents([.medium, .large])
    }
}
