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
    
    var displayName: String {
        switch self {
        case .supplements: return "Supplements"
        case .meats: return "Meats"
        case .dairy: return "Dairy"
        case .seafood: return "Seafood"
        case .eggs: return "Eggs"
        case .breadsAndGrains: return "Breads/Cereals/Grains"
        case .nutsAndSeeds: return "Nuts & Seeds"
        case .vegetables: return "Vegetables"
        case .fruits: return "Fruit"
        case .drinks: return "Drink"
        case .sugars: return "Sugar"
        case .sweetSnacks: return "Sweet Snack"
        case .saltySnacks: return "Salty Snacks"
        case .oils: return "Oil"
        case .spreadsAndSauces: return "Spreads/Sauces/Condiments"
        case .preparedFoods: return "Prepared Food"
        }
    }
    
    var displayOrder: Int {
        switch self {
        case .supplements: return 1
        case .seafood: return 2
        case .dairy: return 3
        case .eggs: return 4
        case .breadsAndGrains: return 5
        case .nutsAndSeeds: return 6
        case .vegetables: return 7
        case .fruits: return 8
        case .drinks: return 9
        case .sugars: return 10
        case .sweetSnacks: return 11
        case .oils: return 12
        case .spreadsAndSauces: return 13
        case .preparedFoods: return 14
        case .meats: return 15
        case .saltySnacks: return 16
        }
    }
}

@Model
final class FoodItem {
    var id: UUID = UUID()
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
    
    init(id: UUID = UUID(), timestamp: Date, brandName: String, name: String, processingLevel: String, servingSize: Double, servingUnit: String, calories: Int, fat: Double, saturatedFat: Double, transFat: Double, protein: Double, carb: Double, dietaryFiber: Double, addedSugar: Double, category: FoodCategory = .preparedFoods) {
        self.id = id
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

extension FoodItem {
    @MainActor
    static var previewData: [FoodItem] { [
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Promix",
            name: "Whey",
            processingLevel: "Processed",
            servingSize: 31.2,
            servingUnit: "grams",
            calories: 125,
            fat: 1.5,
            saturatedFat: 0.5,
            transFat: 0.0,
            protein: 25.0,
            carb: 3.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .supplements
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "PB Fit",
            name: "Peanut Powder",
            processingLevel: "Processed",
            servingSize: 16.0,
            servingUnit: "grams",
            calories: 70,
            fat: 2.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 8.0,
            carb: 5.0,
            dietaryFiber: 3.0,
            addedSugar: 2.0,
            category: .supplements
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Promix",
            name: "Casein",
            processingLevel: "Processed",
            servingSize: 29.0,
            servingUnit: "grams",
            calories: 105,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 25.0,
            carb: 0.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .supplements
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Collagen",
            processingLevel: "Processed",
            servingSize: 20.0,
            servingUnit: "grams",
            calories: 80,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 20.0,
            carb: 0.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .supplements
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "StarKist",
            name: "Tuna Packet",
            processingLevel: "Processed",
            servingSize: 1.0,
            servingUnit: "pack",
            calories: 80,
            fat: 0.5,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 17.0,
            carb: 1.0,
            dietaryFiber: 0.0,
            addedSugar: 1.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Lucern",
            name: "Milk",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 130,
            fat: 5.0,
            saturatedFat: 3.0,
            transFat: 0.0,
            protein: 9.0,
            carb: 13.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Lucern",
            name: "Milk",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 80,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 8.0,
            carb: 12.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Lucern",
            name: "Half and Half",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 40,
            fat: 3.0,
            saturatedFat: 2.0,
            transFat: 0.0,
            protein: 1.0,
            carb: 1.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Kirkland",
            name: "Goat Cheese",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 80,
            fat: 6.0,
            saturatedFat: 4.0,
            transFat: 0.0,
            protein: 5.0,
            carb: 1.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "First Street",
            name: "Parmesan",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 110,
            fat: 8.0,
            saturatedFat: 4.5,
            transFat: 0.0,
            protein: 8.0,
            carb: 2.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Lucern",
            name: "Sour Cream",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 60,
            fat: 5.0,
            saturatedFat: 3.5,
            transFat: 0.0,
            protein: 1.0,
            carb: 2.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Lucern",
            name: "Heavy cream",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 50,
            fat: 5.0,
            saturatedFat: 3.5,
            transFat: 0.0,
            protein: 0.0,
            carb: 1.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Knudsen",
            name: "Cottage Cheese",
            processingLevel: "Whole",
            servingSize: 119.0,
            servingUnit: "g",
            calories: 90,
            fat: 2.5,
            saturatedFat: 1.5,
            transFat: 0.0,
            protein: 11.0,
            carb: 6.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Kirkland",
            name: "Greek Yogurt 0%",
            processingLevel: "Whole",
            servingSize: 170.0,
            servingUnit: "grams",
            calories: 100,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 18.0,
            carb: 7.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Butter",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 119,
            fat: 12.0,
            saturatedFat: 8.0,
            transFat: 0.0,
            protein: 0.0,
            carb: 0.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .dairy
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Egg Whites",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 25,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 5.0,
            carb: 1.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .eggs
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Egg",
            processingLevel: "Whole",
            servingSize: 1.0,
            servingUnit: "egg",
            calories: 70,
            fat: 5.0,
            saturatedFat: 1.5,
            transFat: 0.0,
            protein: 6.0,
            carb: 0.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .eggs
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Oatmeal",
            processingLevel: "Whole",
            servingSize: 40.0,
            servingUnit: "g",
            calories: 150,
            fat: 2.5,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 5.0,
            carb: 27.0,
            dietaryFiber: 4.0,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Jif",
            name: "Peanut Butter",
            processingLevel: "Almost Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 190,
            fat: 16.0,
            saturatedFat: 3.5,
            transFat: 0.0,
            protein: 7.0,
            carb: 8.0,
            dietaryFiber: 2.0,
            addedSugar: 2.0,
            category: .nutsAndSeeds
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Almonds",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 170,
            fat: 15.0,
            saturatedFat: 1.0,
            transFat: 0.0,
            protein: 6.0,
            carb: 6.0,
            dietaryFiber: 4.0,
            addedSugar: 1.0,
            category: .nutsAndSeeds
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Hazelnuts",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 190,
            fat: 18.0,
            saturatedFat: 1.5,
            transFat: 0.0,
            protein: 5.0,
            carb: 5.0,
            dietaryFiber: 3.0,
            addedSugar: 9.0,
            category: .nutsAndSeeds
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Walnuts",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 200,
            fat: 19.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 5.0,
            carb: 4.0,
            dietaryFiber: 2.0,
            addedSugar: 0.0,
            category: .nutsAndSeeds
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Spinach",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 20,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 2.0,
            carb: 3.0,
            dietaryFiber: 2.0,
            addedSugar: 0.0,
            category: .vegetables
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Mini potatoes",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 80,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 2.0,
            carb: 15.0,
            dietaryFiber: 2.0,
            addedSugar: 0.0,
            category: .vegetables
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Banana",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 105,
            fat: 0.5,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 1.5,
            carb: 27.0,
            dietaryFiber: 3.1,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Cherries",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 90,
            fat: 0.5,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 1.5,
            carb: 22.0,
            dietaryFiber: 3.0,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Blueberries",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 85,
            fat: 0.5,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 1.0,
            carb: 21.0,
            dietaryFiber: 3.5,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Pineapple",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 82,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 0.5,
            carb: 13.5,
            dietaryFiber: 1.5,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Strawberries",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 50,
            fat: 0.5,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 1.0,
            carb: 12.0,
            dietaryFiber: 3.0,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "CocaCola",
            name: "CocaCola",
            processingLevel: "Engineered",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 140,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 0.0,
            carb: 39.0,
            dietaryFiber: 0.0,
            addedSugar: 39.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Brown Sugar",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 4,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 0.0,
            carb: 1.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Honey",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 60,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 0.0,
            carb: 16.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Maple Syrup",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 110,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 0.0,
            carb: 27.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Nutella",
            processingLevel: "Processed",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 200,
            fat: 11.0,
            saturatedFat: 4.0,
            transFat: 0.0,
            protein: 2.0,
            carb: 22.0,
            dietaryFiber: 1.0,
            addedSugar: 21.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Olive Oil",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 119,
            fat: 14.0,
            saturatedFat: 2.0,
            transFat: 0.0,
            protein: 0.0,
            carb: 0.0,
            dietaryFiber: 0.0,
            addedSugar: 0.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "",
            name: "Basalmic Vinegar",
            processingLevel: "Whole",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 45,
            fat: 0.0,
            saturatedFat: 0.0,
            transFat: 0.0,
            protein: 0.0,
            carb: 10.0,
            dietaryFiber: 0.0,
            addedSugar: 6.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Costco Food Court",
            name: "Chicken Bake",
            processingLevel: "Engineered",
            servingSize: 1.0,
            servingUnit: "bake",
            calories: 840,
            fat: 32.0,
            saturatedFat: 11.0,
            transFat: 0.5,
            protein: 52.0,
            carb: 83.0,
            dietaryFiber: 3.0,
            addedSugar: 1.0,
            category: .preparedFoods
        ),
        FoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: "Newmans Own",
            name: "Italian Salami Pizza",
            processingLevel: "Engineered",
            servingSize: 0.0,
            servingUnit: "g",
            calories: 980,
            fat: 40.0,
            saturatedFat: 21.0,
            transFat: 0.5,
            protein: 53.0,
            carb: 102.0,
            dietaryFiber: 5.0,
            addedSugar: 0.0,
            category: .preparedFoods
        )
    ] }
}
