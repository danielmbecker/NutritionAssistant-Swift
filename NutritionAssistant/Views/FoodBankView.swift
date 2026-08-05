import SwiftUI
import SwiftData

struct FoodBankView: View {
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [FoodItem]
    
    @State private var showingAddFood = false
    
    @State private var itemToLog: FoodItem?
    @State private var adjustedServingSize: Double = 0.0

    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("My Food Database")) {
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                
                                Text("\(item.calories) kcal | F: \(String(format: "%g", item.fat))g | P: \(String(format: "%g", item.protein))g | C: \(String(format: "%g", item.carb))g")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                adjustedServingSize = item.servingSize
                                itemToLog = item
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Food Bank")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddFood = true }) {
                        Label("Add New Food", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView()
            }
            .sheet(item: $itemToLog) { item in
                // Our beautifully abstracted reusable component!
                RadialHalfSheetSelector(
                    title: "How Much?",
                    subtitle: "Input your served portion",
                    unit: item.servingUnit,
                    value: $adjustedServingSize,
                    baseValue: item.servingSize,
                    onDismiss: { itemToLog = nil },
                    onSave: { logFood(item, amount: adjustedServingSize) }
                )
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
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
