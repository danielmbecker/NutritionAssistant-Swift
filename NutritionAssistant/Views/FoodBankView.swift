import SwiftUI
import SwiftData

struct FoodBankView: View {
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var items: [FoodItem]
    
    @State private var showingAddFood = false
    
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
                        LazyVStack(alignment: .leading, spacing: 4) {
                            Text(group.category.displayName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal) 
//                                .padding(.top, 8)
                            
                            ForEach(group.items) { item in
                                HStack(spacing: 0) {
                                    HStack(spacing: 4) {
                                        Text(item.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        
                                        if !item.brandName.isEmpty {
                                            Text(item.brandName)
                                                .font(.caption2).italic()
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    /* 
                                    Text("\(item.calories) cal | F: \(String(format: "%g", item.fat))g | C: \(String(format: "%g", item.carb))g | P: \(String(format: "%g", item.protein))g")
                                        .font(.caption).italic()
                                        .foregroundColor(.secondary)
                                    */
                                    
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
                                .padding(.vertical, 0)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    adjustedServingSize = item.servingSize
                                    itemToLog = item
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            modelContext.delete(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }.padding().background(colorScheme == .dark ? Color(hex: "0f0f0f") : Color(hex: "FAFAFA")).cornerRadius(10)
                }
                .padding(.vertical)
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
            .sheet(item: $itemToLog) { item in
                // Our beautifully abstracted reusable component!
                RadialHalfSheetSelector(
                    title: "How much \(item.name)?",
                    subtitle: "Input your served portion",
                    unit: item.servingUnit,
                    value: $adjustedServingSize,
                    baseValue: item.servingSize,
                    onDismiss: { itemToLog = nil },
                    onSave: { logFood(item, amount: adjustedServingSize) }
                )
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
