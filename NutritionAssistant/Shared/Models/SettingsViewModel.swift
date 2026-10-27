import SwiftUI
import SwiftData

@Observable
class SettingsViewModel {
    // Core State Variables
    var calorieInput: Int?
    var fatInput: Int?
    var carbInput: Int?
    var proteinInput: Int?
    
    // Macro Lock State Variables
    var fatLock: MacroLock = .none
    var carbLock: MacroLock = .none
    var proteinLock: MacroLock = .none
    
    // Caloric Goal State Variables
    var caloricContextType: CaloricContextType = .custom
    var customCaloricBase: Int = 2000
    var weightIntention: WeightIntention? = nil
    var weightIntentionUnit: WeightIntentionUnit = .calories
    var weightIntentionValue: Double = 0.0
    
    // Micronutrient State Variables
    var satFatInput: Int?
    var transFatInput: Int?
    var fiberInput: Int?
    var sugarInput: Int?
    
    // MARK: - Initialization Logic
    
    func initializeSettingsIfNeeded(settingsList: [UserSettings], context: ModelContext) {
        // Deduplicate: If there are multiple UserSettings due to a previous bug or lack of constraints,
        // delete all but the first one to prevent `@Query` array flip-flopping on changes.
        if settingsList.count > 1 {
            for i in 1..<settingsList.count {
                context.delete(settingsList[i])
            }
            try? context.save()
        }
        
        if settingsList.isEmpty {
            let defaultSettings = UserSettings()
            context.insert(defaultSettings)
            load(from: defaultSettings)
        } else if let currentSettings = settingsList.first {
            load(from: currentSettings)
        }
    }
    
    private func load(from settings: UserSettings) {
        calorieInput = settings.userCaloriesGoal
        fatInput = settings.userFatGoal
        carbInput = settings.userCarbGoal
        proteinInput = settings.userProteinGoal
        
        satFatInput = settings.userSaturatedFatGoal
        transFatInput = settings.userTransFatGoal
        fiberInput = settings.userDietaryFiberGoal
        sugarInput = settings.userAddedSugarGoal
        
        fatLock = settings.fatLock
        carbLock = settings.carbLock
        proteinLock = settings.proteinLock
        
        caloricContextType = settings.caloricContextType
        customCaloricBase = settings.customCaloricBase
        weightIntention = settings.weightIntention
        weightIntentionUnit = settings.weightIntentionUnit
        weightIntentionValue = settings.weightIntentionValue
    }
    
    // MARK: - Database Save Actions
    
    // The newly combined Calorie and Macro save function
    func saveCalorieAndMacros(settingsList: [UserSettings]) {
        if let rawGoal = calorieInput, let currentSettings = settingsList.first {
            let cappedGoal = min(max(rawGoal, 0), 10000)
            
            currentSettings.userCaloriesGoal = cappedGoal
            calorieInput = cappedGoal
            
            if let newFat = fatInput { currentSettings.userFatGoal = newFat }
            if let newCarbs = carbInput { currentSettings.userCarbGoal = newCarbs }
            if let newProtein = proteinInput { currentSettings.userProteinGoal = newProtein }
            
            hideKeyboard()
        }
    }
    
    func saveMacroGoal(settingsList: [UserSettings]) {
        if let currentSettings = settingsList.first {
            if let newFat = fatInput { currentSettings.userFatGoal = newFat }
            if let newCarbs = carbInput { currentSettings.userCarbGoal = newCarbs }
            if let newProtein = proteinInput { currentSettings.userProteinGoal = newProtein }
            hideKeyboard()
        }
    }
    
    func saveLocks(settingsList: [UserSettings]) {
        if let currentSettings = settingsList.first {
            currentSettings.fatLock = fatLock
            currentSettings.carbLock = carbLock
            currentSettings.proteinLock = proteinLock
            // SwiftData auto-saves on runloop end, but we can rely on modelContext if needed.
        }
    }
    
    func saveGoalSettings(settingsList: [UserSettings]) {
        if let currentSettings = settingsList.first {
            currentSettings.caloricContextType = caloricContextType
            currentSettings.customCaloricBase = customCaloricBase
            currentSettings.weightIntention = weightIntention
            currentSettings.weightIntentionUnit = weightIntentionUnit
            currentSettings.weightIntentionValue = weightIntentionValue
        }
    }
    
    func saveSatFatGoal(settingsList: [UserSettings]) {
        if let newGoal = satFatInput, let currentSettings = settingsList.first {
            currentSettings.userSaturatedFatGoal = newGoal
            hideKeyboard()
        }
    }
    
    func saveTransFatGoal(settingsList: [UserSettings]) {
        if let newGoal = transFatInput, let currentSettings = settingsList.first {
            currentSettings.userTransFatGoal = newGoal
            hideKeyboard()
        }
    }
    
    func saveFiberGoal(settingsList: [UserSettings]) {
        if let newGoal = fiberInput, let currentSettings = settingsList.first {
            currentSettings.userDietaryFiberGoal = newGoal
            hideKeyboard()
        }
    }
    
    func saveSugarGoal(settingsList: [UserSettings]) {
        if let newGoal = sugarInput, let currentSettings = settingsList.first {
            currentSettings.userAddedSugarGoal = newGoal
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
