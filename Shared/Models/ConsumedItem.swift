import Foundation
import SwiftData

@Model
final class ConsumedItem {
    var timestamp: Date
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
    
    init(timestamp: Date = Date(), name: String, servingSize: Double, servingUnit: String, calories: Int, fat: Double, saturatedFat: Double, transFat: Double, protein: Double, carb: Double, dietaryFiber: Double, addedSugar: Double) {
        self.timestamp = timestamp
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
    }
}
