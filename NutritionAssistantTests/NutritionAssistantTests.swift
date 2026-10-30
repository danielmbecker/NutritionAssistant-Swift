//
//  NutritionAssistantTests.swift
//  NutritionAssistantTests
//
//  Created by Daniel Becker on 10/28/26.
//

import Testing
import Foundation
import TabularData
@testable import NutritionAssistant

@MainActor
struct MeasurementUnitFormatterTests {

    @Test func singularAtQuantityOne() {
        #expect(MeasurementUnitFormatter.display(name: "patty", quantity: 1) == "patty")
        #expect(MeasurementUnitFormatter.display(name: "cup", quantity: 1) == "cup")
    }

    @Test func irregularPlurals() {
        #expect(MeasurementUnitFormatter.display(name: "patty", quantity: 2) == "patties")
        #expect(MeasurementUnitFormatter.display(name: "gummy", quantity: 2) == "gummies")
    }

    @Test func regularPlurals() {
        #expect(MeasurementUnitFormatter.display(name: "cup", quantity: 1.5) == "cups")
        #expect(MeasurementUnitFormatter.display(name: "box", quantity: 2) == "boxes")
        #expect(MeasurementUnitFormatter.display(name: "pouch", quantity: 2) == "pouches")
        #expect(MeasurementUnitFormatter.display(name: "timed spray", quantity: 2) == "timed sprays")
        #expect(MeasurementUnitFormatter.display(name: "stick", quantity: 3) == "sticks")
    }

    @Test func invariantAbbreviations() {
        for name in ["mL", "g", "oz", "fl oz", "tbsp", "tsp"] {
            #expect(MeasurementUnitFormatter.display(name: name, quantity: 2) == name)
        }
    }
}

@MainActor
struct MeasurementUnitCatalogTests {

    @Test func builtInNamesAreUnique() {
        let ids = MeasurementUnitCatalog.builtIn.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyCategoryHasBuiltInUnits() {
        for group in MeasurementUnitCatalog.grouped() {
            #expect(!group.units.isEmpty, "\(group.category) has no units")
        }
    }

    @Test func categoryLookupIsCaseInsensitive() {
        #expect(MeasurementUnitCatalog.category(for: "SCOOP") == .discretePortion)
        #expect(MeasurementUnitCatalog.category(for: "mL") == .volumetric)
        #expect(MeasurementUnitCatalog.category(for: "g") == .weight)
        #expect(MeasurementUnitCatalog.category(for: "timed spray") == .specializedTime)
        #expect(MeasurementUnitCatalog.category(for: "unknownthing") == nil)
    }

    @Test func duplicateDetectionIncludesPluralForms() {
        #expect(MeasurementUnitCatalog.isDuplicate("cup"))
        #expect(MeasurementUnitCatalog.isDuplicate("cups"))
        #expect(MeasurementUnitCatalog.isDuplicate("patties"))
        #expect(!MeasurementUnitCatalog.isDuplicate("stick"))
    }

    @Test func userUnitsAreMergedButNeverShadowBuiltIns() {
        let stick = UserMeasurementUnit(name: "stick", category: .discretePortion)
        let fakeCup = UserMeasurementUnit(name: "cup", category: .weight)
        let units = [stick, fakeCup]
        #expect(MeasurementUnitCatalog.category(for: "stick", userUnits: units) == .discretePortion)
        #expect(MeasurementUnitCatalog.category(for: "cup", userUnits: units) == .volumetric)
        #expect(MeasurementUnitCatalog.isDuplicate("stick", userUnits: units))
    }
}

@MainActor
struct FoodItemHouseholdMeasurementTests {

    private func makeItem(name: String?, amount: Double?) -> FoodItem {
        FoodItem(
            timestamp: Date(), brandName: "", name: "Test", processingLevel: "Whole",
            servingSize: 1, servingUnit: "g", calories: 1, fat: 0, saturatedFat: 0, transFat: 0,
            protein: 0, carb: 0, dietaryFiber: 0, addedSugar: 0,
            commonHouseholdMeasurement: name, commonHouseholdMeasurementAmount: amount
        )
    }

    @Test func bothNilIsValid() {
        #expect(makeItem(name: nil, amount: nil).hasValidHouseholdMeasurement)
    }

    @Test func completePairIsValid() {
        #expect(makeItem(name: "scoop", amount: 1).hasValidHouseholdMeasurement)
    }

    @Test func partialOrInvalidPairsAreRejected() {
        #expect(!makeItem(name: "scoop", amount: nil).hasValidHouseholdMeasurement)
        #expect(!makeItem(name: nil, amount: 2).hasValidHouseholdMeasurement)
        #expect(!makeItem(name: "scoop", amount: 0).hasValidHouseholdMeasurement)
        #expect(!makeItem(name: "scoop", amount: -1).hasValidHouseholdMeasurement)
        #expect(!makeItem(name: "  ", amount: 1).hasValidHouseholdMeasurement)
    }

    @Test func staticPairRuleMatchesInstanceRule() {
        #expect(FoodItem.isValidHouseholdPair(name: nil, amount: nil))
        #expect(FoodItem.isValidHouseholdPair(name: "tbsp", amount: 2))
        #expect(!FoodItem.isValidHouseholdPair(name: "tbsp", amount: nil))
        #expect(!FoodItem.isValidHouseholdPair(name: nil, amount: 2))
        #expect(!FoodItem.isValidHouseholdPair(name: "tbsp", amount: 0))
    }

    @Test func existingInitCallsDefaultToNil() {
        let item = FoodItem(
            timestamp: Date(), brandName: "", name: "Test", processingLevel: "Whole",
            servingSize: 1, servingUnit: "g", calories: 1, fat: 0, saturatedFat: 0, transFat: 0,
            protein: 0, carb: 0, dietaryFiber: 0, addedSugar: 0
        )
        #expect(item.commonHouseholdMeasurement == nil)
        #expect(item.commonHouseholdMeasurementAmount == nil)
    }
}

@MainActor
struct FoodCSVHouseholdParserTests {

    private func frame(_ csv: String) throws -> DataFrame {
        try DataFrame(csvData: Data(csv.utf8), options: CSVReadingOptions(hasHeaderRow: true, delimiter: ","))
    }

    /// Regression: an older export (no household columns) crashed with
    /// "There is no column named 'Common Household Measurement' in the DataFrame."
    @Test func oldCSVWithoutHouseholdColumnsYieldsNil() throws {
        let df = try frame("Timestamp,Brand,Name,Serving Size,Serving Unit,Variation Group\n2026-08-10T08:00:41Z,Unbranded,Banana,118,g,\n")
        for row in df.rows {
            let result = FoodCSVHouseholdParser.parse(row: row, in: df)
            #expect(result.name == nil)
            #expect(result.amount == nil)
        }
    }

    @Test func completePairIsParsed() throws {
        let df = try frame("Name,Common Household Measurement,Common Household Measurement Amount\nWhey,scoop,1\nPB,tbsp,2.5\n")
        let results = df.rows.map { FoodCSVHouseholdParser.parse(row: $0, in: df) }
        #expect(results[0].name == "scoop" && results[0].amount == 1)
        #expect(results[1].name == "tbsp" && results[1].amount == 2.5)
    }

    @Test func partialOrEmptyRowsAreDropped() throws {
        let df = try frame("Name,Common Household Measurement,Common Household Measurement Amount\nA,,\nB,tbsp,\nC,,2\nD,cup,0\n")
        for row in df.rows {
            let result = FoodCSVHouseholdParser.parse(row: row, in: df)
            #expect(result.name == nil)
            #expect(result.amount == nil)
        }
    }

    @Test func onlyOneColumnPresentYieldsNil() throws {
        let df = try frame("Name,Common Household Measurement\nA,scoop\n")
        for row in df.rows {
            #expect(FoodCSVHouseholdParser.parse(row: row, in: df).name == nil)
        }
    }
}

@MainActor
struct FoodCSVImporterTests {

    private func frame(_ csv: String) throws -> DataFrame {
        try DataFrame(csvData: Data(csv.utf8), options: CSVReadingOptions(hasHeaderRow: true, delimiter: ","))
    }

    /// Header layout of the user's real export (no household columns, empty Variation Group).
    @Test func realExportLayoutImportsWithEmptyHouseholdFields() throws {
        let csv = "Timestamp,Brand,Name,Processing Level,Serving Size,Serving Unit,Calories,Fat,Saturated Fat,Trans Fat,Protein,Carbs,Dietary Fiber,Added Sugar,Category,Variation Group\n"
            + "2026-08-10T08:00:41Z,Unbranded,Banana,Whole,118.0,g,105,0.5,0.0,0.0,1.5,27.0,3.1,0.0,Fruits,\n"
            + "2026-08-10T08:01:03Z,Unbranded,Walnuts,Whole,30.0,g,200,19.0,0.0,0.0,5.0,4.0,2.0,0.0,Nuts & Seeds,\n"
        let result = FoodCSVImporter.parse(try frame(csv))
        #expect(result.items.count == 2)
        #expect(result.items[0].name == "Banana")
        #expect(result.items[0].calories == 105)
        #expect(result.items[0].servingSize == 118.0)
        #expect(result.items[0].category == "Fruits")
        #expect(result.items.allSatisfy { $0.commonHouseholdMeasurement == nil && $0.commonHouseholdMeasurementAmount == nil })
        #expect(result.missingColumns.contains(FoodCSVHouseholdParser.nameColumn))
        #expect(result.missingColumns.contains(FoodCSVHouseholdParser.amountColumn))
    }

    @Test func nameOnlyCSVUsesDefaultsInsteadOfCrashing() throws {
        let result = FoodCSVImporter.parse(try frame("Name\nMystery Food\n"))
        #expect(result.items.count == 1)
        let item = result.items[0]
        #expect(item.brandName == "")
        #expect(item.servingUnit == "")
        #expect(item.servingSize == 0)
        #expect(item.calories == 0)
        #expect(item.protein == 0)
        #expect(item.category == "Imported Foods")
        #expect(FoodCategoryList.defaultCategories.contains("Imported Foods"))
        #expect(FoodCategoryList.displayName(for: "Imported Foods") == "Imported Foods")
        #expect(FoodCategoryList.displayOrder(for: "Imported Foods") == 17)
        #expect(result.missingColumns.contains("Calories"))
    }

    @Test func missingNameColumnSkipsRowsInsteadOfCrashing() throws {
        let result = FoodCSVImporter.parse(try frame("Brand,Calories\nAcme,100\nOther,50\n"))
        #expect(result.items.isEmpty)
        #expect(result.skippedRows == 2)
    }

    @Test func rowsWithBlankNameAreSkipped() throws {
        let result = FoodCSVImporter.parse(try frame("Name,Calories\nA,10\n,20\nC,30\n"))
        #expect(result.items.map { $0.name } == ["A", "C"])
        #expect(result.skippedRows == 1)
    }

    @Test func householdColumnsRoundTrip() throws {
        let csv = "Name,Calories,Common Household Measurement,Common Household Measurement Amount\nWhey,125,scoop,1\nOats,150,,\n"
        let result = FoodCSVImporter.parse(try frame(csv))
        #expect(result.items[0].commonHouseholdMeasurement == "scoop")
        #expect(result.items[0].commonHouseholdMeasurementAmount == 1)
        #expect(result.items[1].commonHouseholdMeasurement == nil)
        #expect(result.missingColumns.isEmpty == false) // other columns absent, but household ones present
        #expect(!result.missingColumns.contains(FoodCSVHouseholdParser.nameColumn))
    }

    @Test func safeRowReturnsNilForAbsentColumns() throws {
        let df = try frame("Name\nA\n")
        for dataRow in df.rows {
            let row = SafeCSVRow(row: dataRow, dataFrame: df)
            #expect(row.string("Nope") == nil)
            #expect(row.double("Nope") == nil)
            #expect(row.int("Nope") == nil)
            #expect(row.date("Nope") == nil)
            #expect(row.string("Name") == "A")
        }
    }
}

@MainActor
struct HouseholdMeasurementAdjusterTests {

    private func adjust(
        oldSize: Double = 20, newSize: Double? = 40,
        oldUnit: String = "g", newUnit: String = "g",
        oldName: String? = "scoop", oldAmount: Double? = 1,
        curName: String? = "scoop", curAmount: Double? = 1
    ) -> HouseholdMeasurementAdjustment? {
        HouseholdMeasurementAdjuster.adjustment(
            originalSize: oldSize, originalUnit: oldUnit, originalMeasurement: oldName, originalAmount: oldAmount,
            currentSize: newSize, currentUnit: newUnit, currentMeasurement: curName, currentAmount: curAmount
        )
    }

    @Test func doublingServingDoublesAmount() {
        let result = adjust()
        #expect(result?.oldAmount == 1)
        #expect(result?.newAmount == 2)
        #expect(result?.measurement == "scoop")
    }

    @Test func halvingServingHalvesAmount() {
        #expect(adjust(oldSize: 40, newSize: 20, oldAmount: 2, curAmount: 2)?.newAmount == 1)
    }

    @Test func nonTerminatingRatiosRoundToTwoDecimals() {
        #expect(adjust(oldSize: 30, newSize: 10)?.newAmount == 0.33)
    }

    @Test func noProposalWhenNothingChangedOrNotApplicable() {
        #expect(adjust(newSize: 20) == nil)                          // size unchanged
        #expect(adjust(newSize: nil) == nil)                         // no size entered
        #expect(adjust(newSize: 0) == nil)                           // zero size
        #expect(adjust(oldSize: 0) == nil)                           // can't scale from zero
        #expect(adjust(newUnit: "oz") == nil)                        // unit changed
        #expect(adjust(oldName: nil, oldAmount: nil, curName: nil, curAmount: nil) == nil) // no household measure
        #expect(adjust(curAmount: 3) == nil)                         // user already edited the amount
        #expect(adjust(curName: "cup") == nil)                       // user already changed the measure
    }
}

struct CategorySuggesterTests {

    private struct Stub: MeasurementCategorySuggesting {
        let result: MeasurementCategory?
        func suggest(for unitName: String) async -> MeasurementCategory? { result }
    }

    @Test func firstNonNilSuggestionWins() async {
        let composite = CompositeCategorySuggester(suggesters: [
            Stub(result: nil), Stub(result: .packageContainer), Stub(result: .weight)
        ])
        #expect(await composite.suggest(for: "sachet") == .packageContainer)
    }

    @Test func fallsThroughToNilWhenNoneSuggest() async {
        let composite = CompositeCategorySuggester(suggesters: [Stub(result: nil), Stub(result: nil)])
        #expect(await composite.suggest(for: "zzz") == nil)
    }
}
