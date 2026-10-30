import Foundation
import TabularData

/// A `DataFrame.Row` wrapper whose accessors never trap.
/// `DataFrame.Row` subscripting by column name is a fatal error when the column does not exist,
/// so all reads go through `columns.contains` first and return `nil` for absent columns.
struct SafeCSVRow {
    let row: DataFrame.Row
    let columns: Set<String>

    init(row: DataFrame.Row, dataFrame: DataFrame) {
        self.row = row
        self.columns = Set(dataFrame.columns.map { $0.name })
    }

    /// Use when the column set was already computed for the whole frame (avoids rebuilding it per row).
    init(row: DataFrame.Row, columns: Set<String>) {
        self.row = row
        self.columns = columns
    }

    func hasColumn(_ name: String) -> Bool { columns.contains(name) }

    func value(_ name: String) -> Any? {
        guard columns.contains(name) else { return nil }
        return row[name]
    }

    func string(_ name: String) -> String? {
        value(name) as? String
    }

    func double(_ name: String) -> Double? {
        switch value(name) {
        case let d as Double: return d
        case let i as Int: return Double(i)
        case let s as String: return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        default: return nil
        }
    }

    func int(_ name: String) -> Int? {
        switch value(name) {
        case let i as Int: return i
        case let d as Double: return Int(d)
        case let s as String: return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        default: return nil
        }
    }

    func date(_ name: String) -> Date? {
        value(name) as? Date
    }
}

/// Converts a food CSV `DataFrame` into (uninserted) `FoodItem`s. Missing columns fall back to defaults.
enum FoodCSVImporter {
    /// Columns the exporter writes. Absent ones are reported (for logging) and defaulted, never fatal.
    static let expectedColumns = [
        "Timestamp", "Brand", "Name", "Processing Level", "Serving Size", "Serving Unit", "Calories",
        "Fat", "Saturated Fat", "Trans Fat", "Protein", "Carbs", "Dietary Fiber", "Added Sugar", "Category",
        FoodCSVHouseholdParser.nameColumn, FoodCSVHouseholdParser.amountColumn
    ]

    struct Result {
        var items: [FoodItem]
        /// Expected columns that were absent from the file (defaults were used).
        var missingColumns: [String]
        /// Rows skipped because they had no name.
        var skippedRows: Int
    }

    static func parse(_ dataFrame: DataFrame) -> Result {
        let columns = Set(dataFrame.columns.map { $0.name })
        let missing = expectedColumns.filter { !columns.contains($0) }

        var items: [FoodItem] = []
        var skipped = 0

        for dataRow in dataFrame.rows {
            let row = SafeCSVRow(row: dataRow, columns: columns)

            guard let name = row.string("Name"), !name.isEmpty else {
                skipped += 1
                continue
            }

            let household = FoodCSVHouseholdParser.parse(row: row)

            items.append(FoodItem(
                timestamp: row.date("Timestamp") ?? Date(),
                brandName: row.string("Brand") ?? "",
                name: name,
                processingLevel: row.string("Processing Level") ?? "",
                servingSize: row.double("Serving Size") ?? 0.0,
                servingUnit: row.string("Serving Unit") ?? "",
                calories: row.int("Calories") ?? 0,
                fat: row.double("Fat") ?? 0.0,
                saturatedFat: row.double("Saturated Fat") ?? 0.0,
                transFat: row.double("Trans Fat") ?? 0.0,
                protein: row.double("Protein") ?? 0.0,
                carb: row.double("Carbs") ?? 0.0,
                dietaryFiber: row.double("Dietary Fiber") ?? 0.0,
                addedSugar: row.double("Added Sugar") ?? 0.0,
                category: row.string("Category") ?? FoodCategoryList.importedCategory,
                commonHouseholdMeasurement: household.name,
                commonHouseholdMeasurementAmount: household.amount
            ))
        }
        return Result(items: items, missingColumns: missing, skippedRows: skipped)
    }
}
