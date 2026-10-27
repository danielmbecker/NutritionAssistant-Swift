import SwiftUI

struct CalorieAndMacroSectionView: View {
    @Binding var calorieInput: Int?
    @Binding var fatInput: Int?
    @Binding var carbInput: Int?
    @Binding var proteinInput: Int?
    
    @Binding var fatLock: MacroLock
    @Binding var carbLock: MacroLock
    @Binding var proteinLock: MacroLock
    
    @Binding var caloricContextType: CaloricContextType
    @Binding var customCaloricBase: Int
    @Binding var weightIntention: WeightIntention?
    @Binding var weightIntentionUnit: WeightIntentionUnit
    @Binding var weightIntentionValue: Double
    
    let onSaveCalories: () -> Void
    let onSaveMacros: () -> Void
    let onLockChanged: () -> Void
    let onGoalSettingsChanged: () -> Void
    
    @State private var fatPercentInput: Int?
    @State private var carbPercentInput: Int?
    @State private var proteinPercentInput: Int?
    
    @State private var showLockLimitAlert = false
    @State private var showCustomRadial = false
    @State private var showIntentionRadial = false
    
    var healthKitManager = HealthKitManager.shared
    
    // MARK: - Computed Math
    
    private var calculatedMacroCalories: Int {
        let fat = Double(fatInput ?? 0) * 9.0
        let carbs = Double(carbInput ?? 0) * 4.0
        let protein = Double(proteinInput ?? 0) * 4.0
        return Int(round(fat + carbs + protein))
    }
    
    private var totalPercentage: Int {
        return (fatPercentInput ?? 0) + (carbPercentInput ?? 0) + (proteinPercentInput ?? 0)
    }
    
    private var isMacroTotalValid: Bool {
        let calorieDifference = abs(calculatedMacroCalories - (calorieInput ?? 0))
        let percentageDifference = abs(totalPercentage - 100)
        return percentageDifference <= 1 || calorieDifference <= 15
    }
    
    private var areAllMacrosLocked: Bool {
        return fatLock != .none && carbLock != .none && proteinLock != .none
    }
    
    // MARK: - Custom Bindings
    
    private var fatGramBinding: Binding<Int?> {
        Binding(
            get: { fatInput },
            set: { newValue in
                fatInput = newValue
                if let newGrams = newValue, let cals = calorieInput, cals > 0 {
                    fatPercentInput = Int(round(Double(newGrams * 9) / Double(cals) * 100.0))
                } else {
                    fatPercentInput = nil
                }
            }
        )
    }
    
    private var fatPercentBinding: Binding<Int?> {
        Binding(
            get: { fatPercentInput },
            set: { newValue in
                fatPercentInput = newValue
                if let newPercent = newValue, let cals = calorieInput {
                    fatInput = Int(round((Double(newPercent) / 100.0 * Double(cals)) / 9.0))
                } else {
                    fatInput = nil
                }
            }
        )
    }
    
    private var carbGramBinding: Binding<Int?> {
        Binding(
            get: { carbInput },
            set: { newValue in
                carbInput = newValue
                if let newGrams = newValue, let cals = calorieInput, cals > 0 {
                    carbPercentInput = Int(round(Double(newGrams * 4) / Double(cals) * 100.0))
                } else {
                    carbPercentInput = nil
                }
            }
        )
    }
    
    private var carbPercentBinding: Binding<Int?> {
        Binding(
            get: { carbPercentInput },
            set: { newValue in
                carbPercentInput = newValue
                if let newPercent = newValue, let cals = calorieInput {
                    carbInput = Int(round((Double(newPercent) / 100.0 * Double(cals)) / 4.0))
                } else {
                    carbInput = nil
                }
            }
        )
    }
    
    private var proteinGramBinding: Binding<Int?> {
        Binding(
            get: { proteinInput },
            set: { newValue in
                proteinInput = newValue
                if let newGrams = newValue, let cals = calorieInput, cals > 0 {
                    proteinPercentInput = Int(round(Double(newGrams * 4) / Double(cals) * 100.0))
                } else {
                    proteinPercentInput = nil
                }
            }
        )
    }
    
    private var proteinPercentBinding: Binding<Int?> {
        Binding(
            get: { proteinPercentInput },
            set: { newValue in
                proteinPercentInput = newValue
                if let newPercent = newValue, let cals = calorieInput {
                    proteinInput = Int(round((Double(newPercent) / 100.0 * Double(cals)) / 4.0))
                } else {
                    proteinInput = nil
                }
            }
        )
    }
    
    // MARK: - Goal Math
    
    private var computedGoalEffectNumber: Double {
        if weightIntention == .maintain || weightIntention == nil { return 0 }
        return weightIntentionUnit == .pounds ? (weightIntentionValue * 3500.0) : weightIntentionValue
    }
    
    private func computeDailyTarget() {
        var base: Double = 0
        switch caloricContextType {
        case .bmr: base = healthKitManager.latestBMR
        case .tdeeYesterday: base = healthKitManager.tdeeYesterday
        case .tdeeLastWeek: base = healthKitManager.tdeeLastWeekAverage
        case .tdeeLastMonth: base = healthKitManager.tdeeLastMonthAverage
        case .tdeeLast90Days: base = healthKitManager.tdeeLast90DaysAverage
        case .custom: base = Double(customCaloricBase)
        }
        
        let dailyDelta = computedGoalEffectNumber / 7.0
        var delta: Double = 0
        if weightIntention == .lose { delta = -dailyDelta }
        else if weightIntention == .gain { delta = dailyDelta }
        
        let newGoal = Int(round(base + delta))
        if calorieInput != newGoal {
            calorieInput = newGoal
            handleCalorieChange(newCalories: newGoal)
            onSaveCalories()
        }
    }
    
    // MARK: - View Body
    
    @ViewBuilder
    var body: some View {
        // 1. Caloric Target Overhaul
        VStack(spacing: 20) {
            
            // Context Selector
            VStack(spacing: 8) {
                HStack {
                    contextBox(title: "BMR", value: healthKitManager.latestBMR, type: .bmr)
                    contextBox(title: "TDEE Yesterday", value: healthKitManager.tdeeYesterday, type: .tdeeYesterday)
                    contextBox(title: "TDEE Last Week", value: healthKitManager.tdeeLastWeekAverage, type: .tdeeLastWeek)
                }
                HStack {
                    contextBox(title: "TDEE Last Month", value: healthKitManager.tdeeLastMonthAverage, type: .tdeeLastMonth)
                    contextBox(title: "TDEE Last 90 days", value: healthKitManager.tdeeLast90DaysAverage, type: .tdeeLast90Days)
                    contextBox(title: "Custom", value: Double(customCaloricBase), type: .custom)
                }
            }
            
            // Weight Intention Section
            VStack(spacing: 12) {
                let intentionProxy = Binding<WeightIntention>(
                    get: { weightIntention ?? .maintain },
                    set: { newValue in
                        weightIntention = newValue
                        if newValue == .maintain {
                            weightIntentionValue = 0
                        }
                        onGoalSettingsChanged()
                        computeDailyTarget()
                    }
                )
                
                Picker("Intention", selection: intentionProxy) {
                    Text("Lose").tag(WeightIntention.lose)
                    Text("Maintain").tag(WeightIntention.maintain)
                    Text("Gain").tag(WeightIntention.gain)
                }
                .pickerStyle(.segmented)
                
                if intentionProxy.wrappedValue != .maintain {
                    HStack(spacing: 12) {
                        Button(action: {
                            if weightIntentionUnit != .calories {
                                weightIntentionUnit = .calories
                                if weightIntentionValue > 0 {
                                    weightIntentionValue = weightIntentionValue * 3500.0
                                }
                                onGoalSettingsChanged()
                                computeDailyTarget()
                            }
                        }) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(weightIntentionUnit == .calories ? .accentColor : .gray)
                                .padding(4)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if weightIntentionUnit != .pounds {
                                weightIntentionUnit = .pounds
                                if weightIntentionValue > 0 {
                                    weightIntentionValue = max(0.1, round((weightIntentionValue / 3500.0) * 10) / 10)
                                }
                                onGoalSettingsChanged()
                                computeDailyTarget()
                            }
                        }) {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(weightIntentionUnit == .pounds ? .accentColor : .gray)
                                .padding(4)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        
                        if(weightIntentionUnit == .calories){
                            Text("\(computedGoalEffectNumber, specifier: "%.0f") Calories/wk")
                                .font(.subheadline)
                        }else if(weightIntentionUnit == .pounds){
                            Text("\(computedGoalEffectNumber / 3500, specifier: "%.1f") Pounds/wk")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Button("Set Goal") {
                            showIntentionRadial = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            // Computed Target
            HStack {
                Text("Daily Calorie Target: ")
                    .font(.headline)
                Spacer()
                Text("\(calorieInput ?? 0)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding(.vertical, 8)
        .onAppear { computeDailyTarget() }
        .onChange(of: healthKitManager.latestBMR) { computeDailyTarget() }
        .onChange(of: healthKitManager.tdeeYesterday) { computeDailyTarget() }
        .onChange(of: healthKitManager.tdeeLastWeekAverage) { computeDailyTarget() }
        .onChange(of: healthKitManager.tdeeLastMonthAverage) { computeDailyTarget() }
        .onChange(of: healthKitManager.tdeeLast90DaysAverage) { computeDailyTarget() }
        .sheet(isPresented: $showCustomRadial) {
            RadialHalfSheetSelector(
                title: "Custom Base",
                subtitle: "Set a custom daily base",
                unit: "kcal",
                value: Binding(get: { Double(customCaloricBase) }, set: { customCaloricBase = Int($0) }),
                baseValue: 2000,
                onDismiss: { showCustomRadial = false },
                onSave: {
                    showCustomRadial = false
                    onGoalSettingsChanged()
                    computeDailyTarget()
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showIntentionRadial) {
            RadialHalfSheetSelector(
                title: "Set Goal",
                subtitle: weightIntentionUnit == .calories ? "Calories per week" : "Pounds per week",
                unit: weightIntentionUnit == .calories ? "kcal" : "lbs",
                value: $weightIntentionValue,
                baseValue: weightIntentionUnit == .calories ? 500 : 0,
                onDismiss: { showIntentionRadial = false },
                onSave: {
                    showIntentionRadial = false
                    onGoalSettingsChanged()
                    computeDailyTarget()
                }
            )
            .presentationDetents([.medium])
        }
        
        
        
        // 2. Macros
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Macronutrients")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if !isMacroTotalValid {
                    Button(action: autoBalanceMacros) {
                        Text("Auto-balance")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(areAllMacrosLocked ? Color.gray.opacity(0.1) : Color.accentColor.opacity(0.1))
                            .foregroundColor(areAllMacrosLocked ? .gray : .accentColor)
                            .cornerRadius(6)
                    }
                    .disabled(areAllMacrosLocked)
                    .animation(.easeInOut(duration: 0.2), value: isMacroTotalValid)
                }
            }
            
            macroRow(title: "Fat", lockState: fatLock, percentBinding: fatPercentBinding, gramBinding: fatGramBinding,
                     onTogglePercent: { handleLockToggle(for: .fat, newMode: fatLock == .percent ? .none : .percent) },
                     onToggleGrams: { handleLockToggle(for: .fat, newMode: fatLock == .grams ? .none : .grams) })
            
            macroRow(title: "Carbs", lockState: carbLock, percentBinding: carbPercentBinding, gramBinding: carbGramBinding,
                     onTogglePercent: { handleLockToggle(for: .carb, newMode: carbLock == .percent ? .none : .percent) },
                     onToggleGrams: { handleLockToggle(for: .carb, newMode: carbLock == .grams ? .none : .grams) })
            
            macroRow(title: "Protein", lockState: proteinLock, percentBinding: proteinPercentBinding, gramBinding: proteinGramBinding,
                     onTogglePercent: { handleLockToggle(for: .protein, newMode: proteinLock == .percent ? .none : .percent) },
                     onToggleGrams: { handleLockToggle(for: .protein, newMode: proteinLock == .grams ? .none : .grams) })
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Calculated Total:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(calculatedMacroCalories) kcal (\(totalPercentage)%)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isMacroTotalValid ? .primary : .red)
                    
                    if !isMacroTotalValid {
                        Text("Must equal 100% or match Calorie Goal")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                Spacer()
                AnimatedSaveButton(action: onSaveMacros)
                    .disabled(!isMacroTotalValid)
            }
        }
        .padding(.vertical, 4)
        .onAppear { updatePercentsFromGrams(calories: calorieInput) }
        .alert("Lock Limit Reached", isPresented: $showLockLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Only 2 macros can be locked at once. Please unlock one before locking another to ensure auto-balancing can function properly.")
        }
    }
    
    // MARK: - Lock Safety Logic
    
    enum MacroType { case fat, carb, protein }
    
    private func handleLockToggle(for macro: MacroType, newMode: MacroLock) {
        if newMode != .none {
            switch macro {
            case .fat:
                if carbLock != .none && proteinLock != .none {
                    showLockLimitAlert = true
                    return
                }
                fatLock = newMode
            case .carb:
                if fatLock != .none && proteinLock != .none {
                    showLockLimitAlert = true
                    return
                }
                carbLock = newMode
            case .protein:
                if fatLock != .none && carbLock != .none {
                    showLockLimitAlert = true
                    return
                }
                proteinLock = newMode
            }
        } else {
            switch macro {
            case .fat: fatLock = .none
            case .carb: carbLock = .none
            case .protein: proteinLock = .none
            }
        }
        onLockChanged()
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func macroRow(title: String, lockState: MacroLock, percentBinding: Binding<Int?>, gramBinding: Binding<Int?>, onTogglePercent: @escaping () -> Void, onToggleGrams: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.headline)
            Spacer()
            Button(action: onTogglePercent) {
                Image(systemName: lockState == .percent ? "lock.fill" : "lock.open")
                    .foregroundColor(lockState == .percent ? .accentColor : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            SuffixTextField(value: percentBinding, suffix: "%")
            SuffixTextField(value: gramBinding, suffix: "g")
            Button(action: onToggleGrams) {
                Image(systemName: lockState == .grams ? "lock.fill" : "lock.open")
                    .foregroundColor(lockState == .grams ? .accentColor : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func contextBox(title: String, value: Double, type: CaloricContextType) -> some View {
        Button(action: {
            caloricContextType = type
            onGoalSettingsChanged()
            computeDailyTarget()
            
            if type == .custom {
                showCustomRadial = true
            }
        }) {
            VStack(spacing: 4) {
                Text(type == .custom ? "\(Int(value))" : String(format: "%.0f", value))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(caloricContextType == type ? .white : .primary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(caloricContextType == type ? .white : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(caloricContextType == type ? Color.accentColor : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Smart Algorithms
    
    private func autoBalanceMacros() {
        guard let targetCals = calorieInput, targetCals > 0 else { return }
        let currentFatCals = Double(fatInput ?? 0) * 9.0
        let currentCarbCals = Double(carbInput ?? 0) * 4.0
        let currentProCals = Double(proteinInput ?? 0) * 4.0
        
        var fixedCals: Double = 0
        var unlockedCurrentTotal: Double = 0
        var unlockedCount: Double = 0
        
        if fatLock != .none { fixedCals += currentFatCals } else { unlockedCurrentTotal += currentFatCals; unlockedCount += 1 }
        if carbLock != .none { fixedCals += currentCarbCals } else { unlockedCurrentTotal += currentCarbCals; unlockedCount += 1 }
        if proteinLock != .none { fixedCals += currentProCals } else { unlockedCurrentTotal += currentProCals; unlockedCount += 1 }
        
        guard unlockedCount > 0 else { return }
        let leftoverCals = max(0, Double(targetCals) - fixedCals)
        
        if fatLock == .none {
            let allocated = unlockedCurrentTotal > 0 ? leftoverCals * (currentFatCals / unlockedCurrentTotal) : leftoverCals / unlockedCount
            fatInput = Int(round(allocated / 9.0))
            fatPercentInput = Int(round(allocated / Double(targetCals) * 100.0))
        }
        if carbLock == .none {
            let allocated = unlockedCurrentTotal > 0 ? leftoverCals * (currentCarbCals / unlockedCurrentTotal) : leftoverCals / unlockedCount
            carbInput = Int(round(allocated / 4.0))
            carbPercentInput = Int(round(allocated / Double(targetCals) * 100.0))
        }
        if proteinLock == .none {
            let allocated = unlockedCurrentTotal > 0 ? leftoverCals * (currentProCals / unlockedCurrentTotal) : leftoverCals / unlockedCount
            proteinInput = Int(round(allocated / 4.0))
            proteinPercentInput = Int(round(allocated / Double(targetCals) * 100.0))
        }
    }
    
    private func handleCalorieChange(newCalories: Int?) {
        guard let newCals = newCalories, newCals > 0 else { return }
        let oldFatCals = Double(fatInput ?? 0) * 9.0
        let oldCarbCals = Double(carbInput ?? 0) * 4.0
        let oldProCals = Double(proteinInput ?? 0) * 4.0

        var fixedCals: Double = 0
        var noneOldCalsTotal: Double = 0
        var newFatCals: Double?
        var newCarbCals: Double?
        var newProCals: Double?

        if fatLock == .grams { newFatCals = oldFatCals; fixedCals += oldFatCals }
        else if fatLock == .percent { let c = (Double(fatPercentInput ?? 0) / 100.0) * Double(newCals); newFatCals = c; fixedCals += c }
        else { noneOldCalsTotal += oldFatCals }

        if carbLock == .grams { newCarbCals = oldCarbCals; fixedCals += oldCarbCals }
        else if carbLock == .percent { let c = (Double(carbPercentInput ?? 0) / 100.0) * Double(newCals); newCarbCals = c; fixedCals += c }
        else { noneOldCalsTotal += oldCarbCals }

        if proteinLock == .grams { newProCals = oldProCals; fixedCals += oldProCals }
        else if proteinLock == .percent { let c = (Double(proteinPercentInput ?? 0) / 100.0) * Double(newCals); newProCals = c; fixedCals += c }
        else { noneOldCalsTotal += oldProCals }

        let leftoverCals = max(0, Double(newCals) - fixedCals)
        if fatLock == .none { newFatCals = noneOldCalsTotal > 0 ? leftoverCals * (oldFatCals / noneOldCalsTotal) : leftoverCals / 3.0 }
        if carbLock == .none { newCarbCals = noneOldCalsTotal > 0 ? leftoverCals * (oldCarbCals / noneOldCalsTotal) : leftoverCals / 3.0 }
        if proteinLock == .none { newProCals = noneOldCalsTotal > 0 ? leftoverCals * (oldProCals / noneOldCalsTotal) : leftoverCals / 3.0 }

        if let fc = newFatCals { fatInput = Int(round(fc / 9.0)); fatPercentInput = Int(round(fc / Double(newCals) * 100.0)) }
        if let cc = newCarbCals { carbInput = Int(round(cc / 4.0)); carbPercentInput = Int(round(cc / Double(newCals) * 100.0)) }
        if let pc = newProCals { proteinInput = Int(round(pc / 4.0)); proteinPercentInput = Int(round(pc / Double(newCals) * 100.0)) }
    }
    
    private func updatePercentsFromGrams(calories: Int?) {
        guard let cals = calories, cals > 0 else { return }
        if let f = fatInput { fatPercentInput = Int(round(Double(f * 9) / Double(cals) * 100.0)) }
        if let c = carbInput { carbPercentInput = Int(round(Double(c * 4) / Double(cals) * 100.0)) }
        if let p = proteinInput { proteinPercentInput = Int(round(Double(p * 4) / Double(cals) * 100.0)) }
    }
}
