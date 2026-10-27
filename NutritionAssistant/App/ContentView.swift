import SwiftUI
import SwiftData

struct ContentView: View {
    // 1. We create a clean list of our available tabs
    // this is a test 
    enum Tab {
        case history
        case today
        case foodBank
        case recipeBank
        case addRecipe
        case home
    }
    
    // 2. We set the default starting value to our "today" tab
    @State private var selectedTab: Tab = .today
    
    @State private var addRecipeID = UUID() // Used to reset AddRecipieView state
    @State private var isAddRecipeDirty = false // Tracks if user modified anything
    @State private var lastLeftAddRecipeTime: Date? = nil
    
    // Custom binding to intercept tab changes
    private var tabBinding: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if selectedTab == .addRecipe && newTab != .addRecipe {
                    // Record timestamp when leaving AddRecipe
                    lastLeftAddRecipeTime = Date()
                } else if selectedTab != .addRecipe && newTab == .addRecipe {
                    // Check if 180 seconds have elapsed since we left
                    if let leftTime = lastLeftAddRecipeTime, Date().timeIntervalSince(leftTime) > 180 {
                        addRecipeID = UUID()
                        isAddRecipeDirty = false
                    }
                    lastLeftAddRecipeTime = nil
                }
                selectedTab = newTab
            }
        )
    }
    @Query private var userSettingsList: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    
    var primaryColor: Color {
        Color(hex: userSettingsList.first?.userSelectedPrimaryColorHex ?? "#007AFF")
    }
    
    var body: some View {
        // 3. We bind the TabView to our custom interceptor binding
        TabView(selection: tabBinding) {
            
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
                
            RecipeBankView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(Tab.recipeBank)
                
            AddRecipieView(isDirty: $isAddRecipeDirty)
                .id(addRecipeID) // Forces a complete reset when UUID changes
                .tabItem {
                    Label("Add Recipe", systemImage: "plus.square.fill")
                }
                .tag(Tab.addRecipe)
           
        }
        .tint(primaryColor)
        .accentColor(primaryColor)
        .onAppear {
            if userSettingsList.count > 1 {
                for i in 1..<userSettingsList.count {
                    modelContext.delete(userSettingsList[i])
                }
                try? modelContext.save()
            } else if userSettingsList.isEmpty {
                let defaultSettings = UserSettings()
                modelContext.insert(defaultSettings)
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodItem.self, ConsumedItem.self, UserSettings.self, RecipeItem.self], inMemory: true)
}

