# Phase 1 API Contract — FDA Regulatory Domain, Lexical Parsers & Self-Healing Math Engine

## Section 1: Milestone 3.1 — `FoodItem.swift`, `AddFoodView.swift`, & `FDADomainModels.swift`

### 1.1 `NutritionAssistant/Shared/Models/FoodItem.swift`
**Responsibility:** Persists user food and supplement templates in SwiftData, including the `isSupplement` regulatory classification flag and household measurement pairing state.

```swift
@Model
final class FoodItem {
    var id: UUID
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
    var category: String
    var foodVariationGroup: String?
    var commonHouseholdMeasurement: String?
    var commonHouseholdMeasurementAmount: Double?
    var isSupplement: Bool?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        brandName: String,
        name: String,
        processingLevel: String,
        servingSize: Double,
        servingUnit: String,
        calories: Int,
        fat: Double,
        saturatedFat: Double,
        transFat: Double,
        protein: Double,
        carb: Double,
        dietaryFiber: Double,
        addedSugar: Double,
        category: String = "Prepared Foods",
        foodVariationGroup: String? = nil,
        commonHouseholdMeasurement: String? = nil,
        commonHouseholdMeasurementAmount: Double? = nil,
        isSupplement: Bool? = nil
    )

    var hasValidHouseholdMeasurement: Bool { get }
    static func isValidHouseholdPair(name: String?, amount: Double?) -> Bool
}
```

### 1.2 `NutritionAssistant/Views/AddFoodView.swift`
**Responsibility:** Provides the SwiftUI form for creating and editing `FoodItem` records and exposes `applyScannedPayload(_:)` to auto-populate nutrition and serving state from a validated FDA scan without overwriting manual metadata.

```swift
struct AddFoodView: View {
    var existingFood: FoodItem?
    init(existingFood: FoodItem? = nil)
    var body: some View { get }
    func applyScannedPayload(_ payload: ScannedNutritionPayload)
}
```

### 1.3 `NutritionAssistant/Shared/Models/FDADomainModels.swift`
**Responsibility:** Defines the core FDA regulatory topologies, demographic groups, exhaustive canonical nutrient identifiers, threshold/omission declaration states, parsed serving size structures, and the validated `ScannedNutritionPayload` model.

```swift
enum FDALabelTopology: String, Codable, CaseIterable, Sendable, Hashable {
    case standardVertical
    case sideBySideMicronutrients
    case tabularHorizontal
    case dualColumnSameFood
    case dualColumnPerContainer
    case dualColumnPerUnit
    case tabularDualColumn
    case aggregateVariety
    case simplified
    case smallPackageTabular
    case linearString
    case supplementFacts

    var isSupplementFacts: Bool { get }
    var isMultiColumn: Bool { get }
    var isTabularLayout: Bool { get }
}

enum FDADemographicGroup: String, Codable, CaseIterable, Sendable, Hashable {
    case infantsThrough12Months
    case children1Through3Years
    case adultsAndChildren4OrMoreYears
    case pregnantAndLactatingWomen

    var referenceCalorieDiet: Int? { get }
}

enum NutrientIndentationLevel: Int, Codable, CaseIterable, Comparable, Sendable, Hashable {
    case level0 = 0
    case level1 = 1
    case level2 = 2

    static func < (lhs: NutrientIndentationLevel, rhs: NutrientIndentationLevel) -> Bool
}

enum NutrientUnit: String, Codable, CaseIterable, Sendable, Hashable {
    case kcal = "kcal"
    case kJ = "kJ"
    case g = "g"
    case mg = "mg"
    case mcg = "mcg"
    case iu = "IU"
    case mcgDFE = "mcg DFE"
    case mgNE = "mg NE"
    case mcgRAE = "mcg RAE"
    case percent = "%"
}

enum CanonicalNutrientID: String, Codable, CaseIterable, Sendable, Hashable {
    case calories
    case caloriesFromSaturatedFat
    case caloriesFromFat
    case totalFat
    case saturatedFat
    case transFat
    case polyunsaturatedFat
    case monounsaturatedFat
    case cholesterol
    case sodium
    case fluoride
    case totalCarbohydrate
    case dietaryFiber
    case solubleFiber
    case insolubleFiber
    case totalSugars
    case addedSugars
    case sugarAlcohol
    case isomalt
    case lactitol
    case xylitol
    case maltitol
    case sorbitol
    case hydrogenatedStarchHydrolysates
    case mannitol
    case erythritol
    case protein
    case vitaminD
    case calcium
    case iron
    case potassium
    case vitaminA
    case vitaminC
    case vitaminE
    case vitaminK
    case thiamin
    case riboflavin
    case niacin
    case vitaminB6
    case folate
    case vitaminB12
    case biotin
    case pantothenicAcid
    case phosphorus
    case iodine
    case magnesium
    case zinc
    case selenium
    case copper
    case manganese
    case chromium
    case molybdenum
    case chloride
    case choline
    case folicAcid
    case betaCarotenePercentage
    case proprietaryBlend
    case otherDietaryIngredient

    var indentationLevel: NutrientIndentationLevel { get }
    var primaryUnit: NutrientUnit { get }
    var allowedUnits: Set<NutrientUnit> { get }
    var usesOneGramHalfStepThreshold: Bool { get }
    var isFatFamily: Bool { get }
    var isMicronutrientRDI: Bool { get }
    var isSpecificSugarAlcohol: Bool { get }
}

enum NutrientThresholdKind: String, Codable, CaseIterable, Sendable, Hashable {
    case lessThanFiveCalories
    case lessThanHalfGram
    case lessThanOneGram
    case lessThanFiveMilligrams
    case lessThanOnePercentDV
    case lessThanTwoPercentDV
}

enum DeclaredNutrientAmount: Codable, Sendable, Equatable, Hashable {
    case omitted
    case explicitZero(unit: NutrientUnit?)
    case threshold(NutrientThresholdKind, unit: NutrientUnit?)
    case insignificantFootnote(symbol: String?, reason: String)
    case exact(value: Double, unit: NutrientUnit, secondaryValue: Double?, secondaryUnit: NutrientUnit?)

    func resolvedValue(for nutrient: CanonicalNutrientID) -> Double
    func resolvedCalories() -> Int
    var unit: NutrientUnit? { get }
}

enum DeclaredPercentDV: Codable, Sendable, Equatable, Hashable {
    case omitted
    case notEstablished(symbol: String?)
    case threshold(NutrientThresholdKind)
    case exact(Int)

    var numericPercent: Double? { get }
}

struct ParsedNutrientRow: Codable, Sendable, Equatable, Hashable {
    let nutrient: CanonicalNutrientID
    let rawName: String
    var amount: DeclaredNutrientAmount
    var percentDV: DeclaredPercentDV
    let indentationLevel: NutrientIndentationLevel
    let sourceCompoundDescription: String?
    let columnIndex: Int

    init(
        nutrient: CanonicalNutrientID,
        rawName: String,
        amount: DeclaredNutrientAmount,
        percentDV: DeclaredPercentDV = .omitted,
        indentationLevel: NutrientIndentationLevel? = nil,
        sourceCompoundDescription: String? = nil,
        columnIndex: Int = 0
    )
}

struct ParsedServingSize: Codable, Sendable, Equatable, Hashable {
    var servingSize: Double
    var servingUnit: String
    var commonHouseholdMeasurementAmount: Double?
    var commonHouseholdMeasurement: String?
    var servingsPerContainer: Double?
    var servingsPerContainerModifier: String?
    var perDayMultiplier: Int?
    var usedMetricFallbackConversion: Bool

    init(
        servingSize: Double,
        servingUnit: String = "g",
        commonHouseholdMeasurementAmount: Double? = nil,
        commonHouseholdMeasurement: String? = nil,
        servingsPerContainer: Double? = nil,
        servingsPerContainerModifier: String? = nil,
        perDayMultiplier: Int? = nil,
        usedMetricFallbackConversion: Bool = false
    )
}

enum FDALegitimateExemptionKind: String, Codable, CaseIterable, Sendable, Hashable {
    case multiunitNotLabeledForRetailSale
    case smallPackageContactString
}

enum ValidationSeverity: String, Codable, CaseIterable, Sendable, Hashable {
    case info
    case healed
    case warning
    case error
}

struct ValidationDiagnostic: Codable, Sendable, Equatable, Hashable {
    let severity: ValidationSeverity
    let nutrient: CanonicalNutrientID?
    let code: String
    let message: String

    init(severity: ValidationSeverity, nutrient: CanonicalNutrientID? = nil, code: String, message: String)
}

struct ScannedNutritionPayload: Codable, Sendable, Equatable {
    var isSupplement: Bool
    var servingSize: Double
    var servingUnit: String
    var commonHouseholdMeasurement: String?
    var commonHouseholdMeasurementAmount: Double?
    var calories: Int
    var fat: Double
    var saturatedFat: Double
    var transFat: Double
    var carb: Double
    var dietaryFiber: Double
    var addedSugar: Double
    var protein: Double
    var topology: FDALabelTopology
    var demographicGroup: FDADemographicGroup
    var confidenceScore: Double
    var atwaterCalorieCheckPassed: Bool
    var expectedAtwaterCalorieRange: ClosedRange<Int>
    var healedNutrients: Set<CanonicalNutrientID>
    var diagnostics: [ValidationDiagnostic]
    var allParsedNutrients: [CanonicalNutrientID: DeclaredNutrientAmount]

    init(
        isSupplement: Bool,
        servingSize: Double,
        servingUnit: String,
        commonHouseholdMeasurement: String? = nil,
        commonHouseholdMeasurementAmount: Double? = nil,
        calories: Int,
        fat: Double,
        saturatedFat: Double,
        transFat: Double,
        carb: Double,
        dietaryFiber: Double,
        addedSugar: Double,
        protein: Double,
        topology: FDALabelTopology = .standardVertical,
        demographicGroup: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        confidenceScore: Double = 1.0,
        atwaterCalorieCheckPassed: Bool = true,
        expectedAtwaterCalorieRange: ClosedRange<Int> = 0...0,
        healedNutrients: Set<CanonicalNutrientID> = [],
        diagnostics: [ValidationDiagnostic] = [],
        allParsedNutrients: [CanonicalNutrientID: DeclaredNutrientAmount] = [:]
    )
}
```

---

## Section 2: Milestone 3.2 — `FDARegulatoryConstants.swift`

### 2.1 `NutritionAssistant/Shared/Models/FDARegulatoryConstants.swift`
**Responsibility:** Encodes the complete FDA Daily Reference Values (DRVs), 27-micronutrient Reference Daily Intakes (RDIs) across all 4 demographic groups, biochemical and Atwater caloric conversion factors, standard household-to-metric conversions, and programmatic `21 CFR § 101.9(c)` rounding interval calculators.

```swift
struct FDADemographicReferenceValues: Codable, Sendable, Equatable, Hashable {
    let unit: NutrientUnit
    let adultsAndChildren4OrMoreYears: Double?
    let infantsThrough12Months: Double?
    let children1Through3Years: Double?
    let pregnantAndLactatingWomen: Double?

    init(
        unit: NutrientUnit,
        adultsAndChildren4OrMoreYears: Double?,
        infantsThrough12Months: Double?,
        children1Through3Years: Double?,
        pregnantAndLactatingWomen: Double?
    )

    func value(for demographic: FDADemographicGroup) -> Double?
}

enum FDARegulatoryConstants {
    static let drvTable: [CanonicalNutrientID: FDADemographicReferenceValues]
    static let rdiTable: [CanonicalNutrientID: FDADemographicReferenceValues]
    static let infantProhibitedPercentDVNutrients: Set<CanonicalNutrientID>
    static let supplementNutrientsAllowingRoundedPercentDVBasis: Set<CanonicalNutrientID>

    static func dailyReferenceValue(
        for nutrient: CanonicalNutrientID,
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears
    ) -> (value: Double, unit: NutrientUnit)?

    enum BiochemicalConversion {
        static let mcgRetinolPerMcgRAE: Double
        static let mcgSupplementalBetaCarotenePerMcgRAE: Double
        static let mcgDietaryBetaCarotenePerMcgRAE: Double
        static let mcgDietaryAlphaCarotenePerMcgRAE: Double
        static let mcgDietaryBetaCryptoxanthinPerMcgRAE: Double
        static let vitaminAIUPerMcgRetinol: Double
        static let vitaminDIUPerMcg: Double
        static let vitaminDMcgPerIU: Double
        static let mgRRRAlphaTocopherolPerMgLabelClaim: Double
        static let mgAllRacAlphaTocopherolPerMgLabelClaim: Double
        static let vitaminEMgNaturalPerIU: Double
        static let vitaminEMgSyntheticPerIU: Double
        static let mgNiacinPerMgNE: Double
        static let mgTryptophanPerMgNE: Double
        static let mcgFoodFolatePerMcgDFE: Double
        static let mcgFolicAcidPerMcgDFE: Double
        static let mcgDFEPerMcgFolicAcid: Double
        static let kilojoulesPerKilocalorie: Double
    }

    static func convertToPrimaryReferenceUnit(
        value: Double,
        fromUnit: NutrientUnit,
        for nutrient: CanonicalNutrientID
    ) -> Double

    enum CaloricFactors {
        static let proteinKcalPerGram: Double
        static let totalCarbohydrateKcalPerGram: Double
        static let totalFatKcalPerGram: Double
        static let solubleNonDigestibleCarbohydrateKcalPerGram: Double
        static let insolubleFiberKcalPerGram: Double
        static let alluloseKcalPerGram: Double
        static let sugarAlcoholKcalPerGram: [CanonicalNutrientID: Double]
        static let genericSugarAlcoholKcalPerGramRange: ClosedRange<Double>
    }

    static let householdVolumeToMilliliters: [String: Double]
    static let householdWeightToGrams: [String: Double]

    static func metricEquivalent(
        forHouseholdUnit rawUnit: String,
        amount: Double
    ) -> (metricAmount: Double, metricUnit: String)?

    static func roundServingMetricQuantity(_ quantity: Double) -> Double

    static func legalActualInterval(
        for nutrient: CanonicalNutrientID,
        declared: DeclaredNutrientAmount,
        isSupplement: Bool = false
    ) -> ClosedRange<Double>?

    static func roundingHalfStepTolerance(
        for nutrient: CanonicalNutrientID,
        declaredValue: Double,
        isSupplement: Bool = false
    ) -> Double

    static func roundToFDADeclared(
        nutrient: CanonicalNutrientID,
        actualValue: Double
    ) -> DeclaredNutrientAmount

    static func legalPercentDVInterval(
        for nutrient: CanonicalNutrientID,
        declaredAmount: DeclaredNutrientAmount,
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        isSupplement: Bool = false
    ) -> ClosedRange<Double>?

    static func legalUnroundedIntervalFromPercentDV(
        for nutrient: CanonicalNutrientID,
        declaredPercentDV: DeclaredPercentDV,
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        isSupplement: Bool = false
    ) -> ClosedRange<Double>?

    static func percentDVRoundingHalfStep(
        for nutrient: CanonicalNutrientID,
        percent: Double,
        isSupplement: Bool = false
    ) -> Double
}
```

---

## Section 3: Milestone 3.3 — `FDALexicalNormalizer.swift`

### 3.1 `NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift`
**Responsibility:** Normalizes noisy OCR transcripts using exhaustive FDA synonym and small-package abbreviation dictionaries, resolves order-independent `CanonicalNutrientID` rows (including inline `Added Sugars`, dot-leader supplement rows, and source compounds), parses serving sizes with fraction and fallback metric conversions, and filters out Subpart D decoy claims and `§ 101.17` hairline-boxed warnings.

```swift
enum FDALexicalNormalizer {
    static let conventionalNutrientSequence: [CanonicalNutrientID]
    static let supplementMicronutrientSequence: [CanonicalNutrientID]
    static let structuralHeaderAbbreviations: [String: String]
    static let authorizedAbbreviationExpansions: [(pattern: String, replacement: String)]
    static let canonicalNutrientSynonyms: [String: CanonicalNutrientID]
    static let decoyComparativeSubstrings: [String]
    static let mandatoryBoxedWarningSubstrings: [String]
    static let unicodeFractionMap: [Character: Double]

    static func isDecoyComparativeString(_ text: String) -> Bool
    static func isMandatoryBoxedWarning(_ text: String) -> Bool
    static func detectLegitimateExemption(_ text: String) -> FDALegitimateExemptionKind?

    static func stripDotLeaders(_ text: String) -> String

    static func stripSupplementSourceCompounds(_ text: String) -> (
        cleanedText: String,
        sourceCompound: String?,
        betaCarotenePercent: Double?,
        folicAcidMcg: Double?
    )

    static func stripFootnoteSuperscripts(_ text: String) -> String
    static func expandAuthorizedAbbreviations(_ text: String) -> String
    static func resolveNutrientID(from rawText: String) -> CanonicalNutrientID?

    static func parseNutrientRow(
        cells: [String],
        isSupplement: Bool = false,
        defaultColumnIndex: Int = 0
    ) -> [ParsedNutrientRow]

    static func parseInsignificantSourceFooter(_ text: String) -> Set<CanonicalNutrientID>

    static func parseLinearDisplayPanel(
        _ text: String,
        isSupplement: Bool = false
    ) -> (servingSize: ParsedServingSize?, rows: [ParsedNutrientRow])

    static func parseFractionOrNumber(_ rawToken: String) -> Double?
    static func normalizeServingMetricUnit(_ rawUnit: String) -> String?

    static func parseServingSize(
        from rawServingSizeText: String,
        servingsPerContainerText: String? = nil,
        isSupplement: Bool = false
    ) -> ParsedServingSize?

    static func classifyTopology(fromLines lines: [String], tableColumnCount: Int = 2) -> FDALabelTopology

    static func extractDeclaredAmount(
        from rawText: String,
        for nutrient: CanonicalNutrientID
    ) -> DeclaredNutrientAmount

    static func extractDeclaredPercentDV(
        from cells: [String],
        for nutrient: CanonicalNutrientID
    ) -> DeclaredPercentDV

    static func normalizeOCRNumericUnitTokens(
        in text: String,
        for nutrient: CanonicalNutrientID
    ) -> String
}
```

---

## Section 4: Milestone 3.4 — `FDANutritionValidator.swift`

### 4.1 `NutritionAssistant/Shared/Models/FDANutritionValidator.swift`
**Responsibility:** Infers the active FDA demographic group, enforces legal nutrient units and glyph disambiguation, cross-checks `% DV` against `21 CFR § 101.9(c)` rounding intervals to conservatively heal dropped decimals and glyph swaps, enforces sub-nutrient ceiling invariants and Atwater 4-4-9 caloric bounds, and builds the final `ScannedNutritionPayload` for `AddFoodView`.

```swift
enum FDANutritionValidator {
    static func inferDemographicGroup(
        fromRawTexts rawTexts: [String],
        rows: [ParsedNutrientRow]
    ) -> FDADemographicGroup

    static func enforceLegalUnitAndDisambiguateGlyphs(
        row: ParsedNutrientRow,
        demographic: FDADemographicGroup,
        isSupplement: Bool
    ) -> (updatedRow: ParsedNutrientRow, wasHealed: Bool, diagnostic: ValidationDiagnostic?)

    static func validateAndHealAgainstPercentDV(
        row: ParsedNutrientRow,
        demographic: FDADemographicGroup,
        isSupplement: Bool
    ) -> (updatedRow: ParsedNutrientRow, wasHealed: Bool, diagnostic: ValidationDiagnostic?)

    static func enforceSubNutrientCeilings(
        nutrients: inout [CanonicalNutrientID: ParsedNutrientRow],
        demographic: FDADemographicGroup,
        isSupplement: Bool
    ) -> (healedNutrients: Set<CanonicalNutrientID>, diagnostics: [ValidationDiagnostic])

    static func evaluateAtwaterCalorieInvariants(
        nutrients: [CanonicalNutrientID: ParsedNutrientRow],
        isSupplement: Bool
    ) -> (passed: Bool, expectedRange: ClosedRange<Int>, diagnostic: ValidationDiagnostic?)

    static func buildPayload(
        topology: FDALabelTopology,
        servingSize: ParsedServingSize?,
        rows: [ParsedNutrientRow],
        insignificantNutrients: Set<CanonicalNutrientID> = [],
        rawPanelTexts: [String] = [],
        selectedColumnIndex: Int = 0
    ) -> ScannedNutritionPayload
}
```


---

## Section 5: Milestone 3.5 — Phase 2 Integration Recipe

```swift
// 1. Reject mandatory § 101.17 warning boxes and Subpart D decoy comparison strings
let validRows = rawTableRows.filter { rowCells in
    let line = rowCells.joined(separator: " ")
    return !FDALexicalNormalizer.isMandatoryBoxedWarning(line) && !FDALexicalNormalizer.isDecoyComparativeString(line)
}
let allLines = validRows.map { $0.joined(separator: " ") }
let topology = FDALexicalNormalizer.classifyTopology(fromLines: allLines, tableColumnCount: validRows.first?.count ?? 2)

// 2. Parse serving size, insignificant-source footers, and canonical nutrient rows
let serving = FDALexicalNormalizer.parseServingSize(from: servingLineText, servingsPerContainerText: containerLineText, isSupplement: topology.isSupplementFacts)
let insignificant = allLines.reduce(into: Set<CanonicalNutrientID>()) { $0.formUnion(FDALexicalNormalizer.parseInsignificantSourceFooter($1)) }
let nutrientRows = validRows.flatMap { FDALexicalNormalizer.parseNutrientRow(cells: $0, isSupplement: topology.isSupplementFacts) }

// 3. Run % DV self-healing, sub-nutrient ceiling checks, and Atwater validation to build the AddFoodView payload
let payload = FDANutritionValidator.buildPayload(
    topology: topology, servingSize: serving, rows: nutrientRows, insignificantNutrients: insignificant, rawPanelTexts: allLines
)
```
