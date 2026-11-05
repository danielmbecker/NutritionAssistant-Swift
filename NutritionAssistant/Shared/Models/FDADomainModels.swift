import Foundation

// MARK: - 1. FDA Label Topologies (21 CFR § 101.9 & § 101.36)

/// Canonical 2D and linear structural topologies for FDA Nutrition Facts (21 CFR § 101.9) and Supplement Facts (21 CFR § 101.36) panels.
enum FDALabelTopology: String, Codable, CaseIterable, Sendable, Hashable {
    /// Standard vertical format (21 CFR § 101.9(d)(1)–(10) & (d)(12); Archetypes B & C).
    case standardVertical
    /// Standard vertical format with two-column side-by-side micronutrients or right-shifted split micronutrients (21 CFR § 101.9(d)(8) & (d)(11)(i)–(ii); Archetype D).
    case sideBySideMicronutrients
    /// 3-zone horizontal tabular format (21 CFR § 101.9(d)(11)(iii); Archetype A).
    case tabularHorizontal
    /// Dual-column format for two forms of the same food, such as "as purchased" vs. "as prepared" (21 CFR § 101.9(e)(5); Archetype F).
    case dualColumnSameFood
    /// Dual-column format declaring "Per Serving" and "Per Container" (21 CFR § 101.9(e)(6)(i); Archetype G).
    case dualColumnPerContainer
    /// Dual-column format declaring "Per Serving" and "Per Unit" (21 CFR § 101.9(e)(6)(i); Archetype H).
    case dualColumnPerUnit
    /// Horizontal tabular dual-column format (21 CFR § 101.9(e)(6)(ii); Archetype I).
    case tabularDualColumn
    /// Aggregate display for multi-product variety packs or multi-packet supplements (21 CFR § 101.9(d)(13)(ii) & § 101.36(e)(8); Archetype E).
    case aggregateVariety
    /// Simplified display omitting insignificant core nutrients (21 CFR § 101.9(f)(4); Archetype J).
    case simplified
    /// Tabular display for small or intermediate packages <= 40 sq. in. (21 CFR § 101.9(j)(13)(ii)(A)(1); Archetype K).
    case smallPackageTabular
    /// Continuous linear string display for small packages lacking interior grid hairlines (21 CFR § 101.9(j)(13)(ii)(A)(2); Archetype L).
    case linearString
    /// Dietary Supplement Facts panel, including two-tiered (b)(2)/(b)(3), split-continuation, and dot-leader variants (21 CFR § 101.36).
    case supplementFacts

    /// Indicates whether this topology represents a 21 CFR § 101.36 Dietary Supplement panel.
    var isSupplementFacts: Bool {
        self == .supplementFacts
    }

    /// Indicates whether the table contains multiple quantitative/percentage nutrient column pairs per row.
    var isMultiColumn: Bool {
        switch self {
        case .dualColumnSameFood, .dualColumnPerContainer, .dualColumnPerUnit, .tabularDualColumn, .aggregateVariety:
            return true
        case .standardVertical, .sideBySideMicronutrients, .tabularHorizontal, .simplified, .smallPackageTabular, .linearString, .supplementFacts:
            return false
        }
    }

    /// Indicates whether the macronutrient list is split into two parallel horizontal stacks.
    var isTabularLayout: Bool {
        switch self {
        case .tabularHorizontal, .tabularDualColumn, .smallPackageTabular:
            return true
        default:
            return false
        }
    }
}

// MARK: - 2. FDA Demographic Groups (21 CFR § 101.9(c)(8)(iv) & (j)(5))

/// Target demographic groups with distinct Reference Daily Intakes (RDIs) and Daily Reference Values (DRVs).
enum FDADemographicGroup: String, Codable, CaseIterable, Sendable, Hashable {
    /// Infants through 12 months of age (§ 101.9(c)(8)(iv) & § 101.9(j)(5)(i)).
    case infantsThrough12Months
    /// Children 1 through 3 years of age (§ 101.9(c)(8)(iv) & § 101.9(j)(5)(ii); 1,000-calorie footnote basis).
    case children1Through3Years
    /// Adults and children 4 or more years of age (§ 101.9(c)(8)(iv); standard 2,000-calorie footnote basis).
    case adultsAndChildren4OrMoreYears
    /// Pregnant and lactating women (§ 101.9(c)(8)(iv) & § 101.36(b)(2)(iii)(E)).
    case pregnantAndLactatingWomen

    /// Standard daily caloric reference diet used in the label footnote, if applicable.
    var referenceCalorieDiet: Int? {
        switch self {
        case .infantsThrough12Months:
            return nil
        case .children1Through3Years:
            return 1000
        case .adultsAndChildren4OrMoreYears, .pregnantAndLactatingWomen:
            return 2000
        }
    }
}

// MARK: - 3. Canonical Nutrient Hierarchy & Identifiers (21 CFR § 101.9(c) & § 101.36(b))

/// Visual and regulatory indentation hierarchy inside the Nutrition Facts and Supplement Facts panels.
enum NutrientIndentationLevel: Int, Codable, CaseIterable, Comparable, Sendable, Hashable {
    /// Unindented top-level nutrients and micronutrients (e.g., Calories, Total Fat, Cholesterol, Sodium, Total Carbohydrate, Protein, Vitamins/Minerals).
    case level0 = 0
    /// First-level indented sub-nutrients (e.g., Saturated Fat, Trans Fat, Polyunsaturated Fat, Monounsaturated Fat, Dietary Fiber, Total Sugars, Sugar Alcohol, Calories from saturated fat).
    case level1 = 1
    /// Second-level indented sub-nutrients (e.g., Soluble Fiber, Insoluble Fiber, Added Sugars).
    case level2 = 2

    static func < (lhs: NutrientIndentationLevel, rhs: NutrientIndentationLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Canonical units of measurement authorized across 21 CFR § 101.9(c) and § 101.36(b)(2).
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

/// Exhaustive enumeration of all mandatory and voluntary nutrients, specific sugar alcohols, and supplement tier markers.
enum CanonicalNutrientID: String, Codable, CaseIterable, Sendable, Hashable {
    // Energy (§ 101.9(c)(1))
    case calories
    case caloriesFromSaturatedFat
    case caloriesFromFat

    // Lipids (§ 101.9(c)(2))
    case totalFat
    case saturatedFat
    case transFat
    case polyunsaturatedFat
    case monounsaturatedFat

    // Cholesterol, Sodium & Fluoride (§ 101.9(c)(3)–(5))
    case cholesterol
    case sodium
    case fluoride

    // Carbohydrates & Sub-Nutrients (§ 101.9(c)(6))
    case totalCarbohydrate
    case dietaryFiber
    case solubleFiber
    case insolubleFiber
    case totalSugars
    case addedSugars
    case sugarAlcohol

    // Specific Named Sugar Alcohols (§ 101.9(c)(6)(iv) & (c)(1)(i)(F))
    case isomalt
    case lactitol
    case xylitol
    case maltitol
    case sorbitol
    case hydrogenatedStarchHydrolysates
    case mannitol
    case erythritol

    // Protein (§ 101.9(c)(7))
    case protein

    // Mandatory 4 Micronutrients (§ 101.9(c)(8)(ii))
    case vitaminD
    case calcium
    case iron
    case potassium

    // Voluntary / Conditional 23 RDI Micronutrients (§ 101.9(c)(8)(iv))
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

    // Sub-Declarations & Supplement Tier-2 Markers (§ 101.9(c)(8)(ii)(B), § 101.36(b)(2)(i)(B)(3), (b)(3), & (c))
    case folicAcid
    case betaCarotenePercentage
    case proprietaryBlend
    case otherDietaryIngredient

    /// Regulatory indentation depth on a standard vertical Nutrition Facts label.
    var indentationLevel: NutrientIndentationLevel {
        switch self {
        case .caloriesFromSaturatedFat, .caloriesFromFat,
             .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat,
             .dietaryFiber, .totalSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol, .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .folicAcid, .betaCarotenePercentage:
            return .level1
        case .solubleFiber, .insolubleFiber, .addedSugars:
            return .level2
        default:
            return .level0
        }
    }

    /// Primary legal unit for quantitative declarations.
    var primaryUnit: NutrientUnit {
        switch self {
        case .calories, .caloriesFromSaturatedFat, .caloriesFromFat:
            return .kcal
        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat,
             .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
             .totalSugars, .addedSugars, .sugarAlcohol,
             .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol, .hydrogenatedStarchHydrolysates, .mannitol, .erythritol,
             .protein, .proprietaryBlend, .otherDietaryIngredient:
            return .g
        case .cholesterol, .sodium, .fluoride,
             .calcium, .iron, .potassium, .vitaminC, .vitaminE,
             .thiamin, .riboflavin, .vitaminB6, .pantothenicAcid,
             .phosphorus, .magnesium, .zinc, .copper, .manganese, .chloride, .choline:
            return .mg
        case .niacin:
            return .mgNE
        case .vitaminD, .vitaminK, .vitaminB12, .biotin, .iodine, .selenium, .chromium, .molybdenum, .folicAcid:
            return .mcg
        case .vitaminA:
            return .mcgRAE
        case .folate:
            return .mcgDFE
        case .betaCarotenePercentage:
            return .percent
        }
    }

    /// All legal units permitted for this nutrient across conventional and supplement labels.
    var allowedUnits: Set<NutrientUnit> {
        switch self {
        case .calories, .caloriesFromSaturatedFat, .caloriesFromFat:
            return [.kcal, .kJ]
        case .vitaminD:
            return [.mcg, .iu]
        case .vitaminA:
            return [.mcgRAE, .mcg, .iu]
        case .vitaminE:
            return [.mg, .iu]
        case .niacin:
            return [.mgNE, .mg]
        case .folate:
            return [.mcgDFE, .mcg]
        case .proprietaryBlend, .otherDietaryIngredient:
            return [.g, .mg, .mcg, .iu]
        default:
            return [primaryUnit]
        }
    }

    /// Indicates whether `<1g` threshold declarations resolve to `0.5g` under Phase 1 target mapping rules.
    var usesOneGramHalfStepThreshold: Bool {
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

    /// Indicates whether `<0.5g` threshold declarations resolve to `0.0g` under 21 CFR § 101.9(c)(2).
    var isFatFamily: Bool {
        switch self {
        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat:
            return true
        default:
            return false
        }
    }

    /// Indicates whether this nutrient is one of the 27 RDI vitamins and minerals in 21 CFR § 101.9(c)(8)(iv).
    var isMicronutrientRDI: Bool {
        switch self {
        case .vitaminD, .calcium, .iron, .potassium,
             .vitaminA, .vitaminC, .vitaminE, .vitaminK,
             .thiamin, .riboflavin, .niacin, .vitaminB6,
             .folate, .vitaminB12, .biotin, .pantothenicAcid,
             .phosphorus, .iodine, .magnesium, .zinc,
             .selenium, .copper, .manganese, .chromium,
             .molybdenum, .chloride, .choline:
            return true
        default:
            return false
        }
    }

    /// Indicates whether this identifier represents a specific named sugar alcohol (`§ 101.9(c)(1)(i)(F)`).
    var isSpecificSugarAlcohol: Bool {
        switch self {
        case .isomalt, .lactitol, .xylitol, .maltitol, .sorbitol,
             .hydrogenatedStarchHydrolysates, .mannitol, .erythritol:
            return true
        default:
            return false
        }
    }
}

// MARK: - 4. Declared Nutrient Amounts & Threshold States

/// Regulatory threshold expressions used when a nutrient falls below a specific reporting increment.
enum NutrientThresholdKind: String, Codable, CaseIterable, Sendable, Hashable {
    /// `<5 cal` expressed as `0` (`§ 101.9(c)(1)`).
    case lessThanFiveCalories
    /// `<0.5g` or `less than 0.5g` for fats, resolving to `0.0` (`§ 101.9(c)(2)`).
    case lessThanHalfGram
    /// `<1g`, `less than 1g`, or `Contains less than 1 gram` for carbs, fiber, sugars, sugar alcohols, and protein, resolving to `0.5` (`§ 101.9(c)(6)–(7)`).
    case lessThanOneGram
    /// `<5mg` or `less than 5 milligrams` for cholesterol (`2–5 mg` range, `§ 101.9(c)(3)`) or sodium (`<5 mg`, `§ 101.9(c)(4)`).
    case lessThanFiveMilligrams
    /// `<1%` or `Less than 1%` for Supplement Facts DRV percentage declarations rounding to `0%` (`§ 101.36(b)(2)(iii)(C)`).
    case lessThanOnePercentDV
    /// `<2%` or `Contains less than 2 percent of the Daily Value` for micronutrients (`§ 101.9(c)(8)(iii)`).
    case lessThanTwoPercentDV
}

/// Explicitly distinguishes the 5 regulatory declaration states for any nutrient on an FDA label.
enum DeclaredNutrientAmount: Codable, Sendable, Equatable, Hashable {
    /// (a) Omitted from the label (e.g., Simplified format or Supplement Facts zero-omission rule under § 101.36(b)(2)(i)).
    case omitted
    /// (b) Explicitly printed as zero (`0`, `0g`, `0mg`, `0mcg`).
    case explicitZero(unit: NutrientUnit?)
    /// (c) Threshold string declaration (`<1g`, `<0.5g`, `<5mg`, `<5 cal`).
    case threshold(NutrientThresholdKind, unit: NutrientUnit?)
    /// (d) Footnote-keyed insignificance (`*`, `†`, or listed in `"Not a significant source of..."`).
    case insignificantFootnote(symbol: String?, reason: String)
    /// (e) Exact numerical weight and validated unit, with optional parenthetical secondary quantity (e.g., `2mcg (80 IU)` or `200mcg DFE (120mcg folic acid)`).
    case exact(value: Double, unit: NutrientUnit, secondaryValue: Double? = nil, secondaryUnit: NutrientUnit? = nil)

    /// Resolves this declaration to a concrete numeric `Double` suitable for `FoodItem` and mathematical validation.
    func resolvedValue(for nutrient: CanonicalNutrientID) -> Double {
        switch self {
        case .omitted, .explicitZero, .insignificantFootnote:
            return 0.0
        case .threshold(let kind, _):
            switch kind {
            case .lessThanOneGram:
                return nutrient.usesOneGramHalfStepThreshold ? 0.5 : 0.0
            case .lessThanHalfGram, .lessThanFiveCalories, .lessThanOnePercentDV, .lessThanTwoPercentDV:
                return 0.0
            case .lessThanFiveMilligrams:
                return nutrient == .cholesterol ? 2.5 : 0.0
            }
        case .exact(let value, _, _, _):
            return max(0.0, value)
        }
    }

    /// Resolves a calorie declaration to an integer value for `FoodItem.calories`.
    func resolvedCalories() -> Int {
        switch self {
        case .omitted, .explicitZero, .insignificantFootnote, .threshold:
            return 0
        case .exact(let value, _, _, _):
            return max(0, Int(value.rounded()))
        }
    }

    /// Primary unit attached to this declaration, if any.
    var unit: NutrientUnit? {
        switch self {
        case .omitted, .insignificantFootnote:
            return nil
        case .explicitZero(let unit), .threshold(_, let unit):
            return unit
        case .exact(_, let unit, _, _):
            return unit
        }
    }
}

/// Represents the `% Daily Value` column state for a nutrient row.
enum DeclaredPercentDV: Codable, Sendable, Equatable, Hashable {
    /// Blank or omitted `% DV` cell (e.g., Trans Fat, Total Sugars, adult Protein without claim, or infant restricted macros).
    case omitted
    /// Symbol (`†`, `*`) pointing to `"Daily Value not established"` (`§ 101.36(b)(2)(iii)(F)` & `(b)(3)(iv)`).
    case notEstablished(symbol: String?)
    /// Threshold percentage declaration (`<1%` or `<2%`).
    case threshold(NutrientThresholdKind)
    /// Whole integer percentage declaration (e.g., `10%` -> `10`).
    case exact(Int)

    /// Returns the numeric percentage value if explicitly declared.
    var numericPercent: Double? {
        switch self {
        case .omitted, .notEstablished:
            return nil
        case .threshold(let kind):
            switch kind {
            case .lessThanOnePercentDV:
                return 0.5
            case .lessThanTwoPercentDV:
                return 1.0
            default:
                return 0.0
            }
        case .exact(let pct):
            return Double(pct)
        }
    }
}

// MARK: - 5. Parsed Row, Serving Size & Exemption Models

/// A normalized nutrient entry extracted from a single label row or linear string segment.
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
    ) {
        self.nutrient = nutrient
        self.rawName = rawName
        self.amount = amount
        self.percentDV = percentDV
        self.indentationLevel = indentationLevel ?? nutrient.indentationLevel
        self.sourceCompoundDescription = sourceCompoundDescription
        self.columnIndex = columnIndex
    }
}

/// Structured representation of a parsed `"Serving size"` and `"Servings per container"` declaration (`§ 101.9(b)` & `§ 101.36(b)(1)`).
struct ParsedServingSize: Codable, Sendable, Equatable, Hashable {
    /// Metric quantity inside parentheses (e.g., `225.0` from `"1 cup (225g)"`) or fallback metric conversion.
    var servingSize: Double
    /// Normalized metric unit strictly constrained to `"g"` or `"ml"` for `AddFoodView`.
    var servingUnit: String
    /// Numeric household quantity preceding the household unit (e.g., `0.67` from `"2/3 cup (55g)"`).
    var commonHouseholdMeasurementAmount: Double?
    /// Household or supplement dosage unit string (e.g., `"cup"`, `"slice"`, `"scoop"`, `"capsule"`).
    var commonHouseholdMeasurement: String?
    /// Numeric count of servings per container, if present.
    var servingsPerContainer: Double?
    /// Optional prefix modifier on servings per container (`"about"`, `"usually"`, `"varied"`).
    var servingsPerContainerModifier: String?
    /// Optional daily multiplier declared on supplement labels (e.g., `"Multiply amounts by 3 for total daily amount"`).
    var perDayMultiplier: Int?
    /// Indicates whether `servingSize` was computed via standard FDA household-to-metric conversion (`§ 101.9(b)(5)(viii)`).
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
    ) {
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.commonHouseholdMeasurementAmount = commonHouseholdMeasurementAmount
        self.commonHouseholdMeasurement = commonHouseholdMeasurement
        self.servingsPerContainer = servingsPerContainer
        self.servingsPerContainerModifier = servingsPerContainerModifier
        self.perDayMultiplier = perDayMultiplier
        self.usedMetricFallbackConversion = usedMetricFallbackConversion
    }
}

/// Legitimate regulatory exemption strings that replace a Nutrition Facts or Supplement Facts panel (`§ 101.9(j)` & `§ 101.36(i)`).
enum FDALegitimateExemptionKind: String, Codable, CaseIterable, Sendable, Hashable {
    /// Inner multiunit container marked `"This Unit Not Labeled For Retail Sale"` (`§ 101.9(j)(15)` & `§ 101.36(i)(3)`).
    case multiunitNotLabeledForRetailSale
    /// Small package `<12 sq. in.` printing `"For nutrition information, call..."` or `"write to..."` (`§ 101.9(j)(13)(i)(A)`).
    case smallPackageContactString
}

// MARK: - 6. Validation Diagnostics & ScannedNutritionPayload

/// Severity level for mathematical cross-validation and self-healing events.
enum ValidationSeverity: String, Codable, CaseIterable, Sendable, Hashable {
    case info
    case healed
    case warning
    case error
}

/// Diagnostic record produced during `% DV`, sub-nutrient ceiling, and Atwater calorie cross-validation.
struct ValidationDiagnostic: Codable, Sendable, Equatable, Hashable {
    let severity: ValidationSeverity
    let nutrient: CanonicalNutrientID?
    let code: String
    let message: String

    init(severity: ValidationSeverity, nutrient: CanonicalNutrientID? = nil, code: String, message: String) {
        self.severity = severity
        self.nutrient = nutrient
        self.code = code
        self.message = message
    }
}

/// Validated, self-healed nutrition payload ready to auto-populate `AddFoodView` / `ScannedAddFoodView` and persist to `FoodItem` / `ScannedFoodItem`.
struct ScannedNutritionPayload: Codable, Sendable, Equatable {
    // Target AddFoodView / FoodItem Properties
    var isSupplement: Bool
    var servingSize: Double
    var servingUnit: String
    var commonHouseholdMeasurement: String?
    var commonHouseholdMeasurementAmount: Double?
    var servingsPerContainer: Double?
    var servingsPerContainerModifier: String?
    var perDayMultiplier: Int?
    var calories: Int
    var fat: Double
    var saturatedFat: Double
    var transFat: Double
    var carb: Double
    var dietaryFiber: Double
    var addedSugar: Double
    var protein: Double

    // Regulatory Context & Validation Metadata
    var topology: FDALabelTopology
    var demographicGroup: FDADemographicGroup
    var confidenceScore: Double
    var atwaterCalorieCheckPassed: Bool
    var expectedAtwaterCalorieRange: ClosedRange<Int>
    var healedNutrients: Set<CanonicalNutrientID>
    var diagnostics: [ValidationDiagnostic]
    var allParsedNutrients: [CanonicalNutrientID: DeclaredNutrientAmount]
    var allParsedPercentDVs: [CanonicalNutrientID: DeclaredPercentDV]
    var derivedFromPercentDVNutrients: Set<CanonicalNutrientID>
    var sourceCompounds: [CanonicalNutrientID: String]

    init(
        isSupplement: Bool,
        servingSize: Double,
        servingUnit: String,
        commonHouseholdMeasurement: String? = nil,
        commonHouseholdMeasurementAmount: Double? = nil,
        servingsPerContainer: Double? = nil,
        servingsPerContainerModifier: String? = nil,
        perDayMultiplier: Int? = nil,
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
        allParsedNutrients: [CanonicalNutrientID: DeclaredNutrientAmount] = [:],
        allParsedPercentDVs: [CanonicalNutrientID: DeclaredPercentDV] = [:],
        derivedFromPercentDVNutrients: Set<CanonicalNutrientID> = [],
        sourceCompounds: [CanonicalNutrientID: String] = [:]
    ) {
        self.isSupplement = isSupplement
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.commonHouseholdMeasurement = commonHouseholdMeasurement
        self.commonHouseholdMeasurementAmount = commonHouseholdMeasurementAmount
        self.servingsPerContainer = servingsPerContainer
        self.servingsPerContainerModifier = servingsPerContainerModifier
        self.perDayMultiplier = perDayMultiplier
        self.calories = calories
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.carb = carb
        self.dietaryFiber = dietaryFiber
        self.addedSugar = addedSugar
        self.protein = protein
        self.topology = topology
        self.demographicGroup = demographicGroup
        self.confidenceScore = confidenceScore
        self.atwaterCalorieCheckPassed = atwaterCalorieCheckPassed
        self.expectedAtwaterCalorieRange = expectedAtwaterCalorieRange
        self.healedNutrients = healedNutrients
        self.diagnostics = diagnostics
        self.allParsedNutrients = allParsedNutrients
        self.allParsedPercentDVs = allParsedPercentDVs
        self.derivedFromPercentDVNutrients = derivedFromPercentDVNutrients
        self.sourceCompounds = sourceCompounds
    }
}

// MARK: - 7. Multi-Column & Variety-Pack Candidate Model (Examples E, F, G, H, I)

/// Represents a single extracted product/serving column from a Dual-Column (`F, G, H, I`) or Aggregate Variety Pack (`E`) label.
struct ScannedColumnCandidate: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var columnIndex: Int
    var headerTitle: String
    var servingSizeText: String?
    var isIncludedByDefault: Bool
    var payload: ScannedNutritionPayload

    init(
        id: UUID = UUID(),
        columnIndex: Int,
        headerTitle: String,
        servingSizeText: String? = nil,
        isIncludedByDefault: Bool = true,
        payload: ScannedNutritionPayload
    ) {
        self.id = id
        self.columnIndex = columnIndex
        self.headerTitle = headerTitle
        self.servingSizeText = servingSizeText
        self.isIncludedByDefault = isIncludedByDefault
        self.payload = payload
    }
}
