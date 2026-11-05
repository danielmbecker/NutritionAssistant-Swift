import Foundation

// MARK: - 1. Demographic Reference Value Container

/// Holds the established Daily Reference Value (DRV) or Reference Daily Intake (RDI) across all 4 FDA demographic groups (`21 CFR § 101.9(c)(8)(iv)` & `(c)(9)`).
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
    ) {
        self.unit = unit
        self.adultsAndChildren4OrMoreYears = adultsAndChildren4OrMoreYears
        self.infantsThrough12Months = infantsThrough12Months
        self.children1Through3Years = children1Through3Years
        self.pregnantAndLactatingWomen = pregnantAndLactatingWomen
    }

    /// Returns the reference value for the specified demographic group, or `nil` if no DRV/RDI is established for that group (e.g., Saturated Fat for infants).
    func value(for demographic: FDADemographicGroup) -> Double? {
        switch demographic {
        case .adultsAndChildren4OrMoreYears:
            return adultsAndChildren4OrMoreYears
        case .infantsThrough12Months:
            return infantsThrough12Months
        case .children1Through3Years:
            return children1Through3Years
        case .pregnantAndLactatingWomen:
            return pregnantAndLactatingWomen
        }
    }
}

// MARK: - 2. Exhaustive FDA Regulatory Constants (21 CFR § 101.9 & § 101.36)

/// Central repository of FDA Daily Reference Values (DRVs), Reference Daily Intakes (RDIs), biochemical conversions, Atwater caloric factors, household metric conversions, and 21 CFR § 101.9(c) rounding interval rules.
enum FDARegulatoryConstants {

    // MARK: 2.1 Daily Reference Values (DRVs) — 21 CFR § 101.9(c)(9) & (c)(7)(iii)

    /// Complete DRV lookup table across all 4 demographic groups.
    static let drvTable: [CanonicalNutrientID: FDADemographicReferenceValues] = [
        .totalFat: FDADemographicReferenceValues(
            unit: .g,
            adultsAndChildren4OrMoreYears: 78.0,
            infantsThrough12Months: 30.0,
            children1Through3Years: 39.0,
            pregnantAndLactatingWomen: 78.0
        ),
        .saturatedFat: FDADemographicReferenceValues(
            unit: .g,
            adultsAndChildren4OrMoreYears: 20.0,
            infantsThrough12Months: nil,
            children1Through3Years: 10.0,
            pregnantAndLactatingWomen: 20.0
        ),
        .cholesterol: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 300.0,
            infantsThrough12Months: nil,
            children1Through3Years: 300.0,
            pregnantAndLactatingWomen: 300.0
        ),
        .totalCarbohydrate: FDADemographicReferenceValues(
            unit: .g,
            adultsAndChildren4OrMoreYears: 275.0,
            infantsThrough12Months: 95.0,
            children1Through3Years: 150.0,
            pregnantAndLactatingWomen: 275.0
        ),
        .sodium: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 2300.0,
            infantsThrough12Months: nil,
            children1Through3Years: 1500.0,
            pregnantAndLactatingWomen: 2300.0
        ),
        .dietaryFiber: FDADemographicReferenceValues(
            unit: .g,
            adultsAndChildren4OrMoreYears: 28.0,
            infantsThrough12Months: nil,
            children1Through3Years: 14.0,
            pregnantAndLactatingWomen: 28.0
        ),
        .addedSugars: FDADemographicReferenceValues(
            unit: .g,
            adultsAndChildren4OrMoreYears: 50.0,
            infantsThrough12Months: nil,
            children1Through3Years: 25.0,
            pregnantAndLactatingWomen: 50.0
        ),
        .protein: FDADemographicReferenceValues(
            unit: .g,
            adultsAndChildren4OrMoreYears: 50.0,
            infantsThrough12Months: 11.0,
            children1Through3Years: 13.0,
            pregnantAndLactatingWomen: 71.0
        )
    ]

    // MARK: 2.2 Reference Daily Intakes (RDIs) for All 27 Vitamins & Minerals — 21 CFR § 101.9(c)(8)(iv)

    /// Complete 27-nutrient RDI lookup table across all 4 demographic groups.
    static let rdiTable: [CanonicalNutrientID: FDADemographicReferenceValues] = [
        .vitaminD: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 20.0,
            infantsThrough12Months: 10.0,
            children1Through3Years: 15.0,
            pregnantAndLactatingWomen: 15.0
        ),
        .calcium: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 1300.0,
            infantsThrough12Months: 260.0,
            children1Through3Years: 700.0,
            pregnantAndLactatingWomen: 1300.0
        ),
        .iron: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 18.0,
            infantsThrough12Months: 11.0,
            children1Through3Years: 7.0,
            pregnantAndLactatingWomen: 27.0
        ),
        .potassium: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 4700.0,
            infantsThrough12Months: 700.0,
            children1Through3Years: 3000.0,
            pregnantAndLactatingWomen: 5100.0
        ),
        .vitaminA: FDADemographicReferenceValues(
            unit: .mcgRAE,
            adultsAndChildren4OrMoreYears: 900.0,
            infantsThrough12Months: 500.0,
            children1Through3Years: 300.0,
            pregnantAndLactatingWomen: 1300.0
        ),
        .vitaminC: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 90.0,
            infantsThrough12Months: 50.0,
            children1Through3Years: 15.0,
            pregnantAndLactatingWomen: 120.0
        ),
        .vitaminE: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 15.0,
            infantsThrough12Months: 5.0,
            children1Through3Years: 6.0,
            pregnantAndLactatingWomen: 19.0
        ),
        .vitaminK: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 120.0,
            infantsThrough12Months: 2.5,
            children1Through3Years: 30.0,
            pregnantAndLactatingWomen: 90.0
        ),
        .thiamin: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 1.2,
            infantsThrough12Months: 0.3,
            children1Through3Years: 0.5,
            pregnantAndLactatingWomen: 1.4
        ),
        .riboflavin: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 1.3,
            infantsThrough12Months: 0.4,
            children1Through3Years: 0.5,
            pregnantAndLactatingWomen: 1.6
        ),
        .niacin: FDADemographicReferenceValues(
            unit: .mgNE,
            adultsAndChildren4OrMoreYears: 16.0,
            infantsThrough12Months: 4.0,
            children1Through3Years: 6.0,
            pregnantAndLactatingWomen: 18.0
        ),
        .vitaminB6: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 1.7,
            infantsThrough12Months: 0.3,
            children1Through3Years: 0.5,
            pregnantAndLactatingWomen: 2.0
        ),
        .folate: FDADemographicReferenceValues(
            unit: .mcgDFE,
            adultsAndChildren4OrMoreYears: 400.0,
            infantsThrough12Months: 80.0,
            children1Through3Years: 150.0,
            pregnantAndLactatingWomen: 600.0
        ),
        .vitaminB12: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 2.4,
            infantsThrough12Months: 0.5,
            children1Through3Years: 0.9,
            pregnantAndLactatingWomen: 2.8
        ),
        .biotin: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 30.0,
            infantsThrough12Months: 6.0,
            children1Through3Years: 8.0,
            pregnantAndLactatingWomen: 35.0
        ),
        .pantothenicAcid: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 5.0,
            infantsThrough12Months: 1.8,
            children1Through3Years: 2.0,
            pregnantAndLactatingWomen: 7.0
        ),
        .phosphorus: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 1250.0,
            infantsThrough12Months: 275.0,
            children1Through3Years: 460.0,
            pregnantAndLactatingWomen: 1250.0
        ),
        .iodine: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 150.0,
            infantsThrough12Months: 130.0,
            children1Through3Years: 90.0,
            pregnantAndLactatingWomen: 290.0
        ),
        .magnesium: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 420.0,
            infantsThrough12Months: 75.0,
            children1Through3Years: 80.0,
            pregnantAndLactatingWomen: 400.0
        ),
        .zinc: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 11.0,
            infantsThrough12Months: 3.0,
            children1Through3Years: 3.0,
            pregnantAndLactatingWomen: 13.0
        ),
        .selenium: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 55.0,
            infantsThrough12Months: 20.0,
            children1Through3Years: 20.0,
            pregnantAndLactatingWomen: 70.0
        ),
        .copper: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 0.9,
            infantsThrough12Months: 0.2,
            children1Through3Years: 0.3,
            pregnantAndLactatingWomen: 1.3
        ),
        .manganese: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 2.3,
            infantsThrough12Months: 0.6,
            children1Through3Years: 1.2,
            pregnantAndLactatingWomen: 2.6
        ),
        .chromium: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 35.0,
            infantsThrough12Months: 5.5,
            children1Through3Years: 11.0,
            pregnantAndLactatingWomen: 45.0
        ),
        .molybdenum: FDADemographicReferenceValues(
            unit: .mcg,
            adultsAndChildren4OrMoreYears: 45.0,
            infantsThrough12Months: 3.0,
            children1Through3Years: 17.0,
            pregnantAndLactatingWomen: 50.0
        ),
        .chloride: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 2300.0,
            infantsThrough12Months: 570.0,
            children1Through3Years: 1500.0,
            pregnantAndLactatingWomen: 2300.0
        ),
        .choline: FDADemographicReferenceValues(
            unit: .mg,
            adultsAndChildren4OrMoreYears: 550.0,
            infantsThrough12Months: 150.0,
            children1Through3Years: 200.0,
            pregnantAndLactatingWomen: 550.0
        )
    ]

    /// Nutrients prohibited from declaring a `% Daily Value` on infant (`<= 12 months`) panels (`21 CFR § 101.9(j)(5)(i)`).
    static let infantProhibitedPercentDVNutrients: Set<CanonicalNutrientID> = [
        .saturatedFat,
        .transFat,
        .cholesterol,
        .sodium,
        .dietaryFiber,
        .totalSugars,
        .addedSugars
    ]

    /// Nutrients on a `Supplement Facts` panel permitted to calculate `% DV` from either the rounded declared label amount or the unrounded amount (`21 CFR § 101.36(b)(2)(iii)(B)`). All other supplement nutrients must use the unrounded amount.
    static let supplementNutrientsAllowingRoundedPercentDVBasis: Set<CanonicalNutrientID> = [
        .totalFat,
        .saturatedFat,
        .cholesterol,
        .sodium,
        .potassium,
        .totalCarbohydrate,
        .dietaryFiber
    ]

    /// Looks up the established DRV or RDI value and canonical unit for a given nutrient and demographic group.
    static func dailyReferenceValue(
        for nutrient: CanonicalNutrientID,
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears
    ) -> (value: Double, unit: NutrientUnit)? {
        if let drv = drvTable[nutrient], let value = drv.value(for: demographic) {
            return (value, drv.unit)
        }
        if let rdi = rdiTable[nutrient], let value = rdi.value(for: demographic) {
            return (value, rdi.unit)
        }
        return nil
    }

    // MARK: 2.3 Biochemical Equivalence & Unit Conversions — 21 CFR § 101.9(c)(8)(iv) Footnotes 3–7

    /// Biochemical equivalence constants for vitamins and energy.
    enum BiochemicalConversion {
        // Vitamin A (Retinol Activity Equivalents — mcg RAE)
        static let mcgRetinolPerMcgRAE: Double = 1.0
        static let mcgSupplementalBetaCarotenePerMcgRAE: Double = 2.0
        static let mcgDietaryBetaCarotenePerMcgRAE: Double = 12.0
        static let mcgDietaryAlphaCarotenePerMcgRAE: Double = 24.0
        static let mcgDietaryBetaCryptoxanthinPerMcgRAE: Double = 24.0
        static let vitaminAIUPerMcgRetinol: Double = 3.3333333333333335

        // Vitamin D (Cholecalciferol / Ergocalciferol)
        static let vitaminDIUPerMcg: Double = 40.0
        static let vitaminDMcgPerIU: Double = 0.025

        // Vitamin E (Alpha-Tocopherol)
        static let mgRRRAlphaTocopherolPerMgLabelClaim: Double = 1.0
        static let mgAllRacAlphaTocopherolPerMgLabelClaim: Double = 2.0
        static let vitaminEMgNaturalPerIU: Double = 0.67
        static let vitaminEMgSyntheticPerIU: Double = 0.45

        // Niacin (Niacin Equivalents — mg NE)
        static let mgNiacinPerMgNE: Double = 1.0
        static let mgTryptophanPerMgNE: Double = 60.0

        // Folate (Dietary Folate Equivalents — mcg DFE)
        static let mcgFoodFolatePerMcgDFE: Double = 1.0
        static let mcgFolicAcidPerMcgDFE: Double = 0.6
        static let mcgDFEPerMcgFolicAcid: Double = 1.6666666666666667

        // Energy
        static let kilojoulesPerKilocalorie: Double = 4.184
    }

    /// Converts a scanned nutrient quantity into the canonical unit used by `drvTable` / `rdiTable` for `% DV` math.
    static func convertToPrimaryReferenceUnit(
        value: Double,
        fromUnit: NutrientUnit,
        for nutrient: CanonicalNutrientID
    ) -> Double {
        let targetUnit = nutrient.primaryUnit
        if fromUnit == targetUnit {
            return value
        }
        switch (nutrient, fromUnit, targetUnit) {
        case (.vitaminD, .iu, .mcg):
            return value * BiochemicalConversion.vitaminDMcgPerIU
        case (.vitaminA, .mcg, .mcgRAE):
            return value
        case (.vitaminA, .iu, .mcgRAE):
            return value / BiochemicalConversion.vitaminAIUPerMcgRetinol
        case (.vitaminE, .iu, .mg):
            return value * BiochemicalConversion.vitaminEMgNaturalPerIU
        case (.niacin, .mg, .mgNE):
            return value
        case (.folate, .mcg, .mcgDFE):
            return value
        case (.folicAcid, .mcg, .mcg):
            return value
        case (.calories, .kJ, .kcal), (.caloriesFromSaturatedFat, .kJ, .kcal), (.caloriesFromFat, .kJ, .kcal):
            return value / BiochemicalConversion.kilojoulesPerKilocalorie
        case (_, .mg, .g):
            return value / 1000.0
        case (_, .mcg, .mg):
            return value / 1000.0
        case (_, .g, .mg):
            return value * 1000.0
        case (_, .mg, .mcg):
            return value * 1000.0
        default:
            return value
        }
    }

    // MARK: 2.4 Atwater 4-4-9 & Sugar Alcohol Caloric Factors — 21 CFR § 101.9(c)(1)(i)

    /// Standard Atwater general factors and non-digestible carbohydrate adjustments (`21 CFR § 101.9(c)(1)(i)`).
    enum CaloricFactors {
        static let proteinKcalPerGram: Double = 4.0
        static let totalCarbohydrateKcalPerGram: Double = 4.0
        static let totalFatKcalPerGram: Double = 9.0
        static let solubleNonDigestibleCarbohydrateKcalPerGram: Double = 2.0
        static let insolubleFiberKcalPerGram: Double = 0.0
        static let alluloseKcalPerGram: Double = 0.4

        /// Specific sugar alcohol caloric factors in `kcal/g` (`21 CFR § 101.9(c)(1)(i)(F)`).
        static let sugarAlcoholKcalPerGram: [CanonicalNutrientID: Double] = [
            .isomalt: 2.0,
            .lactitol: 2.0,
            .xylitol: 2.4,
            .maltitol: 2.1,
            .sorbitol: 2.6,
            .hydrogenatedStarchHydrolysates: 3.0,
            .mannitol: 1.6,
            .erythritol: 0.0
        ]

        /// Legal range of caloric factors (`0.0...3.0 kcal/g`) when generic `"Sugar alcohol"` is declared without naming the specific polyol.
        static let genericSugarAlcoholKcalPerGramRange: ClosedRange<Double> = 0.0...3.0
    }

    // MARK: 2.5 Standard Household-to-Metric Conversions — 21 CFR § 101.9(b)(5)(viii)

    /// Standard FDA volumetric conversions in milliliters (`mL`) per 1 household unit (`§ 101.9(b)(5)(viii)`).
    static let householdVolumeToMilliliters: [String: Double] = [
        "tsp": 5.0,
        "teaspoon": 5.0,
        "teaspoons": 5.0,
        "teaspoonful": 5.0,
        "teaspoonfuls": 5.0,
        "tbsp": 15.0,
        "tbs": 15.0,
        "tbl": 15.0,
        "tablespoon": 15.0,
        "tablespoons": 15.0,
        "tablespoonful": 15.0,
        "tablespoonfuls": 15.0,
        "fl oz": 30.0,
        "fl. oz.": 30.0,
        "fl. oz": 30.0,
        "fl oz.": 30.0,
        "fluid oz": 30.0,
        "fluid ounce": 30.0,
        "fluid ounces": 30.0,
        "cup": 240.0,
        "cups": 240.0,
        "pt": 480.0,
        "pint": 480.0,
        "pints": 480.0,
        "qt": 960.0,
        "quart": 960.0,
        "quarts": 960.0,
        "gal": 3840.0,
        "gallon": 3840.0,
        "gallons": 3840.0,
        "ml": 1.0,
        "milliliter": 1.0,
        "milliliters": 1.0,
        "l": 1000.0,
        "liter": 1000.0,
        "liters": 1000.0
    ]

    /// Standard FDA avoirdupois weight conversions in grams (`g`) per 1 household unit (`§ 101.9(b)(5)(viii)`).
    static let householdWeightToGrams: [String: Double] = [
        "oz": 28.0,
        "oz.": 28.0,
        "ounce": 28.0,
        "ounces": 28.0,
        "oz wt": 28.0,
        "lb": 454.0,
        "lb.": 454.0,
        "lbs": 454.0,
        "pound": 454.0,
        "pounds": 454.0,
        "g": 1.0,
        "gram": 1.0,
        "grams": 1.0
    ]

    /// Computes the standard FDA metric weight (`"g"`) or volume (`"ml"`) when a single-serving container omits the parenthetical metric measure (`§ 101.9(b)(7)(i)`).
    static func metricEquivalent(forHouseholdUnit rawUnit: String, amount: Double) -> (metricAmount: Double, metricUnit: String)? {
        let key = rawUnit
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        if let mlPerUnit = householdVolumeToMilliliters[key] {
            return (roundServingMetricQuantity(amount * mlPerUnit), "ml")
        }
        if let gPerUnit = householdWeightToGrams[key] {
            return (roundServingMetricQuantity(amount * gPerUnit), "g")
        }
        return nil
    }

    // MARK: 2.6 Programmatic 21 CFR § 101.9(c) Rounding Rules & Legal Interval Calculators

    /// Rounds a serving size metric weight or volume (`g` or `mL`) according to `21 CFR § 101.9(b)(7)(ii)`:
    /// - `< 2 g/mL`: rounded to nearest `0.1 g/mL`
    /// - `2..<5 g/mL`: rounded to nearest `0.5 g/mL`
    /// - `>= 5 g/mL`: rounded to nearest whole number (`1.0 g/mL`)
    static func roundServingMetricQuantity(_ quantity: Double) -> Double {
        guard quantity > 0 else { return 0.0 }
        if quantity < 2.0 {
            return (quantity * 10.0).rounded() / 10.0
        } else if quantity < 5.0 {
            return (quantity * 2.0).rounded() / 2.0
        } else {
            return quantity.rounded()
        }
    }

    /// Computes the exact legal unrounded interval `[minActual, maxActual]` that could have produced the printed `DeclaredNutrientAmount` under `21 CFR § 101.9(c)` and `§ 101.36(b)(2)`.
    static func legalActualInterval(
        for nutrient: CanonicalNutrientID,
        declared: DeclaredNutrientAmount,
        isSupplement: Bool = false
    ) -> ClosedRange<Double>? {
        switch declared {
        case .omitted:
            return 0.0...maxZeroThreshold(for: nutrient)

        case .insignificantFootnote:
            return 0.0...maxInsignificantThreshold(for: nutrient)

        case .explicitZero:
            return 0.0...maxZeroThreshold(for: nutrient)

        case .threshold(let kind, _):
            switch kind {
            case .lessThanFiveCalories:
                return 0.0...5.0
            case .lessThanHalfGram:
                return 0.0...0.5
            case .lessThanOneGram:
                return 0.5...1.0
            case .lessThanFiveMilligrams:
                if nutrient == .cholesterol {
                    return 2.0...5.0
                } else {
                    return 0.0...5.0
                }
            case .lessThanOnePercentDV, .lessThanTwoPercentDV:
                return 0.0...1.0
            }

        case .exact(let rawValue, let unit, _, _):
            let value = convertToPrimaryReferenceUnit(value: rawValue, fromUnit: unit, for: nutrient)
            if value == 0.0 {
                return 0.0...maxZeroThreshold(for: nutrient)
            }
            let halfStep = roundingHalfStepTolerance(for: nutrient, declaredValue: value, isSupplement: isSupplement)
            return max(0.0, value - halfStep)...(value + halfStep)
        }
    }

    /// Returns the half-step rounding tolerance (`±halfStep`) for a given nutrient and declared non-zero value under `21 CFR § 101.9(c)`.
    static func roundingHalfStepTolerance(
        for nutrient: CanonicalNutrientID,
        declaredValue: Double,
        isSupplement: Bool = false
    ) -> Double {
        switch nutrient {
        case .calories, .caloriesFromSaturatedFat, .caloriesFromFat:
            // § 101.9(c)(1): <= 50 cal -> nearest 5 cal (±2.5); > 50 cal -> nearest 10 cal (±5.0)
            return declaredValue <= 50.0 ? 2.5 : 5.0

        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat:
            // § 101.9(c)(2): < 5g -> nearest 0.5g (±0.25); >= 5g -> nearest 1g (±0.5)
            return declaredValue < 5.0 ? 0.25 : 0.5

        case .cholesterol:
            // § 101.9(c)(3): nearest 5 mg (±2.5)
            return 2.5

        case .sodium:
            // § 101.9(c)(4): 5..140 mg -> nearest 5 mg (±2.5); > 140 mg -> nearest 10 mg (±5.0)
            return declaredValue <= 140.0 ? 2.5 : 5.0

        case .fluoride:
            // § 101.9(c)(5): <= 0.8 mg -> nearest 0.1 mg (±0.05); > 0.8 mg -> nearest 0.2 mg (±0.1)
            return declaredValue <= 0.8 ? 0.05 : 0.1

        case .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
             .totalSugars, .addedSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol,
             .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .protein:
            // § 101.9(c)(6)–(7): >= 1g -> nearest 1g (±0.5)
            return 0.5

        default:
            // Vitamins, minerals, and supplement ingredients: infer precision from decimal representation (or ±5% of declared value / half of last significant digit)
            return micronutrientWeightHalfStep(for: declaredValue, isSupplement: isSupplement)
        }
    }

    /// Rounds an unrounded actual quantity to its canonical `DeclaredNutrientAmount` representation under `21 CFR § 101.9(c)`.
    static func roundToFDADeclared(
        nutrient: CanonicalNutrientID,
        actualValue: Double
    ) -> DeclaredNutrientAmount {
        let clamped = max(0.0, actualValue)
        let unit = nutrient.primaryUnit

        switch nutrient {
        case .calories, .caloriesFromSaturatedFat, .caloriesFromFat:
            if clamped < 5.0 {
                return .explicitZero(unit: .kcal)
            } else if clamped <= 50.0 {
                let rounded = (clamped / 5.0).rounded() * 5.0
                return .exact(value: rounded, unit: .kcal)
            } else {
                let rounded = (clamped / 10.0).rounded() * 10.0
                return .exact(value: rounded, unit: .kcal)
            }

        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat:
            if clamped < 0.5 {
                return .explicitZero(unit: .g)
            } else if clamped < 5.0 {
                let rounded = (clamped * 2.0).rounded() / 2.0
                return .exact(value: rounded, unit: .g)
            } else {
                return .exact(value: clamped.rounded(), unit: .g)
            }

        case .cholesterol:
            if clamped < 2.0 {
                return .explicitZero(unit: .mg)
            } else if clamped < 5.0 {
                return .threshold(.lessThanFiveMilligrams, unit: .mg)
            } else {
                let rounded = (clamped / 5.0).rounded() * 5.0
                return .exact(value: rounded, unit: .mg)
            }

        case .sodium:
            if clamped < 5.0 {
                return .explicitZero(unit: .mg)
            } else if clamped <= 140.0 {
                let rounded = (clamped / 5.0).rounded() * 5.0
                return .exact(value: rounded, unit: .mg)
            } else {
                let rounded = (clamped / 10.0).rounded() * 10.0
                return .exact(value: rounded, unit: .mg)
            }

        case .fluoride:
            if clamped < 0.1 {
                return .explicitZero(unit: .mg)
            } else if clamped <= 0.8 {
                let rounded = (clamped * 10.0).rounded() / 10.0
                return .exact(value: rounded, unit: .mg)
            } else {
                let rounded = (clamped * 5.0).rounded() / 5.0
                return .exact(value: rounded, unit: .mg)
            }

        case .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
             .totalSugars, .addedSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol,
             .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .protein:
            if clamped < 0.5 {
                return .explicitZero(unit: .g)
            } else if clamped < 1.0 {
                return .threshold(.lessThanOneGram, unit: .g)
            } else {
                return .exact(value: clamped.rounded(), unit: .g)
            }

        default:
            if clamped == 0.0 {
                return .explicitZero(unit: unit)
            }
            return .exact(value: clamped, unit: unit)
        }
    }

    // MARK: 2.7 % Daily Value Cross-Validation Intervals — 21 CFR § 101.9(c)(8)(iii), (d)(7)(ii) & § 101.36(b)(2)(iii)(B)

    /// Computes the legal `[minPercentDV, maxPercentDV]` range for a declared nutrient weight, accounting for both unrounded and rounded calculation bases (`§ 101.9(d)(7)(ii)` vs. `§ 101.36(b)(2)(iii)(B)`) and micronutrient `2%/5%/10%` rounding increments (`§ 101.9(c)(8)(iii)`).
    static func legalPercentDVInterval(
        for nutrient: CanonicalNutrientID,
        declaredAmount: DeclaredNutrientAmount,
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        isSupplement: Bool = false
    ) -> ClosedRange<Double>? {
        guard let (referenceValue, _) = dailyReferenceValue(for: nutrient, demographic: demographic),
              referenceValue > 0,
              let actualInterval = legalActualInterval(for: nutrient, declared: declaredAmount, isSupplement: isSupplement) else {
            return nil
        }

        // Unrounded basis percentage interval
        let minUnroundedPct = (actualInterval.lowerBound / referenceValue) * 100.0
        let maxUnroundedPct = (actualInterval.upperBound / referenceValue) * 100.0

        // Rounded declared basis percentage (permitted on all Nutrition Facts rows under § 101.9(d)(7)(ii), and on the 7 specified DRV rows on Supplement Facts under § 101.36(b)(2)(iii)(B))
        let allowsRoundedBasis = !isSupplement || supplementNutrientsAllowingRoundedPercentDVBasis.contains(nutrient)
        let declaredVal: Double
        if case .exact(let rawVal, let unit, _, _) = declaredAmount {
            declaredVal = convertToPrimaryReferenceUnit(value: rawVal, fromUnit: unit, for: nutrient)
        } else {
            declaredVal = declaredAmount.resolvedValue(for: nutrient)
        }
        let declaredPct = (declaredVal / referenceValue) * 100.0

        let rawMinPct = allowsRoundedBasis ? min(minUnroundedPct, declaredPct) : minUnroundedPct
        let rawMaxPct = allowsRoundedBasis ? max(maxUnroundedPct, declaredPct) : maxUnroundedPct

        // Expand by legal % DV rounding increment tolerance
        let lowStep = percentDVRoundingHalfStep(for: nutrient, percent: rawMinPct, isSupplement: isSupplement)
        let highStep = percentDVRoundingHalfStep(for: nutrient, percent: rawMaxPct, isSupplement: isSupplement)

        // Include ±1.0% regulatory rounding buffer as specified in Part 1.5
        let lowerBound = max(0.0, (rawMinPct - lowStep - 1.0).rounded(.down))
        let upperBound = (rawMaxPct + highStep + 1.0).rounded(.up)
        return lowerBound...upperBound
    }

    /// Computes the legal unrounded nutrient weight interval `[minWeight, maxWeight]` implied by a scanned `DeclaredPercentDV` value.
    static func legalUnroundedIntervalFromPercentDV(
        for nutrient: CanonicalNutrientID,
        declaredPercentDV: DeclaredPercentDV,
        demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        isSupplement: Bool = false
    ) -> ClosedRange<Double>? {
        guard let (referenceValue, _) = dailyReferenceValue(for: nutrient, demographic: demographic),
              referenceValue > 0 else {
            return nil
        }

        let pctInterval: ClosedRange<Double>
        switch declaredPercentDV {
        case .omitted, .notEstablished:
            return nil
        case .threshold(let kind):
            switch kind {
            case .lessThanOnePercentDV:
                pctInterval = 0.0...1.0
            case .lessThanTwoPercentDV:
                pctInterval = 0.0...2.0
            default:
                pctInterval = 0.0...1.0
            }
        case .exact(let pct):
            let p = Double(pct)
            let halfStep = percentDVRoundingHalfStep(for: nutrient, percent: p, isSupplement: isSupplement)
            let minP = max(0.0, p - halfStep - 1.0)
            let maxP = p + halfStep + 1.0
            pctInterval = minP...maxP
        }

        let minWeightFromUnrounded = (pctInterval.lowerBound / 100.0) * referenceValue
        let maxWeightFromUnrounded = (pctInterval.upperBound / 100.0) * referenceValue

        // Also account for the fact that the declared weight itself is rounded under § 101.9(c)
        let lowWeightStep = roundingHalfStepTolerance(for: nutrient, declaredValue: minWeightFromUnrounded, isSupplement: isSupplement)
        let highWeightStep = roundingHalfStepTolerance(for: nutrient, declaredValue: maxWeightFromUnrounded, isSupplement: isSupplement)

        return max(0.0, minWeightFromUnrounded - lowWeightStep)...(maxWeightFromUnrounded + highWeightStep)
    }

    /// Returns the `% DV` rounding half-step (`±halfStep`) for a given nutrient and percentage value:
    /// - Conventional Micronutrients (`§ 101.9(c)(8)(iii)`): `<= 10%` -> `2%` steps (`±1.0%`), `>10%..50%` -> `5%` steps (`±2.5%`), `>50%` -> `10%` steps (`±5.0%`).
    /// - Macronutrients & Supplement Facts (`§ 101.9(d)(7)(ii)` & `§ 101.36(b)(2)(iii)(C)`): nearest whole percent (`1%` steps -> `±0.5%`).
    static func percentDVRoundingHalfStep(
        for nutrient: CanonicalNutrientID,
        percent: Double,
        isSupplement: Bool = false
    ) -> Double {
        if !isSupplement && nutrient.isMicronutrientRDI {
            if percent < 2.0 {
                return 2.0
            } else if percent <= 10.0 {
                return 1.0
            } else if percent <= 50.0 {
                return 2.5
            } else {
                return 5.0
            }
        }
        return 0.5
    }

    // MARK: - Private Interval Helpers

    private static func maxZeroThreshold(for nutrient: CanonicalNutrientID) -> Double {
        switch nutrient {
        case .calories, .caloriesFromSaturatedFat, .caloriesFromFat:
            return 5.0
        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat,
             .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
             .totalSugars, .addedSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol,
             .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .protein:
            return 0.5
        case .cholesterol:
            return 2.0
        case .sodium:
            return 5.0
        case .fluoride:
            return 0.1
        default:
            if let (rdi, _) = dailyReferenceValue(for: nutrient, demographic: .adultsAndChildren4OrMoreYears) {
                return rdi * 0.02
            }
            return 0.05
        }
    }

    private static func maxInsignificantThreshold(for nutrient: CanonicalNutrientID) -> Double {
        switch nutrient {
        case .dietaryFiber, .solubleFiber, .insolubleFiber, .totalSugars, .addedSugars, .protein:
            return 1.0
        case .cholesterol:
            return 2.0
        case .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat, .totalFat:
            return 0.5
        default:
            if let (rdi, _) = dailyReferenceValue(for: nutrient, demographic: .adultsAndChildren4OrMoreYears) {
                return rdi * 0.02
            }
            return 0.5
        }
    }

    private static func micronutrientWeightHalfStep(for declaredValue: Double, isSupplement: Bool) -> Double {
        let absVal = abs(declaredValue)
        if absVal == 0.0 {
            return 0.05
        }
        let formatted = String(format: "%.4f", absVal)
        let trimmed = formatted.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        if let dotIndex = trimmed.firstIndex(of: ".") {
            let decimals = trimmed.distance(from: trimmed.index(after: dotIndex), to: trimmed.endIndex)
            if decimals > 0 {
                return 0.5 * pow(10.0, -Double(decimals))
            }
        }
        if isSupplement {
            return max(0.05, absVal * 0.02)
        }
        return max(0.5, absVal * 0.05)
    }
}
