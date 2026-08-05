import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    @Query(sort: \ConsumedItem.timestamp, order: .reverse) private var consumedItems: [ConsumedItem]
    
    // We default to ONE logical day ago
    @State private var selectedLogicalDate: Date = Calendar.current.date(
        byAdding: .day,
        value: -1,
        to: Date().logicalDay(startHour: UserDefaults.standard.integer(forKey: "dayStartHour"))
    ) ?? Date()
    
    // Filter simply by the logical stamp!
    private var dailyItems: [ConsumedItem] {
        consumedItems.filter { $0.logicalDate == selectedLogicalDate }
    }
    
    private var totalCalories: Int { dailyItems.reduce(0) { $0 + $1.calories } }
    private var totalCarbs: Double { dailyItems.reduce(0.0) { $0 + $1.carb } }
    private var totalProtein: Double { dailyItems.reduce(0.0) { $0 + $1.protein } }
    private var totalFat: Double { dailyItems.reduce(0.0) { $0 + $1.fat } }
    
    private var dateString: String {
        let todayLogical = Date().logicalDay(startHour: dayStartHour)
        if selectedLogicalDate == todayLogical {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return formatter.string(from: selectedLogicalDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack {
                    Button(action: { withAnimation { changeDate(by: -1) } }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(dateString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    let todayLogical = Date().logicalDay(startHour: dayStartHour)
                    Button(action: { withAnimation { changeDate(by: 1) } }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(selectedLogicalDate == todayLogical ? .gray.opacity(0.3) : .blue)
                    }
                    .disabled(selectedLogicalDate == todayLogical)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                CalorieEtcDataView(
                    calories: totalCalories,
                    carbs: totalCarbs,
                    protein: totalProtein,
                    fat: totalFat
                )
                .padding(.horizontal)
                
                Spacer()
                
                Text("Swipe left or right to switch days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
            }
            .navigationTitle("History")
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 50 {
                            withAnimation { changeDate(by: -1) }
                        }
                        else if value.translation.width < -50 {
                            let todayLogical = Date().logicalDay(startHour: dayStartHour)
                            if selectedLogicalDate != todayLogical {
                                withAnimation { changeDate(by: 1) }
                            }
                        }
                    }
            )
        }
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedLogicalDate) {
            selectedLogicalDate = newDate
        }
    }
}
