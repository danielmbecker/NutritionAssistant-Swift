import SwiftUI
import SwiftData

struct AddRecipieView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isDirty: Bool
    @State private var recipe = RecipeItem(name: "", type: "Recipe")
    @State private var showingAddFoodSheet = false
    
    private func checkDirty() {
        isDirty = !recipe.name.isEmpty || 
                  !recipe.ingredients.isEmpty || 
                  recipe.measurementType != .weight
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Recipe Details")) {
                    
                    // 1. Measurement Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How do you want to measure servings of this recipe?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button(action: { recipe.measurementType = .fraction }) {
                                Text("Fractional (1 Whole, 1/2, 1/4, etc)")
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(recipe.measurementType == .fraction ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(recipe.measurementType == .fraction ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { recipe.measurementType = .weight }) {
                                Text("Weight (grams, ounces)")
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(recipe.measurementType == .weight ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(recipe.measurementType == .weight ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    

                    
                    // 4. Recipe Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipe Name")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter recipe name...", text: $recipe.name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // 4.5. Recipe Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        Picker("Select Category", selection: $recipe.category) {
                            ForEach(RecipeCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 4)
                }
                
                // 5. Ingredients Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ingredients")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddFoodSheet = true
                            }) {
                                Text("Add Food")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showingAddFoodSheet) {
                                AddFoodToRecipeSheet(ingredients: $recipe.ingredients)
                            }
                        }
                        
                        // Ingredient loop
                        ForEach(recipe.ingredients) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.name)
                                            .fontWeight(.semibold)
                                        Text("\(item.calories) kcal")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("F: \(item.fat, specifier: "%.0f")g | P: \(item.protein, specifier: "%.0f")g | C: \(item.carb, specifier: "%.0f")g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // Edit serving size logic
                                }) {
                                    Label("\(item.recipeWeight, specifier: "%.1f") \(item.servingUnit)", systemImage: "pencil")
                                        .font(.caption)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if recipe.ingredients.isEmpty {
                            Text("No ingredients added yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Recipe")
            .onChange(of: recipe.name) { checkDirty() }
            .onChange(of: recipe.measurementType) { checkDirty() }
            .onChange(of: recipe.ingredients.count) { checkDirty() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(recipe.name.isEmpty || recipe.ingredients.isEmpty)
                }
            }
        }
    }
    
    private func saveRecipe() {
        modelContext.insert(recipe)
        // Reset form for next recipe
        recipe = RecipeItem(name: "", type: "Recipe")
        isDirty = false
    }
}

struct AddFoodToRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var items: [FoodItem]
    
    @Binding var ingredients: [RecipeIngredient]
    
    @State private var itemToLog: FoodItem?
    @State private var adjustedServingSize: Double = 0.0
    
    var groupedItems: [(category: FoodCategory, items: [FoodItem])] {
        let grouped = Dictionary(grouping: items, by: { $0.category })
        return grouped.map { (category: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category.displayOrder < $1.category.displayOrder }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedItems, id: \.category) { group in
                        LazyVStack(alignment: .leading, spacing: 1) {
                            Text(group.category.displayName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(group.items) { item in
                                let isSelected = ingredients.contains { $0.foodItemID == item.id }
                                
                                HStack(spacing: 0) {
                                    Text(item.name)
                                        .font(.caption)
                                    Spacer()
                                    Text("\(item.calories) kcal | F: \(String(format: "%g", item.fat))g | C: \(String(format: "%g", item.carb))g | P: \(String(format: "%g", item.protein))g")
                                        .font(.caption).italic()
                                        .foregroundColor(isSelected ? .green : .secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.green.opacity(0.15) : Color.clear)
                                .cornerRadius(8)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let index = ingredients.firstIndex(where: { $0.foodItemID == item.id }) {
                                        // Deselect / Remove
                                        ingredients.remove(at: index)
                                    } else {
                                        // Select / Open radial sheet
                                        adjustedServingSize = item.servingSize
                                        itemToLog = item
                                    }
                                }
                                
                                Divider()
                                    .padding(.leading)
                            }
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(hex: "0f0f0f") : Color(hex: "FAFAFA"))
                        .cornerRadius(10)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Add to Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $itemToLog) { item in
                RadialHalfSheetSelector(
                    title: "How Much?",
                    subtitle: "Input amount for recipe",
                    unit: item.servingUnit,
                    value: $adjustedServingSize,
                    baseValue: item.servingSize,
                    onDismiss: { itemToLog = nil },
                    onSave: {
                        let newIngredient = RecipeIngredient(from: item, recipeWeight: adjustedServingSize)
                        ingredients.append(newIngredient)
                        itemToLog = nil
                        // Kept the main sheet open so users can select multiple ingredients!
                    }
                )
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AddRecipieView(isDirty: .constant(false))
}
