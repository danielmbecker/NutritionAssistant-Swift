import Foundation
import SwiftData

@Model
final class FoodItem {
    var timestamp: Date
    var brandName: String
    var name: String
    var processingLevel: String
    var servingSize: Double
    var servingUnit: String
    var calories: Int
    // Updated these macros to Double to allow for .5 values
    var fat: Double
    var saturatedFat: Double
    var transFat: Double
    var protein: Double
    var carb: Double
    var dietaryFiber: Double
    var addedSugar: Double
    
    init(timestamp: Date, brandName: String, name: String, processingLevel: String, servingSize: Double, servingUnit: String, calories: Int, fat: Double, saturatedFat: Double, transFat: Double, protein: Double, carb: Double, dietaryFiber: Double, addedSugar: Double) {
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
    }
}
