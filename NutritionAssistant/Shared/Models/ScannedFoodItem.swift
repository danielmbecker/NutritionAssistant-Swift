//
//  ScannedFoodItem.swift
//  NutritionAssistant
//
//  Milestone 6.1: Full-Spectrum FDA NutritionProfile & @Model final class ScannedFoodItem
//  Captures all 58 CanonicalNutrientIDs across 21 CFR § 101.9 (Nutrition Facts) and
//  21 CFR § 101.36 (Supplement Facts), supports single-call scaling and aggregation for
//  future RecipeItem/ConsumedItem integration, and implements Copy-on-Edit (new UUID +
//  soft-archiving) immutable snapshot versioning.
//

import Foundation
import SwiftData

// MARK: - 1. CanonicalNutrientID Display & Layout Extensions

extension CanonicalNutrientID {

    /// Canonical FDA display title used when rendering a digital Nutrition Facts or Supplement Facts panel.
    var fdaLabelDisplayName: String {
        switch self {
        case .calories: return "Calories"
        case .caloriesFromSaturatedFat: return "Calories from Saturated Fat"
        case .caloriesFromFat: return "Calories from Fat"
        case .totalFat: return "Total Fat"
        case .saturatedFat: return "Saturated Fat"
        case .transFat: return "Trans Fat"
        case .polyunsaturatedFat: return "Polyunsaturated Fat"
        case .monounsaturatedFat: return "Monounsaturated Fat"
        case .cholesterol: return "Cholesterol"
        case .sodium: return "Sodium"
        case .fluoride: return "Fluoride"
        case .totalCarbohydrate: return "Total Carbohydrate"
        case .dietaryFiber: return "Dietary Fiber"
        case .solubleFiber: return "Soluble Fiber"
        case .insolubleFiber: return "Insoluble Fiber"
        case .totalSugars: return "Total Sugars"
        case .addedSugars: return "Added Sugars"
        case .sugarAlcohol: return "Sugar Alcohol"
        case .isomalt: return "Isomalt"
        case .lactitol: return "Lactitol"
        case .xylitol: return "Xylitol"
        case .maltitol: return "Maltitol"
        case .sorbitol: return "Sorbitol"
        case .hydrogenatedStarchHydrolysates: return "Hydrogenated Starch Hydrolysates"
        case .mannitol: return "Mannitol"
        case .erythritol: return "Erythritol"
        case .protein: return "Protein"
        case .vitaminD: return "Vitamin D"
        case .calcium: return "Calcium"
        case .iron: return "Iron"
        case .potassium: return "Potassium"
        case .vitaminA: return "Vitamin A"
        case .vitaminC: return "Vitamin C"
        case .vitaminE: return "Vitamin E"
        case .vitaminK: return "Vitamin K"
        case .thiamin: return "Thiamin"
        case .riboflavin: return "Riboflavin"
        case .niacin: return "Niacin"
        case .vitaminB6: return "Vitamin B6"
        case .folate: return "Folate"
        case .vitaminB12: return "Vitamin B12"
        case .biotin: return "Biotin"
        case .pantothenicAcid: return "Pantothenic Acid"
        case .phosphorus: return "Phosphorus"
        case .iodine: return "Iodine"
        case .magnesium: return "Magnesium"
        case .zinc: return "Zinc"
        case .selenium: return "Selenium"
        case .copper: return "Copper"
        case .manganese: return "Manganese"
        case .chromium: return "Chromium"
        case .molybdenum: return "Molybdenum"
        case .chloride: return "Chloride"
        case .choline: return "Choline"
        case .folicAcid: return "Folic Acid"
        case .betaCarotenePercentage: return "Beta-Carotene"
        case .proprietaryBlend: return "Proprietary Blend"
        case .otherDietaryIngredient: return "Other Dietary Ingredient"
        }
    }

    /// FDA-authorized compact display name (`21 CFR § 101.9(j)(13)(ii)(B)`) for tabular and multi-column layouts.
    var fdaCompactDisplayName: String {
        switch self {
        case .caloriesFromSaturatedFat: return "Sat. Fat Cal."
        case .saturatedFat: return "Sat. Fat"
        case .polyunsaturatedFat: return "Polyunsat. Fat"
        case .monounsaturatedFat: return "Monounsat. Fat"
        case .cholesterol: return "Cholest."
        case .totalCarbohydrate: return "Total Carb."
        case .dietaryFiber: return "Dietary Fiber"
        case .solubleFiber: return "Sol. Fiber"
        case .insolubleFiber: return "Insol. Fiber"
        case .sugarAlcohol: return "Sugar Alc."
        case .vitaminD: return "Vit. D"
        case .potassium: return "Potas."
        case .vitaminA: return "Vit. A"
        case .vitaminC: return "Vit. C"
        case .vitaminE: return "Vit. E"
        case .vitaminK: return "Vit. K"
        case .vitaminB6: return "Vit. B6"
        case .vitaminB12: return "Vit. B12"
        case .pantothenicAcid: return "Pantothenic Acid"
        case .hydrogenatedStarchHydrolysates: return "HSH"
        default: return fdaLabelDisplayName
        }
    }

    /// Indicates whether this nutrient sits in the upper macronutrient/electrolyte tier (above the thick bar below Protein) on a conventional § 101.9 panel.
    var isUpperMacronutrientSection: Bool {
        switch self {
        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat,
             .cholesterol, .sodium, .fluoride,
             .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
             .totalSugars, .addedSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol, .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .protein:
            return true
        default:
            return false
        }
    }

    /// Indicates whether this nutrient belongs to the Left Nutrient Stack (Lipids, Cholesterol, Sodium, Fluoride) in a 3-Zone Tabular Horizontal layout (`Topologies A, I, K`).
    var isTabularLeftStackNutrient: Bool {
        switch self {
        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat,
             .cholesterol, .sodium, .fluoride:
            return true
        default:
            return false
        }
    }

    /// Indicates whether this nutrient belongs to the Right Nutrient Stack (Carbohydrates, Fiber, Sugars, Sugar Alcohols, Protein) in a 3-Zone Tabular Horizontal layout (`Topologies A, I, K`).
    var isTabularRightStackNutrient: Bool {
        switch self {
        case .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
             .totalSugars, .addedSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol, .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .protein:
            return true
        default:
            return false
        }
    }

    /// Indicates whether this nutrient is one of the 15 mandatory lines on a standard vertical 21 CFR § 101.9 label.
    var isStandardMandatoryFoodNutrient: Bool {
        switch self {
        case .calories, .totalFat, .saturatedFat, .transFat, .cholesterol, .sodium,
             .totalCarbohydrate, .dietaryFiber, .totalSugars, .addedSugars, .protein,
             .vitaminD, .calcium, .iron, .potassium:
            return true
        default:
            return false
        }
    }

    /// Indicates whether a `% Daily Value` is legally prohibited or never established for this nutrient on conventional food labels.
    var omitsPercentDVOnConventionalFood: Bool {
        switch self {
        case .calories, .caloriesFromSaturatedFat, .caloriesFromFat,
             .transFat, .polyunsaturatedFat, .monounsaturatedFat, .fluoride,
             .solubleFiber, .insolubleFiber, .totalSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol, .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .folicAcid, .betaCarotenePercentage, .proprietaryBlend, .otherDietaryIngredient:
            return true
        default:
            return false
        }
    }
}

// MARK: - 2. ScannedNutrientEntry

/// Represents a single populated nutrient or dietary ingredient row inside a `NutritionProfile`.
struct ScannedNutrientEntry: Codable, Sendable, Equatable, Hashable, Identifiable {
    var id: UUID
    var nutrient: CanonicalNutrientID
    var amount: DeclaredNutrientAmount
    var percentDV: DeclaredPercentDV
    /// Optional custom display name for Supplement Facts `(b)(3)` ingredients or proprietary blends.
    var customName: String?
    /// Optional inline chemical/botanical source compound description (e.g., `"as calcium carbonate"`).
    var sourceCompoundDescription: String?
    /// True when the quantitative weight was omitted on the label (e.g., cereal vitamin rows in `Examples E & M`) and derived from `% DV`.
    var derivedFromPercentDVOnly: Bool

    init(
        id: UUID = UUID(),
        nutrient: CanonicalNutrientID,
        amount: DeclaredNutrientAmount,
        percentDV: DeclaredPercentDV = .omitted,
        customName: String? = nil,
        sourceCompoundDescription: String? = nil,
        derivedFromPercentDVOnly: Bool = false
    ) {
        self.id = id
        self.nutrient = nutrient
        self.amount = amount
        self.percentDV = percentDV
        self.customName = customName
        self.sourceCompoundDescription = sourceCompoundDescription
        self.derivedFromPercentDVOnly = derivedFromPercentDVOnly
    }

    /// Resolved numeric value in the nutrient's primary or declared unit.
    var resolvedValue: Double {
        amount.resolvedValue(for: nutrient)
    }

    /// Resolved unit of measurement for display and editing.
    var resolvedUnit: NutrientUnit {
        amount.unit ?? nutrient.primaryUnit
    }

    /// Indicates whether this entry represents an active, non-omitted line on the label.
    var isPresentOnLabel: Bool {
        switch amount {
        case .omitted, .insignificantFootnote:
            return percentDV.numericPercent != nil
        case .explicitZero, .threshold, .exact:
            return true
        }
    }

    /// Formats a `Double` cleanly without trailing `.0` (e.g., `8.0` -> `"8"`, `1.5` -> `"1.5"`).
    static func formatNumber(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.001 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%g", (value * 100.0).rounded() / 100.0)
    }

    /// Formats the quantitative weight token for FDA label display (e.g., `"8g"`, `"160mg"`, `"<1g"`, `"40mcg DFE"`).
    func formattedWeightToken(compact: Bool = false) -> String {
        switch amount {
        case .omitted, .insignificantFootnote:
            return ""
        case .explicitZero(let unit):
            let u = (unit ?? nutrient.primaryUnit).rawValue
            return nutrient == .calories ? "0" : "0\(u)"
        case .threshold(let kind, let unit):
            let u = (unit ?? nutrient.primaryUnit).rawValue
            switch kind {
            case .lessThanFiveCalories:
                return "<5"
            case .lessThanHalfGram:
                return "<0.5\(u)"
            case .lessThanOneGram:
                return "<1\(u)"
            case .lessThanFiveMilligrams:
                return "<5\(u)"
            case .lessThanOnePercentDV, .lessThanTwoPercentDV:
                return "0\(u)"
            }
        case .exact(let value, let unit, let secondaryValue, let secondaryUnit):
            if nutrient == .calories || nutrient == .caloriesFromSaturatedFat || nutrient == .caloriesFromFat {
                return "\(Int(value.rounded()))"
            }
            if nutrient == .folicAcid {
                return "(\(Self.formatNumber(value))\(unit.rawValue))"
            }
            let primaryText = "\(Self.formatNumber(value))\(unit.rawValue)"
            if !compact, let secVal = secondaryValue, let secUnit = secondaryUnit {
                if nutrient == .folate && secUnit == .mcg {
                    return "\(primaryText) (\(Self.formatNumber(secVal))mcg folic acid)"
                }
                return "\(primaryText) (\(Self.formatNumber(secVal)) \(secUnit.rawValue))"
            }
            return primaryText
        }
    }

    /// Computes the read-only `% Daily Value` string for this nutrient row.
    /// Automatically recalculates `% DV` from `FDARegulatoryConstants` based on the current `amount`
    /// unless the row was scanned as `% DV`-only or carries a `†` (`notEstablished`) symbol.
    func formattedPercentDVToken(
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        isSupplement: Bool = false
    ) -> String {
        if !isSupplement && nutrient.omitsPercentDVOnConventionalFood {
            return ""
        }

        if case .notEstablished(let symbol) = percentDV {
            return symbol ?? "†"
        }

        if isSupplement && (nutrient == .proprietaryBlend || nutrient == .otherDietaryIngredient || nutrient.omitsPercentDVOnConventionalFood) {
            return "†"
        }

        // Adult protein on conventional food labels only shows % DV if it was explicitly present on the scanned label.
        if !isSupplement && nutrient == .protein && demographic == .adultsAndChildren4OrMoreYears {
            if case .exact(let pct) = percentDV {
                return "\(pct)%"
            }
            return ""
        }

        // Infant labels prohibit % DV on saturatedFat, transFat, cholesterol, sodium, dietaryFiber, totalSugars, addedSugars.
        if !isSupplement && demographic == .infantsThrough12Months
            && FDARegulatoryConstants.infantProhibitedPercentDVNutrients.contains(nutrient) {
            return ""
        }

        // If this entry came from a %DV-only cereal/small-package row, preserve its scanned %DV display.
        if derivedFromPercentDVOnly {
            switch percentDV {
            case .exact(let pct):
                return "\(pct)%"
            case .threshold(let kind):
                return kind == .lessThanOnePercentDV ? "<1%" : "<2%"
            default:
                break
            }
        }

        if case .threshold(let kind) = percentDV {
            if kind == .lessThanOnePercentDV { return "<1%" }
            if kind == .lessThanTwoPercentDV { return "<2%" }
        }

        // Compute % DV dynamically from `FDARegulatoryConstants` using the current numeric weight.
        guard let (refVal, _) = FDARegulatoryConstants.dailyReferenceValue(for: nutrient, demographic: demographic),
              refVal > 0 else {
            return isSupplement ? "†" : ""
        }

        let numericAmount = resolvedValue
        if numericAmount <= 0 {
            if case .explicitZero = amount {
                return "0%"
            }
            if case .exact(let val, _, _, _) = amount, val == 0 {
                return "0%"
            }
            if case .exact(let pct) = percentDV {
                return "\(pct)%"
            }
            return "0%"
        }

        let rawPct = (numericAmount / refVal) * 100.0
        if isSupplement && rawPct > 0 && rawPct < 0.5 {
            return "<1%"
        }

        // If the existing scanned % DV is within the legal rounding interval of the current amount, keep it exact;
        // otherwise use the newly calculated rounded % DV (e.g., after inline user edits).
        if case .exact(let scannedPct) = percentDV,
           let interval = FDARegulatoryConstants.legalPercentDVInterval(
               for: nutrient,
               declaredAmount: amount,
               demographic: demographic,
               isSupplement: isSupplement
           ),
           interval.contains(Double(scannedPct)) {
            return "\(scannedPct)%"
        }

        let roundedPct = Int(rawPct.rounded())
        return "\(roundedPct)%"
    }
}

// MARK: - 3. NutritionProfile (Full-Spectrum Composable Value Type)

/// Composable value type storing the complete FDA nutrient spectrum (`58 CanonicalNutrientID`s + Supplement Tier-2 ingredients).
/// Supports single-call portion scaling (`.scaled(by:)`) and additive aggregation (`+`) for recipes and daily logs.
struct NutritionProfile: Codable, Sendable, Equatable, Hashable {
    /// Keyed map of canonical nutrients present on the food or supplement label.
    var entries: [CanonicalNutrientID: ScannedNutrientEntry]
    /// Ordered list of Supplement Facts `(b)(3)` non-RDI dietary ingredients and proprietary blends.
    var supplementTier2Entries: [ScannedNutrientEntry]

    init(
        entries: [CanonicalNutrientID: ScannedNutrientEntry] = [:],
        supplementTier2Entries: [ScannedNutrientEntry] = []
    ) {
        self.entries = entries
        self.supplementTier2Entries = supplementTier2Entries
    }

    static let zero = NutritionProfile()

    // MARK: - Payload Conversion Initializer

    /// Initializes a full-spectrum `NutritionProfile` directly from a `ScannedNutritionPayload`.
    init(from payload: ScannedNutritionPayload) {
        var builtEntries: [CanonicalNutrientID: ScannedNutrientEntry] = [:]
        var tier2: [ScannedNutrientEntry] = []

        for (nutrient, declaredAmount) in payload.allParsedNutrients {
            // Skip nutrients omitted via "Not a significant source of..." footnotes per user UI specification.
            if case .insignificantFootnote = declaredAmount {
                continue
            }

            let scannedPctDV = payload.allParsedPercentDVs[nutrient] ?? .omitted
            let wasDerivedFromDV = payload.derivedFromPercentDVNutrients.contains(nutrient)

            if case .omitted = declaredAmount, scannedPctDV.numericPercent == nil {
                continue
            }

            let entry = ScannedNutrientEntry(
                nutrient: nutrient,
                amount: declaredAmount,
                percentDV: scannedPctDV,
                customName: nil,
                sourceCompoundDescription: payload.sourceCompounds[nutrient],
                derivedFromPercentDVOnly: wasDerivedFromDV
            )

            if nutrient == .proprietaryBlend || nutrient == .otherDietaryIngredient {
                tier2.append(entry)
            } else {
                builtEntries[nutrient] = entry
            }
        }

        // Ensure Calories is always populated if present on payload.
        if builtEntries[.calories] == nil {
            builtEntries[.calories] = ScannedNutrientEntry(
                nutrient: .calories,
                amount: .exact(value: Double(payload.calories), unit: .kcal)
            )
        }

        // Ensure core macros present in payload are represented if no entry was created yet.
        let coreFallbacks: [(CanonicalNutrientID, Double, NutrientUnit)] = [
            (.totalFat, payload.fat, .g),
            (.saturatedFat, payload.saturatedFat, .g),
            (.transFat, payload.transFat, .g),
            (.totalCarbohydrate, payload.carb, .g),
            (.dietaryFiber, payload.dietaryFiber, .g),
            (.addedSugars, payload.addedSugar, .g),
            (.protein, payload.protein, .g)
        ]

        for (id, val, unit) in coreFallbacks where builtEntries[id] == nil {
            if !payload.isSupplement || val > 0 {
                if let rawDeclared = payload.allParsedNutrients[id], case .insignificantFootnote = rawDeclared {
                    continue
                }
                if payload.allParsedNutrients[id] == nil && payload.topology == .simplified
                    && id != .totalFat && id != .totalCarbohydrate && id != .protein {
                    continue
                }
                builtEntries[id] = ScannedNutrientEntry(
                    nutrient: id,
                    amount: val == 0.0 ? .explicitZero(unit: unit) : .exact(value: val, unit: unit)
                )
            }
        }

        self.entries = builtEntries
        self.supplementTier2Entries = tier2
    }

    // MARK: - Strongly-Typed Accessors & Mutators

    /// Returns the `ScannedNutrientEntry` for the specified `CanonicalNutrientID` if present on the label.
    func entry(for nutrient: CanonicalNutrientID) -> ScannedNutrientEntry? {
        guard let found = entries[nutrient], found.isPresentOnLabel else {
            return nil
        }
        return found
    }

    /// Returns the numeric value for the given `CanonicalNutrientID`, or `nil` if the nutrient is not present on the label.
    func value(for nutrient: CanonicalNutrientID) -> Double? {
        guard let found = entry(for: nutrient) else { return nil }
        return found.resolvedValue
    }

    /// Returns the non-optional numeric value for a nutrient (defaulting to `0.0` when omitted).
    func resolvedOrZero(for nutrient: CanonicalNutrientID) -> Double {
        value(for: nutrient) ?? 0.0
    }

    var calories: Int {
        get {
            if let calEntry = entries[.calories] {
                return calEntry.amount.resolvedCalories()
            }
            return 0
        }
        set {
            let clamped = max(0, newValue)
            var current = entries[.calories] ?? ScannedNutrientEntry(
                nutrient: .calories,
                amount: .exact(value: Double(clamped), unit: .kcal)
            )
            current.amount = .exact(value: Double(clamped), unit: .kcal)
            entries[.calories] = current
        }
    }

    /// Sets or inserts an exact numeric value for the specified nutrient and automatically updates its `% DV` state.
    mutating func setExactValue(
        _ value: Double,
        unit: NutrientUnit? = nil,
        for nutrient: CanonicalNutrientID,
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        isSupplement: Bool = false
    ) {
        let clamped = max(0.0, value)
        let resolvedUnit = unit ?? entries[nutrient]?.resolvedUnit ?? nutrient.primaryUnit

        if nutrient == .calories {
            self.calories = Int(clamped.rounded())
            return
        }

        let secondaryVal: Double?
        let secondaryUnit: NutrientUnit?
        if let existing = entries[nutrient],
           case .exact(_, _, let secV, let secU) = existing.amount {
            secondaryVal = secV
            secondaryUnit = secU
        } else {
            secondaryVal = nil
            secondaryUnit = nil
        }

        let newAmount: DeclaredNutrientAmount = (clamped == 0.0)
            ? .explicitZero(unit: resolvedUnit)
            : .exact(value: clamped, unit: resolvedUnit, secondaryValue: secondaryVal, secondaryUnit: secondaryUnit)

        let computedPctDV: DeclaredPercentDV
        if let (refVal, _) = FDARegulatoryConstants.dailyReferenceValue(for: nutrient, demographic: demographic),
           refVal > 0,
           !( !isSupplement && nutrient.omitsPercentDVOnConventionalFood ) {
            let pct = Int(((clamped / refVal) * 100.0).rounded())
            computedPctDV = .exact(pct)
        } else if isSupplement {
            computedPctDV = .notEstablished(symbol: "†")
        } else {
            computedPctDV = .omitted
        }

        if var existing = entries[nutrient] {
            existing.amount = newAmount
            existing.percentDV = computedPctDV
            existing.derivedFromPercentDVOnly = false
            entries[nutrient] = existing
        } else {
            entries[nutrient] = ScannedNutrientEntry(
                nutrient: nutrient,
                amount: newAmount,
                percentDV: computedPctDV,
                derivedFromPercentDVOnly: false
            )
        }
    }

    /// Removes a voluntary or false-positive nutrient row from the profile.
    mutating func removeNutrient(_ nutrient: CanonicalNutrientID) {
        entries.removeValue(forKey: nutrient)
    }

    // MARK: - Canonical FDA Ordering Helpers for Digital Label Rendering

    /// Complete ordered sequence of upper-tier macronutrients & electrolytes (including specific sugar alcohols).
    static let orderedUpperMacroSequence: [CanonicalNutrientID] = [
        .totalFat,
        .saturatedFat,
        .transFat,
        .polyunsaturatedFat,
        .monounsaturatedFat,
        .cholesterol,
        .sodium,
        .fluoride,
        .totalCarbohydrate,
        .dietaryFiber,
        .solubleFiber,
        .insolubleFiber,
        .totalSugars,
        .addedSugars,
        .sugarAlcohol,
        .erythritol,
        .xylitol,
        .maltitol,
        .sorbitol,
        .isomalt,
        .lactitol,
        .mannitol,
        .hydrogenatedStarchHydrolysates,
        .protein
    ]

    /// Ordered sequence of lower-tier vitamins and minerals for Conventional Food labels (`21 CFR § 101.9(c)(8)`).
    static let orderedConventionalMicronutrientSequence: [CanonicalNutrientID] = [
        .vitaminD,
        .calcium,
        .iron,
        .potassium,
        .vitaminA,
        .betaCarotenePercentage,
        .vitaminC,
        .vitaminE,
        .vitaminK,
        .thiamin,
        .riboflavin,
        .niacin,
        .vitaminB6,
        .folate,
        .folicAcid,
        .vitaminB12,
        .biotin,
        .pantothenicAcid,
        .phosphorus,
        .iodine,
        .magnesium,
        .zinc,
        .selenium,
        .copper,
        .manganese,
        .chromium,
        .molybdenum,
        .chloride,
        .choline
    ]

    /// Ordered sequence of all `(b)(2)` RDI/DRV nutrients for Supplement Facts panels (`21 CFR § 101.36(b)(2)(i)(B)`).
    static let orderedSupplementTier1Sequence: [CanonicalNutrientID] = [
        .calories,
        .caloriesFromSaturatedFat,
        .caloriesFromFat,
        .totalFat,
        .saturatedFat,
        .transFat,
        .polyunsaturatedFat,
        .monounsaturatedFat,
        .cholesterol,
        .totalCarbohydrate,
        .dietaryFiber,
        .solubleFiber,
        .insolubleFiber,
        .totalSugars,
        .addedSugars,
        .sugarAlcohol,
        .protein,
        .vitaminA,
        .betaCarotenePercentage,
        .vitaminC,
        .vitaminD,
        .vitaminE,
        .vitaminK,
        .thiamin,
        .riboflavin,
        .niacin,
        .vitaminB6,
        .folate,
        .folicAcid,
        .vitaminB12,
        .biotin,
        .pantothenicAcid,
        .choline,
        .calcium,
        .iron,
        .phosphorus,
        .iodine,
        .magnesium,
        .zinc,
        .selenium,
        .copper,
        .manganese,
        .chromium,
        .molybdenum,
        .chloride,
        .sodium,
        .potassium,
        .fluoride
    ]

    /// Returns the ordered upper-section macronutrient entries currently present in this profile.
    func orderedPresentMacroEntries() -> [ScannedNutrientEntry] {
        Self.orderedUpperMacroSequence.compactMap { entry(for: $0) }
    }

    /// Returns the ordered lower-section vitamin & mineral entries currently present in this profile.
    func orderedPresentMicronutrientEntries(isSupplement: Bool) -> [ScannedNutrientEntry] {
        let sequence = isSupplement ? Self.orderedSupplementTier1Sequence : Self.orderedConventionalMicronutrientSequence
        return sequence.compactMap { id in
            if isSupplement && (id == .calories || id == .caloriesFromSaturatedFat || id == .caloriesFromFat) {
                return nil
            }
            return entry(for: id)
        }
    }

    /// Returns all `CanonicalNutrientID`s that are not yet present in this profile, ordered by FDA sequence for the `"+ Add Nutrient Line"` picker.
    func unpopulatedNutrients(isSupplement: Bool) -> [CanonicalNutrientID] {
        let fullOrder: [CanonicalNutrientID]
        if isSupplement {
            fullOrder = Self.orderedSupplementTier1Sequence
        } else {
            fullOrder = [.calories, .caloriesFromSaturatedFat] + Self.orderedUpperMacroSequence + Self.orderedConventionalMicronutrientSequence
        }
        var seen = Set<CanonicalNutrientID>()
        var result: [CanonicalNutrientID] = []
        for id in fullOrder where seen.insert(id).inserted {
            if entry(for: id) == nil {
                result.append(id)
            }
        }
        return result
    }

    /// Count of populated nutrients beyond the 4 compact summary macros (`Calories`, `Total Fat`, `Total Carb`, `Protein`).
    var additionalPopulatedNutrientCount: Int {
        let summarySet: Set<CanonicalNutrientID> = [.calories, .totalFat, .totalCarbohydrate, .protein]
        let presentExtras = entries.values.filter { $0.isPresentOnLabel && !summarySet.contains($0.nutrient) }.count
        return presentExtras + supplementTier2Entries.count
    }

    // MARK: - Scaling & Aggregation Operators (Stage 2 Recipe & ConsumedItem Readiness)

    /// Returns a new `NutritionProfile` with every populated nutrient and tier-2 ingredient scaled by `ratio`.
    func scaled(by ratio: Double) -> NutritionProfile {
        let safeRatio = max(0.0, ratio)
        var scaledEntries: [CanonicalNutrientID: ScannedNutrientEntry] = [:]

        for (id, existing) in entries {
            var updated = existing
            let scaledVal = existing.resolvedValue * safeRatio
            let unit = existing.resolvedUnit
            if id == .calories || id == .caloriesFromSaturatedFat || id == .caloriesFromFat {
                updated.amount = .exact(value: Double(Int((scaledVal).rounded())), unit: .kcal)
            } else {
                updated.amount = scaledVal == 0.0
                    ? .explicitZero(unit: unit)
                    : .exact(value: scaledVal, unit: unit)
            }
            updated.derivedFromPercentDVOnly = false
            scaledEntries[id] = updated
        }

        let scaledTier2 = supplementTier2Entries.map { item -> ScannedNutrientEntry in
            var copy = item
            let val = item.resolvedValue * safeRatio
            copy.amount = .exact(value: val, unit: item.resolvedUnit)
            return copy
        }

        return NutritionProfile(entries: scaledEntries, supplementTier2Entries: scaledTier2)
    }

    /// Aggregates two `NutritionProfile` instances across all 58 canonical nutrients.
    static func + (lhs: NutritionProfile, rhs: NutritionProfile) -> NutritionProfile {
        var merged = lhs.entries

        for (id, rEntry) in rhs.entries where rEntry.isPresentOnLabel {
            if var lEntry = merged[id], lEntry.isPresentOnLabel {
                let sum = lEntry.resolvedValue + rEntry.resolvedValue
                let unit = lEntry.resolvedUnit
                if id == .calories || id == .caloriesFromSaturatedFat || id == .caloriesFromFat {
                    lEntry.amount = .exact(value: Double(Int(sum.rounded())), unit: .kcal)
                } else {
                    lEntry.amount = sum == 0.0 ? .explicitZero(unit: unit) : .exact(value: sum, unit: unit)
                }
                lEntry.derivedFromPercentDVOnly = false
                merged[id] = lEntry
            } else {
                merged[id] = rEntry
            }
        }

        return NutritionProfile(
            entries: merged,
            supplementTier2Entries: lhs.supplementTier2Entries + rhs.supplementTier2Entries
        )
    }

    // MARK: - Atwater 4-4-9 + Fiber + Sugar Alcohol Calorie Cross-Check

    /// Computes the expected FDA Atwater calorie range for this profile, accounting for `Total Fat`, `Protein`,
    /// `Total Carbohydrate`, `Dietary/Soluble/Insoluble Fiber`, and `Sugar Alcohol` (`21 CFR § 101.9(c)(1)(i)`).
    func expectedAtwaterCalorieRange(isSupplement: Bool = false) -> ClosedRange<Int> {
        var rowMap: [CanonicalNutrientID: ParsedNutrientRow] = [:]
        for (id, entry) in entries where entry.isPresentOnLabel {
            rowMap[id] = ParsedNutrientRow(
                nutrient: id,
                rawName: id.fdaLabelDisplayName,
                amount: entry.amount,
                percentDV: entry.percentDV,
                indentationLevel: id.indentationLevel,
                sourceCompoundDescription: entry.sourceCompoundDescription
            )
        }
        return FDANutritionValidator.evaluateAtwaterCalorieInvariants(
            nutrients: rowMap,
            isSupplement: isSupplement
        ).expectedRange
    }
}

// MARK: - 4. @Model final class ScannedFoodItem

@Model
final class ScannedFoodItem {
    var id: UUID = UUID()
    var timestamp: Date
    var brandName: String
    var name: String
    var processingLevel: String
    var category: String
    var foodVariationGroup: String?

    // Serving & Container Metadata
    var servingSize: Double
    var servingUnit: String
    var commonHouseholdMeasurement: String?
    var commonHouseholdMeasurementAmount: Double?
    var servingsPerContainer: Double?
    var servingsPerContainerModifier: String?
    var perDayMultiplier: Int?
    var columnHeaderTitle: String?

    // Regulatory & Layout Metadata
    var isSupplement: Bool
    var topologyRawValue: String
    var demographicGroupRawValue: String

    // Copy-on-Edit (Immutable Snapshot Versioning) Metadata
    var isArchived: Bool = false
    var previousVersionID: UUID? = nil
    var supersededByID: UUID? = nil

    // Full-Spectrum Encoded Nutrition Profile
    var nutritionProfileData: Data

    // Synchronized Summary Macros & Sub-Nutrients for Fast SwiftData Queries & Compact Rows
    var calories: Int
    var fat: Double
    var saturatedFat: Double
    var transFat: Double
    var polyunsaturatedFat: Double?
    var monounsaturatedFat: Double?
    var cholesterol: Double?
    var sodium: Double?
    var carb: Double
    var dietaryFiber: Double
    var solubleFiber: Double?
    var insolubleFiber: Double?
    var totalSugars: Double?
    var addedSugar: Double
    var sugarAlcohol: Double?
    var protein: Double

    @MainActor
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        brandName: String,
        name: String,
        processingLevel: String = "Processed",
        category: String = "Prepared Foods",
        foodVariationGroup: String? = nil,
        servingSize: Double,
        servingUnit: String = "g",
        commonHouseholdMeasurement: String? = nil,
        commonHouseholdMeasurementAmount: Double? = nil,
        servingsPerContainer: Double? = nil,
        servingsPerContainerModifier: String? = nil,
        perDayMultiplier: Int? = nil,
        columnHeaderTitle: String? = nil,
        isSupplement: Bool = false,
        topology: FDALabelTopology = .standardVertical,
        demographicGroup: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        isArchived: Bool = false,
        previousVersionID: UUID? = nil,
        supersededByID: UUID? = nil,
        nutrition: NutritionProfile
    ) {
        self.id = id
        self.timestamp = timestamp
        self.brandName = brandName
        self.name = name
        self.processingLevel = processingLevel
        self.category = category
        self.foodVariationGroup = foodVariationGroup
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.commonHouseholdMeasurement = commonHouseholdMeasurement
        self.commonHouseholdMeasurementAmount = commonHouseholdMeasurementAmount
        self.servingsPerContainer = servingsPerContainer
        self.servingsPerContainerModifier = servingsPerContainerModifier
        self.perDayMultiplier = perDayMultiplier
        self.columnHeaderTitle = columnHeaderTitle
        self.isSupplement = isSupplement
        self.topologyRawValue = topology.rawValue
        self.demographicGroupRawValue = demographicGroup.rawValue
        self.isArchived = isArchived
        self.previousVersionID = previousVersionID
        self.supersededByID = supersededByID

        self.nutritionProfileData = (try? JSONEncoder().encode(nutrition)) ?? Data()

        self.calories = nutrition.calories
        self.fat = nutrition.resolvedOrZero(for: .totalFat)
        self.saturatedFat = nutrition.resolvedOrZero(for: .saturatedFat)
        self.transFat = nutrition.resolvedOrZero(for: .transFat)
        self.polyunsaturatedFat = nutrition.value(for: .polyunsaturatedFat)
        self.monounsaturatedFat = nutrition.value(for: .monounsaturatedFat)
        self.cholesterol = nutrition.value(for: .cholesterol)
        self.sodium = nutrition.value(for: .sodium)
        self.carb = nutrition.resolvedOrZero(for: .totalCarbohydrate)
        self.dietaryFiber = nutrition.resolvedOrZero(for: .dietaryFiber)
        self.solubleFiber = nutrition.value(for: .solubleFiber)
        self.insolubleFiber = nutrition.value(for: .insolubleFiber)
        self.totalSugars = nutrition.value(for: .totalSugars)
        self.addedSugar = nutrition.resolvedOrZero(for: .addedSugars)
        self.sugarAlcohol = nutrition.value(for: .sugarAlcohol)
        self.protein = nutrition.resolvedOrZero(for: .protein)
    }

    // MARK: - Computed Domain Properties

    var topology: FDALabelTopology {
        get { FDALabelTopology(rawValue: topologyRawValue) ?? .standardVertical }
        set { topologyRawValue = newValue.rawValue }
    }

    var demographicGroup: FDADemographicGroup {
        get { FDADemographicGroup(rawValue: demographicGroupRawValue) ?? .adultsAndChildren4OrMoreYears }
        set { demographicGroupRawValue = newValue.rawValue }
    }

    @MainActor
    var nutrition: NutritionProfile {
        get {
            if !nutritionProfileData.isEmpty,
               let decoded = try? JSONDecoder().decode(NutritionProfile.self, from: nutritionProfileData) {
                return decoded
            }
            return NutritionProfile()
        }
        set {
            nutritionProfileData = (try? JSONEncoder().encode(newValue)) ?? Data()
            syncSummaryProperties(from: newValue)
        }
    }

    @MainActor
    func syncSummaryProperties(from profile: NutritionProfile) {
        self.calories = profile.calories
        self.fat = profile.resolvedOrZero(for: .totalFat)
        self.saturatedFat = profile.resolvedOrZero(for: .saturatedFat)
        self.transFat = profile.resolvedOrZero(for: .transFat)
        self.polyunsaturatedFat = profile.value(for: .polyunsaturatedFat)
        self.monounsaturatedFat = profile.value(for: .monounsaturatedFat)
        self.cholesterol = profile.value(for: .cholesterol)
        self.sodium = profile.value(for: .sodium)
        self.carb = profile.resolvedOrZero(for: .totalCarbohydrate)
        self.dietaryFiber = profile.resolvedOrZero(for: .dietaryFiber)
        self.solubleFiber = profile.value(for: .solubleFiber)
        self.insolubleFiber = profile.value(for: .insolubleFiber)
        self.totalSugars = profile.value(for: .totalSugars)
        self.addedSugar = profile.resolvedOrZero(for: .addedSugars)
        self.sugarAlcohol = profile.value(for: .sugarAlcohol)
        self.protein = profile.resolvedOrZero(for: .protein)
    }

    /// Validates that `commonHouseholdMeasurement` and `commonHouseholdMeasurementAmount` are either both valid or both `nil`.
    var hasValidHouseholdMeasurement: Bool {
        FoodItem.isValidHouseholdPair(
            name: commonHouseholdMeasurement,
            amount: commonHouseholdMeasurementAmount
        )
    }

    /// Formats the FDA serving size string (e.g., `"2/3 cup (55g)"` or `"55g"`).
    var formattedServingSizeHeader: String {
        let metricStr = "\(ScannedNutrientEntry.formatNumber(servingSize))\(servingUnit)"
        if let hhName = commonHouseholdMeasurement,
           !hhName.trimmingCharacters(in: .whitespaces).isEmpty,
           let hhAmt = commonHouseholdMeasurementAmount,
           hhAmt > 0 {
            return "\(ScannedNutrientEntry.formatNumber(hhAmt)) \(hhName) (\(metricStr))"
        }
        return metricStr
    }

    /// Formats the FDA servings per container string (e.g., `"About 9 servings per container"` or `"8 servings per container"`).
    var formattedServingsPerContainerHeader: String? {
        guard let spc = servingsPerContainer, spc > 0 else { return nil }
        let numStr = ScannedNutrientEntry.formatNumber(spc)
        if let mod = servingsPerContainerModifier, !mod.isEmpty {
            return "\(mod.capitalized) \(numStr) servings per container"
        }
        return "\(numStr) servings per container"
    }

    // MARK: - Copy-on-Edit (Immutable Snapshot Versioning)

    /// Creates a new `ScannedFoodItem` with a newly generated `UUID` containing the edited values,
    /// and soft-archives `self` (`isArchived = true`, `supersededByID = newItem.id`) so historical logs
    /// and un-updated recipes preserve their exact original nutrition values.
    @MainActor
    func createSupersedingVersion(
        brandName: String,
        name: String,
        processingLevel: String,
        category: String,
        foodVariationGroup: String?,
        servingSize: Double,
        servingUnit: String,
        commonHouseholdMeasurement: String?,
        commonHouseholdMeasurementAmount: Double?,
        servingsPerContainer: Double?,
        servingsPerContainerModifier: String?,
        perDayMultiplier: Int?,
        columnHeaderTitle: String?,
        isSupplement: Bool,
        topology: FDALabelTopology,
        demographicGroup: FDADemographicGroup,
        nutrition: NutritionProfile
    ) -> ScannedFoodItem {
        let newVersion = ScannedFoodItem(
            id: UUID(),
            timestamp: Date(),
            brandName: brandName,
            name: name,
            processingLevel: processingLevel,
            category: category,
            foodVariationGroup: foodVariationGroup,
            servingSize: servingSize,
            servingUnit: servingUnit,
            commonHouseholdMeasurement: commonHouseholdMeasurement,
            commonHouseholdMeasurementAmount: commonHouseholdMeasurementAmount,
            servingsPerContainer: servingsPerContainer,
            servingsPerContainerModifier: servingsPerContainerModifier,
            perDayMultiplier: perDayMultiplier,
            columnHeaderTitle: columnHeaderTitle,
            isSupplement: isSupplement,
            topology: topology,
            demographicGroup: demographicGroup,
            isArchived: false,
            previousVersionID: self.id,
            supersededByID: nil,
            nutrition: nutrition
        )

        self.isArchived = true
        self.supersededByID = newVersion.id
        return newVersion
    }

    /// Applies an in-place mutation (`"Typo Fix (Affects Recipes and Historical Logs)"`) without changing `self.id`.
    @MainActor
    func applyInPlaceUpdate(
        brandName: String,
        name: String,
        processingLevel: String,
        category: String,
        foodVariationGroup: String?,
        servingSize: Double,
        servingUnit: String,
        commonHouseholdMeasurement: String?,
        commonHouseholdMeasurementAmount: Double?,
        servingsPerContainer: Double?,
        servingsPerContainerModifier: String?,
        perDayMultiplier: Int?,
        columnHeaderTitle: String?,
        isSupplement: Bool,
        topology: FDALabelTopology,
        demographicGroup: FDADemographicGroup,
        nutrition: NutritionProfile
    ) {
        self.brandName = brandName
        self.name = name
        self.processingLevel = processingLevel
        self.category = category
        self.foodVariationGroup = foodVariationGroup
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.commonHouseholdMeasurement = commonHouseholdMeasurement
        self.commonHouseholdMeasurementAmount = commonHouseholdMeasurementAmount
        self.servingsPerContainer = servingsPerContainer
        self.servingsPerContainerModifier = servingsPerContainerModifier
        self.perDayMultiplier = perDayMultiplier
        self.columnHeaderTitle = columnHeaderTitle
        self.isSupplement = isSupplement
        self.topology = topology
        self.demographicGroup = demographicGroup
        self.nutrition = nutrition
    }
}
