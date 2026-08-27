import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var userSettingsList: [UserSettings]
    
    private var dayStartHour: Int {
        userSettingsList.first?.dayStartHour ?? 0
    }
    
    private var todayLogical: Date {
        Date().logicalDay(startHour: dayStartHour)
    }
    
    var body: some View {
        TodayContentView(
            dayStartHour: dayStartHour,
            todayLogical: todayLogical
        )
    }
}

struct TodayContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    let dayStartHour: Int
    let todayLogical: Date
    
    @Query private var consumedItems: [ConsumedItem]
    
    @State private var itemToView: ConsumedItem?
    @State private var itemToEdit: ConsumedItem?
    @State private var itemToEditIngredients: ConsumedItem?
    @State private var customizedIngredients: [RecipeIngredient] = []
    @State private var adjustedServingSize: Double = 0.0
    /// Captures the serving size at the moment the edit sheet opens, before any mutation.
    @State private var editBaseServingSize: Double = 0.0
    @State private var showSettings = false
    @State private var showResetTime = false
    
    @State private var groupForAlert: [ConsumedItem]?
    @State private var groupToEditTime: [ConsumedItem]?
    @State private var showTimePickerSheet = false
    @State private var selectedGroupTime: Date = Date()
    
    init(dayStartHour: Int, todayLogical: Date) {
        self.dayStartHour = dayStartHour
        self.todayLogical = todayLogical
        
        let targetDate = todayLogical
        let predicate = #Predicate<ConsumedItem> { item in
            item.logicalDate == targetDate
        }
        
        _consumedItems = Query(filter: predicate, sort: \.timestamp, order: .reverse)
    }
    
    private var totalCalories: Int { consumedItems.reduce(0) { $0 + $1.calories } }
    private var totalCarbs: Double { consumedItems.reduce(0.0) { $0 + $1.carb } }
    private var totalProtein: Double { consumedItems.reduce(0.0) { $0 + $1.protein } }
    private var totalFat: Double { consumedItems.reduce(0.0) { $0 + $1.fat } }

    private var groupedItems: [(anchor: Date, items: [ConsumedItem])] {
        let ascending = consumedItems.sorted { $0.timestamp < $1.timestamp }
        var groups: [(Date, [ConsumedItem])] = []
        
        for item in ascending {
            if let last = groups.last, item.timestamp.timeIntervalSince(last.0) <= 900 {
                let index = groups.count - 1
                groups[index].1.append(item)
            } else {
                groups.append((item.timestamp, [item]))
            }
        }
        
        return groups.reversed().map { ($0.0, $0.1.reversed()) }
    }
    
    // NEW: Dynamically formats today's date for the header
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMM d"
        return formatter.string(from: Date())
    }
    
    // NEW: Converts the stored hour integer into a clean text format
    private func timeString(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased() // Outputs "4 am"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(currentDateString)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showResetTime = true
                            }
                            // Hide after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showResetTime = false
                                }
                            }
                        }
                    
                    if showResetTime {
                        Text("day resets at \(timeString(for: dayStartHour))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                TodayViewVisualDataBar(
                    calories: totalCalories,
                    carbs: totalCarbs,
                    protein: totalProtein,
                    fat: totalFat
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGroupedBackground))
                
                List {
                    Section(header: Text("My Log")) {
                        ForEach(groupedItems, id: \.anchor) { group in
                            
                            HStack(spacing: 8) {
                                Text(formattedRoundedTime(for: group.anchor))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        groupForAlert = group.items
                                    }
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                            .listRowSeparator(.hidden)
                            
                            ForEach(group.items) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        
                                        if let additives = item.recipeAdditives, !additives.isEmpty {
                                            Text("+ \(additives.map { $0.name }.joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text("\(String(format: "%g", item.servingSize)) \(item.servingUnit)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(item.calories) calories")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("F: \(item.fat, specifier: "%.0f")g | P: \(item.protein, specifier: "%.0f")g | C: \(item.carb, specifier: "%.0f")g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .listRowSeparator(.hidden)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if item.isRecipe {
                                        itemToView = item
                                    }
                                }
                                .contextMenu {
                                    if item.isRecipe {
                                        if item.recipeCustomBatchWeight == nil {
                                            Button {
                                                itemToEditIngredients = item
                                            } label: {
                                                Label("Edit Ingredients", systemImage: "list.bullet")
                                            }
                                        }
                                    } else {
                                        Button {
                                            editBaseServingSize = item.servingSize
                                            adjustedServingSize = item.servingSize
                                            itemToEdit = item
                                        } label: {
                                            Label("Edit Served Portion", systemImage: "pencil")
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            modelContext.delete(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // By omitting the .navigationTitle here, we let our custom header shine!
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $itemToEdit) { item in
                RadialHalfSheetSelector(
                    title: "Edit Portion",
                    subtitle: "Update your logged amount",
                    unit: item.servingUnit,
                    value: $adjustedServingSize,
                    baseValue: editBaseServingSize,
                    onDismiss: { itemToEdit = nil },
                    onSave: { 
                        if item.isRecipe && !customizedIngredients.isEmpty {
                            updateConsumedRecipe(item, customIngredients: customizedIngredients, newAmount: adjustedServingSize)
                            customizedIngredients = []
                        } else {
                            updateConsumedItem(item, newAmount: adjustedServingSize)
                        }
                    }
                )
            }
            .sheet(item: $itemToEditIngredients) { item in
                RecipeWeightsHalfSheetSelector(
                    initialIngredients: item.recipeIngredients ?? [],
                    onNext: { customIngredients in
                        customizedIngredients = customIngredients
                        
                        editBaseServingSize = customIngredients.reduce(0) { $0 + $1.recipeWeight }
                        adjustedServingSize = item.servingSize
                        
                        // Small delay to allow the first sheet to dismiss smoothly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            itemToEdit = item
                        }
                    }
                )
            }
            .popover(item: $itemToView) { item in
                NavigationStack {
                    List {
                        if let ingredients = item.recipeIngredients, !ingredients.isEmpty {
                            Section {
                                ForEach(ingredients) { ingredient in
                                    HStack {
                                        Text(ingredient.name)
                                            .fontWeight(.medium)
                                        Spacer()
                                        if item.recipeRatio == 1.0 {
                                            Text("\(String(format: "%.1f", ingredient.recipeWeight)) \(ingredient.servingUnit)")
                                                .foregroundColor(.secondary)
                                        } else {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("Recipe: \(String(format: "%.1f", ingredient.recipeWeight)) \(ingredient.servingUnit)")
                                                Text("Portion: \(String(format: "%.1f", ingredient.recipeWeight * item.recipeRatio)) \(ingredient.servingUnit)")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("Ingredients")
                                    Spacer()
                                    if item.isRecipe && item.recipeCustomBatchWeight == nil {
                                        Button {
                                            itemToView = nil
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                itemToEditIngredients = item
                                            }
                                        } label: {
                                            Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                                .font(.body)
                                        }
                                    }
                                }
                            }
                            
                            Section {
                                if let additives = item.recipeAdditives {
                                    ForEach(additives) { additive in
                                        HStack {
                                            Text(additive.name)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(String(format: "%.1f", additive.recipeWeight)) \(additive.servingUnit)")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("Extras")
                                    Spacer()
                                    Button {
                                        print("Add extra to consumed item")
                                    } label: {
                                        Image(systemName: "plus.app")
                                            .font(.body)
                                    }
                                }
                            }
                        } else {
                            Text("No ingredient details available.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .navigationTitle("Ingredients")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { itemToView = nil }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .alert("Change Meal Group Time?", isPresented: Binding(
                get: { groupForAlert != nil },
                set: { if !$0 { groupForAlert = nil } }
            )) {
                Button("Change") {
                    if let group = groupForAlert {
                        groupToEditTime = group
                        selectedGroupTime = group.first?.timestamp ?? Date()
                        showTimePickerSheet = true
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showTimePickerSheet) {
                NavigationStack {
                    DatePicker("Select Time", selection: $selectedGroupTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .navigationTitle("Edit Meal Time")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showTimePickerSheet = false }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    if let items = groupToEditTime {
                                        for item in items {
                                            item.timestamp = selectedGroupTime
                                        }
                                    }
                                    showTimePickerSheet = false
                                }
                            }
                        }
                        .presentationDetents([.medium])
                }
            }
        }
    }

    private func deleteItems(at offsets: IndexSet, in items: [ConsumedItem]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
    
    private func updateConsumedItem(_ item: ConsumedItem, newAmount: Double) {
        let ratio = item.servingSize > 0 ? (newAmount / item.servingSize) : 1.0
        
        item.calories = Int(round(Double(item.calories) * ratio))
        item.fat *= ratio
        item.saturatedFat *= ratio
        item.transFat *= ratio
        item.protein *= ratio
        item.carb *= ratio
        item.dietaryFiber *= ratio
        item.addedSugar *= ratio
        
        item.servingSize = newAmount
    }
    
    private func updateConsumedRecipe(_ item: ConsumedItem, customIngredients: [RecipeIngredient], newAmount: Double) {
        let baseTotalWeight = customIngredients.reduce(0) { $0 + $1.recipeWeight }
        let ratio = baseTotalWeight > 0 ? (newAmount / baseTotalWeight) : 1.0
        
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
        
        item.calories = Int(round(totalCalories * ratio))
        item.fat = totalFat * ratio
        item.saturatedFat = totalSaturatedFat * ratio
        item.transFat = totalTransFat * ratio
        item.protein = totalProtein * ratio
        item.carb = totalCarb * ratio
        item.dietaryFiber = totalDietaryFiber * ratio
        item.addedSugar = totalAddedSugar * ratio
        
        item.servingSize = newAmount
        item.recipeIngredients = customIngredients
    }
    
    private func formattedRoundedTime(for date: Date) -> String {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        
        let roundedMinute = Int(round(Double(minute) / 5.0) * 5.0)
        let minuteDifference = roundedMinute - minute
        
        let roundedDate = calendar.date(byAdding: .minute, value: minuteDifference, to: date) ?? date
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: roundedDate)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [UserSettings.self, ConsumedItem.self], inMemory: true)
}
