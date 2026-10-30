import SwiftUI
import SwiftData

@main
struct NutritionAssistantApp: App {
    var sharedModelContainer: ModelContainer = {
        // We add UserSettings.self to the schema list!
        let schema = Schema([
            FoodItem.self,
            ConsumedItem.self,
            UserSettings.self,
            RecipeItem.self,
            UserRecipeCategory.self,
            UserFoodCategory.self,
            UserMeasurementUnit.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
