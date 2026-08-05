import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Fetches all consumed items
    @Query(sort: \ConsumedItem.timestamp, order: .forward) private var consumedItems: [ConsumedItem]
    
    // Filters the items so we only see today's logs
    private var todaysItems: [ConsumedItem] {
        let calendar = Calendar.current
        return consumedItems.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Today's Log")) {
                    if todaysItems.isEmpty {
                        Text("No food logged today yet. Head to the Food Bank to add some!")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(todaysItems) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    Text("\(item.calories) kcal | F: \(String(format: "%g", item.fat))g | P: \(String(format: "%g", item.protein))g | C: \(String(format: "%g", item.carb))g")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("Today")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                // Ensure we delete the correct item from our filtered list
                let itemToDelete = todaysItems[index]
                modelContext.delete(itemToDelete)
            }
        }
    }
}
