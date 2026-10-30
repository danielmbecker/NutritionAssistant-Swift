import Foundation
import TabularData

/// Reads the optional household-measurement columns from a food CSV row (never traps on missing columns).
enum FoodCSVHouseholdParser {
    static let nameColumn = "Common Household Measurement"
    static let amountColumn = "Common Household Measurement Amount"

    /// Returns both values only for a complete valid pair (non-empty name, amount > 0); otherwise `(nil, nil)`.
    static func parse(row: SafeCSVRow) -> (name: String?, amount: Double?) {
        guard row.hasColumn(nameColumn), row.hasColumn(amountColumn) else { return (nil, nil) }

        let trimmed = row.string(nameColumn)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (trimmed?.isEmpty == true) ? nil : trimmed
        let amount = row.double(amountColumn)

        guard FoodItem.isValidHouseholdPair(name: name, amount: amount),
              let name, let amount else { return (nil, nil) }
        return (name, amount)
    }

    static func parse(row: DataFrame.Row, in dataFrame: DataFrame) -> (name: String?, amount: Double?) {
        parse(row: SafeCSVRow(row: row, dataFrame: dataFrame))
    }
}
