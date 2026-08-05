import Foundation
import SwiftData

@Model
final class FoodItem {
    var timestamp: Date // Kept securely in place!
    var name: String // New property so you know what you are logging
    var calories: Int
    var fat: Int
    var protein: Int
    var carb: Int
    
    init(timestamp: Date, name: String, calories: Int, fat: Int, protein: Int, carb: Int) {
        self.timestamp = timestamp
        self.name = name
        self.calories = calories
        self.fat = fat
        self.protein = protein
        self.carb = carb
    }
}
