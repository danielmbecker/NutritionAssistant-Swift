import Foundation
import SwiftData

enum CaloricContextType: String, Codable, CaseIterable {
    case bmr = "BMR"
    case tdeeYesterday = "TDEE Yesterday"
    case tdeeLastWeek = "TDEE Last Week"
    case tdeeLastMonth = "TDEE Last Month"
    case tdeeLast90Days = "TDEE Last 90 days"
    case custom = "Custom"
}

enum WeightIntention: String, Codable {
    case lose = "Lose"
    case maintain = "Maintain"
    case gain = "Gain"
}

enum WeightIntentionUnit: String, Codable {
    case calories = "Calories"
    case pounds = "Pounds"
}

enum MacroLock: String, Codable {
    case none = "none"
    case percent = "percent"
    case grams = "grams"
}

enum GoalType: String, Codable {
    case goal = "Goal"
    case limit = "Limit"
}

@Model
final class UserSettings {
    var id: UUID = UUID()
    var userCaloriesGoal: Int
    var userCaloriesGoalType: GoalType
    
    var userFatGoal: Int
    var userFatGoalType: GoalType
    
    var userSaturatedFatGoal: Int
    var userSaturatedFatGoalType: GoalType
    
    var userTransFatGoal: Int
    var userTransFatGoalType: GoalType
    
    var userProteinGoal: Int
    var userProteinGoalType: GoalType
    
    var userCarbGoal: Int
    var userCarbGoalType: GoalType
    
    var userDietaryFiberGoal: Int
    var userDietaryFiberGoalType: GoalType
    
    var userAddedSugarGoal: Int
    var userAddedSugarGoalType: GoalType
    
    var dayStartHour: Int
    
    // NEW: Optional toggle for custom HealthKit window
    var healthKitCustomDayWindow: Bool
    
    // NEW: Macro Lock states
    var fatLock: MacroLock
    var carbLock: MacroLock
    var proteinLock: MacroLock
    
    // NEW: Caloric Goal Context and Effect
    var caloricContextType: CaloricContextType
    var customCaloricBase: Int
    
    var weightIntention: WeightIntention?
    var weightIntentionUnit: WeightIntentionUnit
    var weightIntentionValue: Double
    
    var userSelectedPrimaryColorHex: String
    
    // Initializer with beautifully balanced mathematical defaults!
    init(
        userCaloriesGoal: Int = 2000,
        userCaloriesGoalType: GoalType = .goal,
        
        userFatGoal: Int = 80, // Updated to 80
        userFatGoalType: GoalType = .limit,
        
        userSaturatedFatGoal: Int = 20,
        userSaturatedFatGoalType: GoalType = .limit,
        
        userTransFatGoal: Int = 0,
        userTransFatGoalType: GoalType = .limit,
        
        userProteinGoal: Int = 110, // Updated to 110
        userProteinGoalType: GoalType = .goal,
        
        userCarbGoal: Int = 210, // Updated to 210
        userCarbGoalType: GoalType = .goal,
        
        userDietaryFiberGoal: Int = 28,
        userDietaryFiberGoalType: GoalType = .goal,
        
        userAddedSugarGoal: Int = 50,
        userAddedSugarGoalType: GoalType = .limit,
        
        dayStartHour: Int = 0,
        healthKitCustomDayWindow: Bool = false,
        
        fatLock: MacroLock = .none,
        carbLock: MacroLock = .none,
        proteinLock: MacroLock = .none,
        
        caloricContextType: CaloricContextType = .custom,
        customCaloricBase: Int = 2000,
        weightIntention: WeightIntention? = nil,
        weightIntentionUnit: WeightIntentionUnit = .calories,
        weightIntentionValue: Double = 0.0,
        
        userSelectedPrimaryColorHex: String = "#007AFF"
    ) {
        self.userCaloriesGoal = userCaloriesGoal
        self.userCaloriesGoalType = userCaloriesGoalType
        
        self.userFatGoal = userFatGoal
        self.userFatGoalType = userFatGoalType
        
        self.userSaturatedFatGoal = userSaturatedFatGoal
        self.userSaturatedFatGoalType = userSaturatedFatGoalType
        
        self.userTransFatGoal = userTransFatGoal
        self.userTransFatGoalType = userTransFatGoalType
        
        self.userProteinGoal = userProteinGoal
        self.userProteinGoalType = userProteinGoalType
        
        self.userCarbGoal = userCarbGoal
        self.userCarbGoalType = userCarbGoalType
        
        self.userDietaryFiberGoal = userDietaryFiberGoal
        self.userDietaryFiberGoalType = userDietaryFiberGoalType
        
        self.userAddedSugarGoal = userAddedSugarGoal
        self.userAddedSugarGoalType = userAddedSugarGoalType
        
        self.dayStartHour = dayStartHour
        self.healthKitCustomDayWindow = healthKitCustomDayWindow
        
        self.fatLock = fatLock
        self.carbLock = carbLock
        self.proteinLock = proteinLock
        
        self.caloricContextType = caloricContextType
        self.customCaloricBase = customCaloricBase
        self.weightIntention = weightIntention
        self.weightIntentionUnit = weightIntentionUnit
        self.weightIntentionValue = weightIntentionValue
        
        self.userSelectedPrimaryColorHex = userSelectedPrimaryColorHex
    }
}
