import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsList: [UserSettings]
    
    private var dayStartHour: Int {
        userSettingsList.first?.dayStartHour ?? 0
    }
    
    @Query(sort: \ConsumedItem.timestamp, order: .reverse) private var consumedItems: [ConsumedItem]
    
    @State private var itemToView: ConsumedItem?
    @State private var itemToEdit: ConsumedItem?
    @State private var itemToEditIngredients: ConsumedItem?
    @State private var customizedIngredients: [RecipeIngredient] = []
    @State private var adjustedServingSize: Double = 0.0
    /// Captures the serving size at the moment the edit sheet opens, before any mutation.
    @State private var editBaseServingSize: Double = 0.0
    @State private var showSettings = false
    @State private var showResetTime = false
    
    private var todaysItems: [ConsumedItem] {
        let todayLogical = Date().logicalDay(startHour: dayStartHour)
        return consumedItems.filter { $0.logicalDate == todayLogical }
    }
    
    private var totalCalories: Int { todaysItems.reduce(0) { $0 + $1.calories } }
    private var totalCarbs: Double { todaysItems.reduce(0.0) { $0 + $1.carb } }
    private var totalProtein: Double { todaysItems.reduce(0.0) { $0 + $1.protein } }
    private var totalFat: Double { todaysItems.reduce(0.0) { $0 + $1.fat } }

    private var groupedItems: [(anchor: Date, items: [ConsumedItem])] {
        let ascending = todaysItems.sorted { $0.timestamp < $1.timestamp }
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
                                        
                                        Text("\(String(format: "%g", item.servingSize)) \(item.servingUnit)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(item.calories)")
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
                                        Button {
                                            itemToEditIngredients = item
                                        } label: {
                                            Label("Edit Ingredients", systemImage: "list.bullet")
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
                            ForEach(ingredients) { ingredient in
                                HStack {
                                    Text(ingredient.name)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(String(format: "%.1f", ingredient.recipeWeight)) \(ingredient.servingUnit)")
                                        .foregroundColor(.secondary)
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
