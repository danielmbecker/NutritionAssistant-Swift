import Foundation
import SwiftData

enum RecipeMeasurementType: String, Codable {
    case fraction = "Fraction"
    case weight = "Weight"
}

struct RecipeCategory {
    static let defaultCategories = [
        "Soups & Salads",
        "Vegetables",
        "Entrees",
        "Seafood",
        "Meat",
        "Sauces",
        "Breakfast",
        "Desserts",
        "Eggs",
        "Appetizers",
        "Beverages",
        "Bread & Pasta",
        "Snack",
        "Vegetarian"
    ]
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
    var category: String
    var customBatchWeight: Double?
    var finalWeightPostponed: Bool
    var servingSize: Double?
    
    init(name: String, type: String, measurementType: RecipeMeasurementType = .weight, ingredients: [RecipeIngredient] = [], category: String = "Entrees", customBatchWeight: Double? = nil, finalWeightPostponed: Bool = false, servingSize: Double? = nil) {
        self.name = name
        self.type = type
        self.measurementType = measurementType
        self.ingredients = ingredients
        self.category = category
        self.customBatchWeight = customBatchWeight
        self.finalWeightPostponed = finalWeightPostponed
        self.servingSize = servingSize
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
        if let custom = customBatchWeight {
            return custom
        }
        return ingredients.reduce(0.0) { $0 + $1.recipeWeight }
    }
    
    var servingRatio: Double {
        guard let serving = servingSize, serving > 0 else { return 1.0 }
        
        if measurementType == .weight {
            let tbw = totalBatchWeight
            return tbw > 0 ? (serving / tbw) : 1.0
        } else {
            // Fraction recipe
            if serving < 1.0 {
                return serving // e.g. 0.25 (1/4 of the recipe)
            } else {
                return 1.0 / serving // e.g. 3.0 circles means the recipe makes 3 portions, so 1 portion is 1/3 of the recipe
            }
        }
    }
    
    var servingCalories: Int {
        return Int(round(Double(totalCalories) * servingRatio))
    }
    
    var servingFat: Double {
        return totalFat * servingRatio
    }
    
    var servingCarb: Double {
        return totalCarb * servingRatio
    }
    
    var servingProtein: Double {
        return totalProtein * servingRatio
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
            category: self.category,
            customBatchWeight: self.customBatchWeight,
            finalWeightPostponed: self.finalWeightPostponed,
            servingSize: self.servingSize
        )
    }
    
    convenience init(from dto: RecipeItemDTO) {
        self.init(
            name: dto.name,
            type: dto.type,
            measurementType: dto.measurementType,
            ingredients: dto.ingredients,
            category: dto.category,
            customBatchWeight: dto.customBatchWeight,
            finalWeightPostponed: dto.finalWeightPostponed ?? false,
            servingSize: dto.servingSize
        )
        self.id = dto.id
    }
}
