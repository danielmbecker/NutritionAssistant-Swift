import SwiftUI
import SwiftData

struct ContentView: View {
    // 1. We create a clean list of our available tabs
    enum Tab {
        case history
        case today
        case foodBank
    }
    
    // 2. We set the default starting value to our "today" tab
    @State private var selectedTab: Tab = .today
    
    var body: some View {
        // 3. We bind the TabView to our state variable
        TabView(selection: $selectedTab) {
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history) // 4. Tag the view so the TabView recognizes it
            
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(Tab.today)
            
            FoodBankView()
                .tabItem {
                    Label("Food Bank", systemImage: "archivebox.fill")
                }
                .tag(Tab.foodBank)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodItem.self, ConsumedItem.self], inMemory: true)
}
