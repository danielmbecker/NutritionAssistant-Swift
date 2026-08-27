import SwiftUI
import SwiftData

struct AddRecipieView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isDirty: Bool
    @State private var recipe = RecipeItem(name: "", type: "Recipe")
    @State private var showingAddFoodSheet = false
    @State private var showingAddExtraSheet = false
    @State private var displayServingAsFraction = false
    @State private var hasSelectedMeasurement = false
    @State private var fractionSections: Int = -4
    @State private var recipeWeightStatic = true
    @State private var ingredientToEdit: RecipeIngredient?
    @State private var additiveToEdit: RecipeIngredient?
    @State private var editedWeight: Double = 0.0
    
    var existingRecipe: RecipeItem?
    var isVariation: Bool = false
    
    @Query private var customCategories: [UserRecipeCategory]
    @State private var showingAddCategoryAlert = false
    @State private var newCategoryName = ""
    
    enum Field: Hashable {
        case variationGroup
    }
    @FocusState private var focusedField: Field?
    
    init(isDirty: Binding<Bool>, existingRecipe: RecipeItem? = nil, variationSource: RecipeItem? = nil) {
        self._isDirty = isDirty
        self.existingRecipe = existingRecipe
        if let existing = existingRecipe {
            self._recipe = State(initialValue: existing)
            self._hasSelectedMeasurement = State(initialValue: true)
            self._recipeWeightStatic = State(initialValue: existing.customBatchWeight == nil)
            if let serving = existing.servingSize {
                if serving > 0 && serving < 1.0 {
                    self._fractionSections = State(initialValue: -Int(round(1.0 / serving)))
                } else if serving == 1.0 {
                    self._fractionSections = State(initialValue: -1)
                } else if serving > 1.0 {
                    self._fractionSections = State(initialValue: Int(round(serving)))
                }
            }
        } else if let source = variationSource {
            self.isVariation = true
            // Create a new recipe object with the same values
            let newRecipe = RecipeItem(
                name: source.name,
                type: source.type,
                measurementType: source.measurementType,
                ingredients: source.ingredients.map { var copy = $0; copy.id = UUID(); return copy },
                additives: source.additives.map { var copy = $0; copy.id = UUID(); return copy },
                category: source.category,
                customBatchWeight: source.customBatchWeight,
                finalWeightPostponed: source.finalWeightPostponed,
                servingSize: source.servingSize,
                recipeVariationGroup: source.recipeVariationGroup ?? source.name
            )
            self._recipe = State(initialValue: newRecipe)
            self._hasSelectedMeasurement = State(initialValue: true)
            self._recipeWeightStatic = State(initialValue: source.customBatchWeight == nil)
            if let serving = source.servingSize {
                if serving > 0 && serving < 1.0 {
                    self._fractionSections = State(initialValue: -Int(round(1.0 / serving)))
                } else if serving == 1.0 {
                    self._fractionSections = State(initialValue: -1)
                } else if serving > 1.0 {
                    self._fractionSections = State(initialValue: Int(round(serving)))
                }
            }
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
                            Text("Recipe Name").padding(5)
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
                        Text("Add as Variation")
                        TextField("Variation Group Name", text: Binding(
                            get: { recipe.recipeVariationGroup ?? "" },
                            set: { recipe.recipeVariationGroup = $0.isEmpty ? nil : $0 }
                        ))
                        .focused($focusedField, equals: .variationGroup)
                        .textFieldStyle(.roundedBorder)
                        
                        Button(action: {
                            // No action for now
                        }) {
                            Image(systemName: "magnifyingglass")
                        }
                        .buttonStyle(.plain)
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
                            FractionSelectionView(sections: $fractionSections)
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
                                TextField("0", value: $recipe.servingSize, format: .number)
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
                
             
                Section(header: HStack {
                    Text("Ingredients")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                    
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
                }) {
                    ForEach(recipe.ingredients) { item in
                        let ratio = item.servingSize > 0 ? (item.recipeWeight / item.servingSize) : 1.0
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.name)
                                        .fontWeight(.semibold)
                                    Text("\(Int(round(Double(item.calories) * ratio))) kcal")
                                        .foregroundColor(.secondary)
                                }
                                  
                                Text("F: \(item.fat * ratio, specifier: "%.0f")g | P: \(item.protein * ratio, specifier: "%.0f")g | C: \(item.carb * ratio, specifier: "%.0f")g")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                editedWeight = item.recipeWeight
                                ingredientToEdit = item
                            }) {
                                Label("\(item.recipeWeight, specifier: "%.1f") \(item.servingUnit)", systemImage: "pencil")
                                    .font(.caption)
                                    .frame(width: 80, alignment: .trailing)
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
                    .onDelete { indices in
                        recipe.ingredients.remove(atOffsets: indices)
                    }
                    
                    if recipe.ingredients.isEmpty {
                        Text("No ingredients added yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                    
                Section(header: HStack {
                    Text("Toppings, Sauces, and Extras")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddExtraSheet = true
                    }) {
                        Text("Add Extra")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingAddExtraSheet) {
                        AddFoodToRecipeSheet(ingredients: $recipe.additives)
                    }
                }) {
                    ForEach(recipe.additives) { item in
                        let ratio = item.servingSize > 0 ? (item.recipeWeight / item.servingSize) : 1.0
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.name)
                                        .fontWeight(.semibold)
                                    Text("\(Int(round(Double(item.calories) * ratio))) kcal")
                                        .foregroundColor(.secondary)
                                }
                                  
                                Text("F: \(item.fat * ratio, specifier: "%.0f")g | P: \(item.protein * ratio, specifier: "%.0f")g | C: \(item.carb * ratio, specifier: "%.0f")g")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                editedWeight = item.recipeWeight
                                additiveToEdit = item
                            }) {
                                Label("\(item.recipeWeight, specifier: "%.1f") \(item.servingUnit)", systemImage: "pencil")
                                    .font(.caption)
                                    .frame(width: 80, alignment: .trailing)
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
                    .onDelete { indices in
                        recipe.additives.remove(atOffsets: indices)
                    }
                    
                    if recipe.additives.isEmpty {
                        Text("No extras added yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle(isVariation ? "Create Recipe Variation" : (existingRecipe == nil ? "Add Recipe" : "Edit Recipe"))
            .onChange(of: recipe.name) { checkDirty() }
            .onChange(of: recipe.measurementType) { checkDirty() }
            .onChange(of: recipe.ingredients.count) { checkDirty() }
            .onChange(of: recipe.additives.count) { checkDirty() }
            .onAppear {
                if isVariation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        focusedField = .variationGroup
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if existingRecipe != nil || isVariation {
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
            .sheet(item: $ingredientToEdit) { ingredient in
                RadialHalfSheetSelector(
                    title: "How Much?",
                    subtitle: "Adjust amount for \(ingredient.name)",
                    unit: ingredient.servingUnit,
                    value: $editedWeight,
                    baseValue: ingredient.servingSize,
                    onDismiss: { ingredientToEdit = nil },
                    onSave: {
                        if let index = recipe.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                            recipe.ingredients[index].recipeWeight = editedWeight
                        }
                        ingredientToEdit = nil
                    }
                )
            }
            .sheet(item: $additiveToEdit) { additive in
                RadialHalfSheetSelector(
                    title: "How Much?",
                    subtitle: "Adjust amount for \(additive.name)",
                    unit: additive.servingUnit,
                    value: $editedWeight,
                    baseValue: additive.servingSize,
                    onDismiss: { additiveToEdit = nil },
                    onSave: {
                        if let index = recipe.additives.firstIndex(where: { $0.id == additive.id }) {
                            recipe.additives[index].recipeWeight = editedWeight
                        }
                        additiveToEdit = nil
                    }
                )
            }
        }
    }
    
    private func saveRecipe() {
        if recipe.measurementType == .fraction {
            recipe.servingSize = fractionSections < 0 ? (1.0 / Double(abs(fractionSections))) : Double(fractionSections)
        }
        
        if existingRecipe == nil {
            modelContext.insert(recipe)
        }
        
        if existingRecipe != nil || isVariation {
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
    
    var groupedItems: [(category: String, items: [FoodItem])] {
        let grouped = Dictionary(grouping: items, by: { $0.category })
        return grouped.map { (category: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted {
                let order1 = FoodCategoryList.displayOrder(for: $0.category)
                let order2 = FoodCategoryList.displayOrder(for: $1.category)
                
                if order1 == 999 && order2 == 999 {
                    return $0.category < $1.category
                }
                return order1 < order2
            }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedItems, id: \.category) { group in
                        LazyVStack(alignment: .leading, spacing: 1) {
                            Text(FoodCategoryList.displayName(for: group.category))
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
