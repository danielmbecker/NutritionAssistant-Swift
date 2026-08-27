import SwiftUI
import SwiftData

enum FoodListItem: Identifiable {
    case single(FoodItem)
    case group(String, [FoodItem])
    
    var id: String {
        switch self {
        case .single(let food): return food.id.uuidString
        case .group(let name, _): return name
        }
    }
    
    var name: String {
        switch self {
        case .single(let food): return food.name
        case .group(let name, _): return name
        }
    }
}

struct FoodBankView: View {
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var items: [FoodItem]
    
    @State private var showingAddFood = false
    @State private var foodToEdit: FoodItem?
    
    @State private var itemToLog: FoodItem?
    @State private var adjustedServingSize: Double = 0.0
    
    @State private var expandedItemIDs: Set<String> = []
    @State private var highlightedCategory: String?

    var groupedItems: [(category: String, items: [FoodListItem])] {
        let categoryGrouped = Dictionary(grouping: items, by: { $0.category })
        return categoryGrouped.map { category, foods in
            let sortedFoods = foods.sorted { $0.name < $1.name }
            var variationGroups: [String: [FoodItem]] = [:]
            var singles: [FoodItem] = []
            
            for food in sortedFoods {
                if let groupName = food.foodVariationGroup, !groupName.isEmpty {
                    variationGroups[groupName, default: []].append(food)
                } else {
                    singles.append(food)
                }
            }
            
            var resultList: [FoodListItem] = singles.map { .single($0) }
            for (groupName, items) in variationGroups {
                resultList.append(.group(groupName, items))
            }
            resultList.sort { $0.name < $1.name }
            return (category, resultList)
        }
        .sorted {
            let order1 = FoodCategoryList.displayOrder(for: $0.category)
            let order2 = FoodCategoryList.displayOrder(for: $1.category)
            
            if order1 == 999 && order2 == 999 {
                return $0.category < $1.category
            }
            return order1 < order2
        }
    }
    
    private var navigationCategories: [NavigationCategory<String>] {
        groupedItems.map { group in
            let cat = group.category
            let displayName = FoodCategoryList.displayName(for: cat)
            let firstChar = displayName.first?.lowercased() ?? "c"
            return NavigationCategory(
                id: cat,
                label: displayName,
                iconName: "\(firstChar).circle"
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(groupedItems, id: \.category) { group in
                                VStack(spacing: 0) {
                                    Color.clear
                                        .frame(height: 0)
                                        .id(group.category)
                                    
                                    LazyVStack(alignment: .leading, spacing: 4) {
                                        Text(FoodCategoryList.displayName(for: group.category))
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal) 
                                        
                                        ForEach(group.items) { item in
                                            switch item {
                                            case .single(let food):
                                                foodRow(food)
                                            case .group(let groupName, let foods):
                                                groupRow(groupName: groupName, items: foods)
                                            }
                                            
                                            if item.id != group.items.last?.id {
                                                Divider()
                                                    .padding(.leading)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(colorScheme == .dark ? Color(hex: "0f0f0f") : Color(hex: "FAFAFA"))
                                    .cornerRadius(10)
                                    .shadow(color: highlightedCategory == group.category ? Color.white.opacity(0.4) : .clear, radius: highlightedCategory == group.category ? 8 : 0)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    IconNavigationHelper(categories: navigationCategories) { categoryID in
                        withAnimation {
                            proxy.scrollTo(categoryID, anchor: UnitPoint(x: 0.5, y: 0.3))
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                highlightedCategory = categoryID
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    highlightedCategory = nil
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Food Bank")
            .toolbar {
                ToolbarItem {
                    Button(action: { showingAddFood = true }) {
                        Label("Add New Food", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView()
            }
            .sheet(item: $foodToEdit) { item in
                AddFoodView(existingFood: item)
            }
            .sheet(item: $itemToLog) { item in
                // Our beautifully abstracted reusable component!
                RadialHalfSheetSelector(
                    title: "How much \(item.name)?",
                    subtitle: "Input your served portion",
                    unit: item.servingUnit,
                    value: $adjustedServingSize,
                    baseValue: item.servingSize,
                    onDismiss: { itemToLog = nil },
                    onSave: { logFood(item, amount: adjustedServingSize) },
                    baseCalories: item.calories,
                    baseFat: item.fat,
                    baseCarb: item.carb,
                    baseProtein: item.protein
                )
            }
        }
    }
    
    @ViewBuilder
    private func foodRow(_ item: FoodItem) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(item.name)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !item.brandName.isEmpty && item.brandName.lowercased() != "unbranded" {
                    Text(item.brandName)
                        .font(.caption2).italic()
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer(minLength: 8)
            
            HStack(spacing: 7) {
                Text("\(item.calories)")
                    .font(.caption).bold()
                    .monospacedDigit()
                    .foregroundColor(.gray)
                    .frame(width: 34, alignment: .trailing)
                Text("\(String(format: "%g", item.fat))")
                    .font(.caption).bold()
                    .monospacedDigit()
                    .foregroundColor(Color(hex: "#FDE4BE"))
                    .frame(width: 30, alignment: .trailing)
                Text("\(String(format: "%g", item.carb))")
                    .font(.caption).bold()
                    .monospacedDigit()
                    .foregroundColor(Color(hex: "#BEFDE4"))
                    .frame(width: 30, alignment: .trailing)
                Text("\(String(format: "%g", item.protein))")
                    .font(.caption).bold()
                    .monospacedDigit()
                    .foregroundColor(Color(hex: "#E4BEFD"))
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            adjustedServingSize = item.servingSize
            itemToLog = item
        }
        .contextMenu {
            Button {
                foodToEdit = item
            } label: {
                Label("Edit This Food", systemImage: "pencil")
            }

            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(item)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func groupRow(groupName: String, items: [FoodItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                
                Text(groupName)
                    .font(.caption)
                    .bold()
                Image(systemName: "square.stack.3d.down.right.fill")
                    .foregroundColor(.accentColor)
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
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
                    ForEach(items) { item in
                        Divider()
                            .padding(.leading, 32)
                        foodRow(item)
                            .padding(.leading, 16)
                    }
                }
                .padding(.top, 0)
            }
        }
    }

    private func logFood(_ item: FoodItem, amount: Double) {
        let ratio = item.servingSize > 0 ? (amount / item.servingSize) : 1.0
        let now = Date()

        let loggedItem = ConsumedItem(
            timestamp: now,
            logicalDate: now.logicalDay(startHour: dayStartHour), // Stamped permanently!
            name: item.name,
            servingSize: amount,
            servingUnit: item.servingUnit,
            calories: Int(round(Double(item.calories) * ratio)),
            fat: item.fat * ratio,
            saturatedFat: item.saturatedFat * ratio,
            transFat: item.transFat * ratio,
            protein: item.protein * ratio,
            carb: item.carb * ratio,
            dietaryFiber: item.dietaryFiber * ratio,
            addedSugar: item.addedSugar * ratio
        )

        modelContext.insert(loggedItem)
    }
}

#Preview {
    do {
        // 1. Create a temporary, in-memory configuration so we don't save mock data permanently
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        // 2. Initialize the container.
        // (I included ConsumedItem here as well, since your view references it when logging food!)
        let container = try ModelContainer(for: FoodItem.self, ConsumedItem.self, configurations: config)
        
        // 3. Loop through our hardcoded array and insert each item into the preview's context
        for item in FoodItem.previewData {
            container.mainContext.insert(item)
        }
        
        // 4. Return your view and attach the mock container to it
        return FoodBankView()
            .modelContainer(container)
            
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}
