import Foundation

/// A proposed proportional update of the household measure after the serving size was edited.
struct HouseholdMeasurementAdjustment: Identifiable {
    let id = UUID()
    let oldServingSize: Double
    let newServingSize: Double
    let servingUnit: String
    let measurement: String
    let oldAmount: Double
    let newAmount: Double
}

enum HouseholdMeasurementAdjuster {

    /// Returns a proposal only when it is meaningful:
    /// - the original food had a valid household pair and the user has not already edited it,
    /// - the serving unit is unchanged (a size ratio is only meaningful within one unit),
    /// - both sizes are > 0 and differ.
    /// The new amount scales proportionally (20 g → 40 g turns 1 scoop into 2), rounded to 2 decimals.
    static func adjustment(
        originalSize: Double,
        originalUnit: String,
        originalMeasurement: String?,
        originalAmount: Double?,
        currentSize: Double?,
        currentUnit: String,
        currentMeasurement: String?,
        currentAmount: Double?
    ) -> HouseholdMeasurementAdjustment? {
        guard FoodItem.isValidHouseholdPair(name: originalMeasurement, amount: originalAmount),
              let measurement = originalMeasurement, let oldAmount = originalAmount,
              let newSize = currentSize,
              originalUnit == currentUnit,
              currentMeasurement == originalMeasurement,
              currentAmount == originalAmount,
              originalSize > 0, newSize > 0,
              abs(newSize - originalSize) > 0.000_001
        else { return nil }

        let scaled = oldAmount * newSize / originalSize
        let newAmount = (scaled * 100).rounded() / 100
        guard newAmount > 0, newAmount != oldAmount else { return nil }

        return HouseholdMeasurementAdjustment(
            oldServingSize: originalSize,
            newServingSize: newSize,
            servingUnit: currentUnit,
            measurement: measurement,
            oldAmount: oldAmount,
            newAmount: newAmount
        )
    }
}
