//
//  ScannedFoodBankView.swift
//  NutritionAssistant
//
//  Milestone 6.5: Full-Spectrum ScannedFoodItem Bank View
//  Displays active (`!isArchived`) ScannedFoodItem records grouped by category and variation group,
//  retaining the compact 4-column summary row (`Calories | Fat | Carb | Protein`) alongside a quick
//  digital-label inspector button, portion logging via RadialHalfSheetSelector, and creation/editing
//  via ScannedAddFoodView.
//

import SwiftData
import SwiftUI

enum ScannedFoodListItem: Identifiable {
    case single(ScannedFoodItem)
    case group(String, [ScannedFoodItem])

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

struct ScannedFoodBankView: View {
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    /// Queries only active (non-archived) `ScannedFoodItem` records so superseded Copy-on-Edit snapshots remain hidden.
    @Query(filter: #Predicate<ScannedFoodItem> { !$0.isArchived })
    private var items: [ScannedFoodItem]

    @State private var showingAddScannedFood = false
    @State private var itemToEdit: ScannedFoodItem?
    @State private var itemToLog: ScannedFoodItem?
    @State private var adjustedServingSize: Double = 0.0

    @State private var expandedGroupIDs: Set<String> = []
    @State private var highlightedCategory: String?

    var groupedItems: [(category: String, items: [ScannedFoodListItem])] {
        let categoryGrouped = Dictionary(grouping: items, by: { $0.category })
        return categoryGrouped.map { category, foods in
            let sortedFoods = foods.sorted { $0.name < $1.name }
            var variationGroups: [String: [ScannedFoodItem]] = [:]
            var singles: [ScannedFoodItem] = []

            for food in sortedFoods {
                if let groupName = food.foodVariationGroup, !groupName.isEmpty {
                    variationGroups[groupName, default: []].append(food)
                } else {
                    singles.append(food)
                }
            }

            var resultList: [ScannedFoodListItem] = singles.map { .single($0) }
            for (groupName, groupFoods) in variationGroups {
                resultList.append(.group(groupName, groupFoods))
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
                if items.isEmpty {
                    emptyStateView
                } else {
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
                                                    scannedFoodRow(food)
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
                                        .shadow(
                                            color: highlightedCategory == group.category ? Color.white.opacity(0.4) : .clear,
                                            radius: highlightedCategory == group.category ? 8 : 0
                                        )
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
            }
            .navigationTitle("Scanned Food Bank")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddScannedFood = true
                    } label: {
                        Label("Add Scanned Food", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddScannedFood) {
                NavigationStack {
                    ScannedAddFoodView()
                }
            }
            .sheet(item: $itemToEdit) { item in
                NavigationStack {
                    ScannedAddFoodView(existingItem: item)
                }
            }
            .sheet(item: $itemToLog) { item in
                RadialHalfSheetSelector(
                    title: "How much \(item.name)?",
                    subtitle: "Input your served portion",
                    unit: item.servingUnit,
                    value: $adjustedServingSize,
                    baseValue: item.servingSize,
                    onDismiss: { itemToLog = nil },
                    onSave: { logScannedFood(item, amount: adjustedServingSize) },
                    baseCalories: item.calories,
                    baseFat: item.fat,
                    baseCarb: item.carb,
                    baseProtein: item.protein
                )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 46))
                .foregroundStyle(.secondary)
            Text("No Scanned Foods Yet")
                .font(.title3.weight(.semibold))
            Text("Scan a Nutrition Facts or Supplement Facts panel to view and edit its full-spectrum digital FDA label.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Button {
                showingAddScannedFood = true
            } label: {
                Label("Scan or Add Food", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    @ViewBuilder
    private func scannedFoodRow(_ item: ScannedFoodItem) -> some View {
        HStack(spacing: 0) {
            Button {
                itemToEdit = item
            } label: {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .padding(.trailing, 6)
            }
            .buttonStyle(.plain)

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

                if item.previousVersionID != nil {
                    Text("v2+")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
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
                itemToEdit = item
            } label: {
                Label("Inspect / Edit Digital FDA Label", systemImage: "pencil")
            }

            Button {
                adjustedServingSize = item.servingSize
                itemToLog = item
            } label: {
                Label("Log Portion to Today", systemImage: "plus.circle")
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
    private func groupRow(groupName: String, items: [ScannedFoodItem]) -> some View {
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
                if expandedGroupIDs.contains(groupName) {
                    expandedGroupIDs.remove(groupName)
                } else {
                    expandedGroupIDs.insert(groupName)
                }
            }

            if expandedGroupIDs.contains(groupName) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        Divider()
                            .padding(.leading, 32)
                        scannedFoodRow(item)
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func logScannedFood(_ item: ScannedFoodItem, amount: Double) {
        let ratio = item.servingSize > 0 ? (amount / item.servingSize) : 1.0
        let now = Date()

        let loggedItem = ConsumedItem(
            timestamp: now,
            logicalDate: now.logicalDay(startHour: dayStartHour),
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
    ScannedFoodBankView()
        .modelContainer(for: [ScannedFoodItem.self, ConsumedItem.self, UserFoodCategory.self], inMemory: true)
}
