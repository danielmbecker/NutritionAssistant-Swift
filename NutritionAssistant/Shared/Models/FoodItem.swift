import Foundation
import SwiftData

enum FoodCategory: String, Codable, CaseIterable {
    case supplements = "Supplements"
    case meats = "Meats"
    case dairy = "Dairy"
    case seafood = "Seafood"
    case eggs = "Eggs"
    case breadsAndGrains = "Breads & Grains"
    case nutsAndSeeds = "Nuts & Seeds"
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case drinks = "Drinks"
    case sugars = "Sugars"
    case sweetSnacks = "Sweet Snacks"
    case saltySnacks = "Salty Snacks"
    case oils = "Oils"
    case spreadsAndSauces = "Spreads & Sauces"
    case preparedFoods = "Prepared Foods"
}

@Model
final class FoodItem {
    var timestamp: Date
    var brandName: String
    var name: String
    var processingLevel: String
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
    
    init(timestamp: Date, brandName: String, name: String, processingLevel: String, servingSize: Double, servingUnit: String, calories: Int, fat: Double, saturatedFat: Double, transFat: Double, protein: Double, carb: Double, dietaryFiber: Double, addedSugar: Double, category: FoodCategory = .preparedFoods) {
        self.timestamp = timestamp
        self.brandName = brandName
        self.name = name
        self.processingLevel = processingLevel
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
    }
}
