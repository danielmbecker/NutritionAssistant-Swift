import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
            
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
            
            FoodBankView()
                .tabItem {
                    Label("Food Bank", systemImage: "archivebox.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodItem.self, ConsumedItem.self], inMemory: true)
}
