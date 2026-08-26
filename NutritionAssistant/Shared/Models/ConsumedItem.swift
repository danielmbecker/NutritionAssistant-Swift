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
    var category: FoodCategory
    
    var isRecipe: Bool
    var recipeCategory: String?
    var recipeIngredients: [RecipeIngredient]?
    var recipeAdditives: [RecipeIngredient]?
    
    init(timestamp: Date, logicalDate: Date, name: String, servingSize: Double, servingUnit: String, calories: Int, fat: Double, saturatedFat: Double, transFat: Double, protein: Double, carb: Double, dietaryFiber: Double, addedSugar: Double, category: FoodCategory = .preparedFoods, isRecipe: Bool = false, recipeCategory: String? = nil, recipeIngredients: [RecipeIngredient]? = nil, recipeAdditives: [RecipeIngredient]? = nil) {
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
}
