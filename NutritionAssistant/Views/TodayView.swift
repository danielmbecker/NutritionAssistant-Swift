import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    
    @Query(sort: \ConsumedItem.timestamp, order: .reverse) private var consumedItems: [ConsumedItem]
    
    @State private var itemToEdit: ConsumedItem?
    @State private var adjustedServingSize: Double = 0.0
    
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
        formatter.dateStyle = .long // Outputs something like "July 12, 2026"
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
                
                // NEW: Our beautiful custom header replacing the standard navigation title!
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(currentDateString)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("day resets at \(timeString(for: dayStartHour))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                CalorieEtcDataView(
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
                                        Text("\(item.calories) kcal")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("F: \(item.fat, specifier: "%.0f")g | P: \(item.protein, specifier: "%.0f")g | C: \(item.carb, specifier: "%.0f")g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        itemToEdit = item
                                        adjustedServingSize = item.servingSize
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                            }
                            .onDelete { offsets in
                                deleteItems(at: offsets, in: group.items)
                            }
                        }
                    }
                }
            }
            // By omitting the .navigationTitle here, we let our custom header shine!
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(item: $itemToEdit) { item in
                RadialHalfSheetSelector(
                    title: "Edit Portion",
                    subtitle: "Update your logged amount",
                    unit: item.servingUnit,
                    value: $adjustedServingSize,
                    baseValue: item.servingSize,
                    onDismiss: { itemToEdit = nil },
                    onSave: { updateConsumedItem(item, newAmount: adjustedServingSize) }
                )
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
