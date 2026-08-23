import Foundation
import SwiftData

enum RecipeMeasurementType: String, Codable {
    case fraction = "Fraction"
    case weight = "Weight"
}

enum RecipeCategory: String, Codable, CaseIterable {
    case soupsAndSalads = "Soups & Salads"
    case vegetables = "Vegetables"
    case entrees = "Entrees"
    case seafood = "Seafood"
    case meat = "Meat"
    case sauces = "Sauces"
    case breakfast = "Breakfast"
    case desserts = "Desserts"
    case eggs = "Eggs"
    case appetizers = "Appetizers"
    case beverages = "Beverages"
    case breadAndPasta = "Bread & Pasta"
    case snack = "Snack"
    case vegetarian = "Vegetarian"
}

struct RecipeIngredient: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var foodItemID: UUID
    
    var brandName: String
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
    
    var recipeWeight: Double
    
    init(from foodItem: FoodItem, recipeWeight: Double) {
        self.foodItemID = foodItem.id
        self.brandName = foodItem.brandName
        self.name = foodItem.name
        self.servingSize = foodItem.servingSize
        self.servingUnit = foodItem.servingUnit
        self.calories = foodItem.calories
        self.fat = foodItem.fat
        self.saturatedFat = foodItem.saturatedFat
        self.transFat = foodItem.transFat
        self.protein = foodItem.protein
        self.carb = foodItem.carb
        self.dietaryFiber = foodItem.dietaryFiber
        self.addedSugar = foodItem.addedSugar
        self.category = foodItem.category
        self.recipeWeight = recipeWeight
    }
}

@Model
final class RecipeItem {
    var id: UUID = UUID()
    var name: String
    var type: String
    var measurementType: RecipeMeasurementType
    var ingredients: [RecipeIngredient]
    var category: RecipeCategory
    
    init(name: String, type: String, measurementType: RecipeMeasurementType = .weight, ingredients: [RecipeIngredient] = [], category: RecipeCategory = .entrees) {
        self.name = name
        self.type = type
        self.measurementType = measurementType
        self.ingredients = ingredients
        self.category = category
    }
}

extension RecipeItem {
    var totalCalories: Int {
        let total = ingredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (Double(ingredient.calories) * ratio)
        }
        return Int(round(total))
    }
    
    var totalFat: Double {
        ingredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.fat * ratio)
        }
    }
    
    var totalCarb: Double {
        ingredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.carb * ratio)
        }
    }
    
    var totalProtein: Double {
        ingredients.reduce(0.0) { sum, ingredient in
            let ratio = ingredient.servingSize > 0 ? (ingredient.recipeWeight / ingredient.servingSize) : 1.0
            return sum + (ingredient.protein * ratio)
        }
    }
    
    var totalBatchWeight: Double {
        ingredients.reduce(0.0) { $0 + $1.recipeWeight }
    }
}

// MARK: - DTO Conversion
extension RecipeItem {
    func toDTO() -> RecipeItemDTO {
        return RecipeItemDTO(
            id: self.id,
            name: self.name,
            type: self.type,
            measurementType: self.measurementType,
            ingredients: self.ingredients,
            category: self.category
        )
    }
    
    convenience init(from dto: RecipeItemDTO) {
        self.init(
            name: dto.name,
            type: dto.type,
            measurementType: dto.measurementType,
            ingredients: dto.ingredients,
            category: dto.category
        )
        self.id = dto.id
    }
}
