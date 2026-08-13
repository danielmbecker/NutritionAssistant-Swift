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
    
    @State private var showingDiscardAlert = false
    @State private var pendingTab: Tab? = nil
    @State private var addRecipeID = UUID() // Used to reset AddRecipieView state
    @State private var isAddRecipeDirty = false // Tracks if user modified anything
    
    // Custom binding to intercept tab changes
    private var tabBinding: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if selectedTab == .addRecipe && newTab != .addRecipe && isAddRecipeDirty {
                    pendingTab = newTab
                    showingDiscardAlert = true
                } else {
                    selectedTab = newTab
                }
            }
        )
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
        .alert("Discard Recipe?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                if let nextTab = pendingTab {
                    selectedTab = nextTab
                    addRecipeID = UUID() // Triggers state reset of AddRecipieView
                    isAddRecipeDirty = false // Reset dirty flag
                }
            }
            Button("Cancel", role: .cancel) {
                pendingTab = nil
            }
        } message: {
            Text("Are you sure you want to leave? Your recipe entry will be lost.")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodItem.self, ConsumedItem.self, UserSettings.self, RecipeItem.self], inMemory: true)
}

