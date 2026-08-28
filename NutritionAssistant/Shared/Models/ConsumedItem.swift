import Foundation
import SwiftData

@Model
final class ConsumedItem {
    var id: UUID = UUID()
    var timestamp: Date
    var logicalDate: Date // NEW: The specific "Day" this belongs to!
    var name: String
    var servingSize: Double
    var servingUnit: String
    var calories: Int
    var fat: Double
    var saturatedFat: Double
    var transFat: Double
    var protein: Double
    var carb: Double
    var dietaryFiber: Double
    var addedSugar: Double
    var category: String
    
    var isRecipe: Bool
    var recipeCategory: String?
    var recipeIngredients: [RecipeIngredient]?
    var recipeAdditives: [RecipeIngredient]?
    var recipeCustomBatchWeight: Double?
    var recipeRatio: Double = 1.0
    
    init(timestamp: Date, logicalDate: Date, name: String, servingSize: Double, servingUnit: String, calories: Int, fat: Double, saturatedFat: Double, transFat: Double, protein: Double, carb: Double, dietaryFiber: Double, addedSugar: Double, category: String = "Prepared Foods", isRecipe: Bool = false, recipeCategory: String? = nil, recipeIngredients: [RecipeIngredient]? = nil, recipeAdditives: [RecipeIngredient]? = nil, recipeCustomBatchWeight: Double? = nil, recipeRatio: Double = 1.0) {
        self.timestamp = timestamp
        self.logicalDate = logicalDate
        self.name = name
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.protein = protein
        self.carb = carb
        self.dietaryFiber = dietaryFiber
        self.addedSugar = addedSugar
        self.category = category
        self.isRecipe = isRecipe
        self.recipeCategory = recipeCategory
        self.recipeIngredients = recipeIngredients
        self.recipeAdditives = recipeAdditives
        self.recipeCustomBatchWeight = recipeCustomBatchWeight
        self.recipeRatio = recipeRatio
    }
}

// MARK: - Logical Date Helper
extension Date {
    func logicalDay(startHour: Int) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        
        // If the current hour is before the user's start hour, it belongs to the previous day!
        let adjustedDate = hour < startHour ? calendar.date(byAdding: .day, value: -1, to: self) ?? self : self
        
        // Returns exactly midnight of that logical day to make searching super easy
        return calendar.startOfDay(for: adjustedDate)
    }
    
    // NEW: Calculates the exact starting Date (e.g. 4:00 AM) of the current logical day
    func healthKitWindowStart(startHour: Int) -> Date {
        let logicalMidnight = self.logicalDay(startHour: startHour)
        return Calendar.current.date(bySettingHour: startHour, minute: 0, second: 0, of: logicalMidnight) ?? logicalMidnight
    }
}
