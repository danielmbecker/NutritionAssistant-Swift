import SwiftUI
import SwiftData

struct AddRecipieView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isDirty: Bool
    @State private var recipe = RecipeItem(name: "", type: "Recipe")
    @State private var showingAddFoodSheet = false
    @State private var displayServingAsFraction = false
    @State private var hasSelectedMeasurement = false
    @State private var userEnteredServing: Double? = nil
    @State private var recipeWeightStatic = true
    
    var existingRecipe: RecipeItem?
    
    @Query private var customCategories: [UserRecipeCategory]
    @State private var showingAddCategoryAlert = false
    @State private var newCategoryName = ""
    
    init(isDirty: Binding<Bool>, existingRecipe: RecipeItem? = nil) {
        self._isDirty = isDirty
        self.existingRecipe = existingRecipe
        if let existing = existingRecipe {
            self._recipe = State(initialValue: existing)
            self._hasSelectedMeasurement = State(initialValue: true)
            self._recipeWeightStatic = State(initialValue: existing.customBatchWeight == nil)
        }
    }
    
    private func checkDirty() {
        isDirty = !recipe.name.isEmpty || 
                  !recipe.ingredients.isEmpty || 
                  recipe.measurementType != .weight
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section() {
                    
                    // 4. Recipe Name
                    VStack(alignment: .leading, spacing: 8) {
                       
                            
                        
                        HStack {
                            Text("Recipe Name")
                            TextField("Enter recipe name...", text: $recipe.name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // 4.5. Recipe Category
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let allCategories = RecipeCategory.defaultCategories + customCategories.map { $0.name }
                                
                                ForEach(allCategories, id: \.self) { cat in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            recipe.category = cat
                                        }
                                    }) {
                                        Text(cat)
                                            .font(.subheadline)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(recipe.category == cat ? Color.accentColor : Color.gray.opacity(0.15))
                                            .foregroundColor(recipe.category == cat ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Button(action: {
                                    showingAddCategoryAlert = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.15))
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                     
                    HStack {
                        HStack(spacing: 4) {
                            if !hasSelectedMeasurement {
                                Text("How is this recipe measured?")
                                    .contentTransition(.interpolate)
                            } else {
                                Text("How Many")
                                Text(recipe.measurementType == .weight ? "grams per Serving" : "Servings per Recipe")
                                    .contentTransition(.interpolate)
                                    .animation(.spring(duration: 2.0, bounce: 0.3), value: recipe.measurementType)
                            }
                        }
                        .font(.subheadline)
                        
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    hasSelectedMeasurement = true
                                    recipe.measurementType = .weight
                                }
                            }) {
                                Image(systemName: "scalemass")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(hasSelectedMeasurement && recipe.measurementType == .weight ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(hasSelectedMeasurement && recipe.measurementType == .weight ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    hasSelectedMeasurement = true
                                    recipe.measurementType = .fraction
                                }
                            }) {
                                Image(systemName: "chart.pie")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(hasSelectedMeasurement && recipe.measurementType == .fraction ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(hasSelectedMeasurement && recipe.measurementType == .fraction ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                        .cornerRadius(6)
                    }
                    if hasSelectedMeasurement {
                        if recipe.measurementType == .fraction {
                            FractionSelectionView()
                                .padding(.top, 4)
                        }
                        
                        if recipe.measurementType == .weight {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Total Weight")
                                Spacer()
                                HStack(spacing: 0) {
                                    Button(action: { withAnimation { recipeWeightStatic = false } }) {
                                        Text("Changes")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(!recipeWeightStatic ? Color.accentColor : Color.gray.opacity(0.2))
                                            .foregroundColor(!recipeWeightStatic ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: { 
                                        withAnimation { 
                                            recipeWeightStatic = true 
                                            recipe.customBatchWeight = nil
                                        } 
                                    }) {
                                        Text("Doesn't Change")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(recipeWeightStatic ? Color.accentColor : Color.gray.opacity(0.2))
                                            .foregroundColor(recipeWeightStatic ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .cornerRadius(6)
                            }
                            
                            HStack {
                                Text(recipeWeightStatic ? "Total Ingredients Weight" : "Custom Total Weight")
                                Spacer()
                                if recipeWeightStatic {
                                    Text("\(recipe.totalBatchWeight, specifier: "%.1f")g")
                                        .foregroundColor(.secondary)
                                } else {
                                    HStack(spacing: 4) {
                                        TextField("0", value: $recipe.customBatchWeight, format: .number)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 80)
                                            .padding(4)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(6)
                                        Text("g")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            if !recipeWeightStatic {
                                Toggle(isOn: $recipe.finalWeightPostponed) {
                                    Text("Set final weight later")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text("Serving Size")
                                Spacer()
                                TextField("0", value: $userEnteredServing, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
             
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
            .navigationTitle(existingRecipe == nil ? "Add Recipe" : "Edit Recipe")
            .onChange(of: recipe.name) { checkDirty() }
            .onChange(of: recipe.measurementType) { checkDirty() }
            .onChange(of: recipe.ingredients.count) { checkDirty() }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if existingRecipe != nil {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(recipe.name.isEmpty || recipe.ingredients.isEmpty)
                }
            }
            .alert("New Category", isPresented: $showingAddCategoryAlert) {
                TextField("Category Name", text: $newCategoryName)
                Button("Cancel", role: .cancel) { newCategoryName = "" }
                Button("Save") {
                    let newCat = UserRecipeCategory(name: newCategoryName)
                    modelContext.insert(newCat)
                    recipe.category = newCategoryName
                    newCategoryName = ""
                }
                .disabled(newCategoryName.isEmpty)
            } message: {
                Text("Enter a name for the new custom category.")
            }
        }
    }
    
    private func saveRecipe() {
        if existingRecipe == nil {
            modelContext.insert(recipe)
        }
        
        if existingRecipe != nil {
            dismiss()
        } else {
            // Reset form for next recipe
            recipe = RecipeItem(name: "", type: "Recipe")
            isDirty = false
            hasSelectedMeasurement = false
        }
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
