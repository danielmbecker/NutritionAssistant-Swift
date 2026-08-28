import SwiftUI

struct CalorieAndMacroSectionView: View {
    @Binding var calorieInput: Int?
    @Binding var fatInput: Int?
    @Binding var carbInput: Int?
    @Binding var proteinInput: Int?
    
    @Binding var fatLock: MacroLock
    @Binding var carbLock: MacroLock
    @Binding var proteinLock: MacroLock
    
    let onSaveCalories: () -> Void
    let onSaveMacros: () -> Void
    let onLockChanged: () -> Void
    
    @State private var fatPercentInput: Int?
    @State private var carbPercentInput: Int?
    @State private var proteinPercentInput: Int?
    
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
    
    // MARK: - View Body
    
    @ViewBuilder
    var body: some View {
        // 1. Calories
        HStack(spacing: 12) {
            Text("Calories")
                .font(.headline)
            Spacer()
            // Standard binding directly attached here
            TextField("Goal", value: $calorieInput, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(width: 85)
            
            AnimatedSaveButton(action: {
                if let current = calorieInput {
                    calorieInput = min(max(current, 0), 10000)
                }
                handleCalorieChange(newCalories: calorieInput)
                onSaveCalories()
            })
            .disabled(areAllMacrosLocked)
        }
        .padding(.vertical, 4)
        
        
        
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
            
            macroRow(title: "Fat", lockState: $fatLock, percentBinding: fatPercentBinding, gramBinding: fatGramBinding)
            macroRow(title: "Carbs", lockState: $carbLock, percentBinding: carbPercentBinding, gramBinding: carbGramBinding)
            macroRow(title: "Protein", lockState: $proteinLock, percentBinding: proteinPercentBinding, gramBinding: proteinGramBinding)
            
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
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func macroRow(title: String, lockState: Binding<MacroLock>, percentBinding: Binding<Int?>, gramBinding: Binding<Int?>) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.headline)
            Spacer()
            Button(action: {
                lockState.wrappedValue = lockState.wrappedValue == .percent ? .none : .percent
                onLockChanged()
            }) {
                Image(systemName: lockState.wrappedValue == .percent ? "lock.fill" : "lock.open")
                    .foregroundColor(lockState.wrappedValue == .percent ? .accentColor : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            SuffixTextField(value: percentBinding, suffix: "%")
            SuffixTextField(value: gramBinding, suffix: "g")
            Button(action: {
                lockState.wrappedValue = lockState.wrappedValue == .grams ? .none : .grams
                onLockChanged()
            }) {
                Image(systemName: lockState.wrappedValue == .grams ? "lock.fill" : "lock.open")
                    .foregroundColor(lockState.wrappedValue == .grams ? .accentColor : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
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
