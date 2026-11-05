import Foundation

// MARK: - FDALexicalNormalizer (21 CFR § 101.9, § 101.17, § 101.36, & §§ 101.54–101.62)

/// Pure-Swift lexical normalizer, order-independent nutrient resolver, serving size grammar parser, and defensive decoy/warning filter for FDA Nutrition Facts and Supplement Facts panels.
enum FDALexicalNormalizer {

    // MARK: - 1. Canonical Nutrient Sequences (Part 1.2 & Part 3.2)

    /// Strict top-to-bottom sequence of nutrients on a conventional `"Nutrition Facts"` panel (`21 CFR § 101.9(c)`).
    static let conventionalNutrientSequence: [CanonicalNutrientID] = [
        .calories,
        .caloriesFromSaturatedFat,
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
        .protein,
        .vitaminD,
        .calcium,
        .iron,
        .potassium,
        .vitaminA,
        .vitaminC,
        .vitaminE,
        .vitaminK,
        .thiamin,
        .riboflavin,
        .niacin,
        .vitaminB6,
        .folate,
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

    /// Modified 29-item micronutrient sequence required on `"Supplement Facts"` `(b)(2)` tiers (`21 CFR § 101.36(b)(2)(i)(B)`), where Calcium and Iron follow Choline, and Sodium and Potassium follow Chloride.
    static let supplementMicronutrientSequence: [CanonicalNutrientID] = [
        .vitaminA,
        .vitaminC,
        .vitaminD,
        .vitaminE,
        .vitaminK,
        .thiamin,
        .riboflavin,
        .niacin,
        .vitaminB6,
        .folate,
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

    // MARK: - 2. Authorized Abbreviations & Lexical Normalization Dictionaries (Part 1.2, 1.3, & 3.2)

    /// FDA-authorized header and structural abbreviations (`21 CFR § 101.9(j)(13)(ii)(B)` & `§ 101.36(b)(2)(iii)(A)`).
    static let structuralHeaderAbbreviations: [String: String] = [
        "serv size": "serving size",
        "serv. size": "serving size",
        "serving size": "serving size",
        "tamaño de la porción": "serving size",
        "tamano de la porcion": "serving size",
        "servings": "servings per container",
        "servings per container": "servings per container",
        "porciones por envase": "servings per container",
        "percent daily value": "% daily value",
        "percent dv": "% daily value",
        "% dv": "% daily value",
        "% dv*": "% daily value",
        "% daily value": "% daily value",
        "% daily value*": "% daily value",
        "% daily value (dv)": "% daily value",
        "% valor diario": "% daily value",
        "amount/serving": "amount per serving",
        "amount / serving": "amount per serving",
        "amount per serving": "amount per serving",
        "incl": "includes",
        "incl.": "includes",
        "cal": "calories",
        "cal.": "calories"
    ]

    /// Ordered abbreviation expansion rules applied during lexical normalization (`21 CFR § 101.9(j)(13)(ii)(B)`).
    static let authorizedAbbreviationExpansions: [(pattern: String, replacement: String)] = [
        ("\\bsat\\.?\\s+fat\\s+cal\\.?\\b", "calories from saturated fat"),
        ("\\bfat\\s+cal\\.?\\b", "calories from fat"),
        ("\\bsat\\.?\\s+fat\\b", "saturated fat"),
        ("\\bmonounsat\\.?\\s+fat\\b", "monounsaturated fat"),
        ("\\bpolyunsat\\.?\\s+fat\\b", "polyunsaturated fat"),
        ("\\bpoly-unsaturated\\s+fat\\b", "polyunsaturated fat"),
        ("\\bpoly-unsaturated\\b", "polyunsaturated fat"),
        ("\\bcholest\\.?\\b", "cholesterol"),
        ("\\btotal\\s+carb\\.?\\b", "total carbohydrate"),
        ("\\bsol\\.?\\s+fiber\\b", "soluble fiber"),
        ("\\binsol\\.?\\s+fiber\\b", "insoluble fiber"),
        ("\\bsugar\\s+alc\\.?\\b", "sugar alcohol"),
        ("\\bvit\\.?\\s+", "vitamin "),
        ("\\bpotas\\.?\\b", "potassium"),
        ("\\bincl\\.?\\b", "includes")
    ]

    /// Exhaustive synonym lookup dictionary mapping normalized nutrient strings (including inverted names, vitamin chemical synonyms, specific sugar alcohols, and bilingual English/Spanish names) to `CanonicalNutrientID`.
    static let canonicalNutrientSynonyms: [String: CanonicalNutrientID] = [
        // Energy (§ 101.9(c)(1))
        "calories": .calories,
        "total calories": .calories,
        "calories, total": .calories,
        "calories total": .calories,
        "calories (energy)": .calories,
        "calories energy": .calories,
        "cal": .calories,
        "calories/calorias": .calories,
        "calories/calorías": .calories,
        "calories from saturated fat": .caloriesFromSaturatedFat,
        "calories from saturated": .caloriesFromSaturatedFat,
        "sat fat cal": .caloriesFromSaturatedFat,
        "calories from fat": .caloriesFromFat,
        "fat cal": .caloriesFromFat,

        // Lipids (§ 101.9(c)(2))
        "total fat": .totalFat,
        "fat, total": .totalFat,
        "fat total": .totalFat,
        "total fat/grasa total": .totalFat,
        "saturated fat": .saturatedFat,
        "saturated": .saturatedFat,
        "sat fat": .saturatedFat,
        "saturated fat/grasa saturada": .saturatedFat,
        "trans fat": .transFat,
        "trans": .transFat,
        "trans fat/grasa trans": .transFat,
        "polyunsaturated fat": .polyunsaturatedFat,
        "poly-unsaturated fat": .polyunsaturatedFat,
        "poly-unsaturated": .polyunsaturatedFat,
        "polyunsaturated": .polyunsaturatedFat,
        "polyunsat fat": .polyunsaturatedFat,
        "monounsaturated fat": .monounsaturatedFat,
        "monounsaturated": .monounsaturatedFat,
        "monounsat fat": .monounsaturatedFat,

        // Sterols, Electrolytes & Halides (§ 101.9(c)(3)–(5))
        "cholesterol": .cholesterol,
        "cholest": .cholesterol,
        "cholesterol/colesterol": .cholesterol,
        "sodium": .sodium,
        "sodium/sodio": .sodium,
        "fluoride": .fluoride,

        // Carbohydrates & Sub-Nutrients (§ 101.9(c)(6))
        "total carbohydrate": .totalCarbohydrate,
        "carbohydrate, total": .totalCarbohydrate,
        "carbohydrate total": .totalCarbohydrate,
        "total carb": .totalCarbohydrate,
        "total carbohydrates": .totalCarbohydrate,
        "carbohydrate": .totalCarbohydrate,
        "total carbohydrate/carbohidrato total": .totalCarbohydrate,
        "total carb/carb total": .totalCarbohydrate,
        "dietary fiber": .dietaryFiber,
        "fiber": .dietaryFiber,
        "dietary fiber/fibra dietetica": .dietaryFiber,
        "dietary fiber/fibra dietética": .dietaryFiber,
        "soluble fiber": .solubleFiber,
        "sol fiber": .solubleFiber,
        "insoluble fiber": .insolubleFiber,
        "insol fiber": .insolubleFiber,
        "total sugars": .totalSugars,
        "sugars, total": .totalSugars,
        "sugars": .totalSugars,
        "total sugars/azucares totales": .totalSugars,
        "total sugars/azúcares totales": .totalSugars,
        "added sugars": .addedSugars,
        "includes added sugars": .addedSugars,
        "incl added sugars": .addedSugars,
        "added sugars/azucares anadidos": .addedSugars,
        "added sugars/azúcares añadidos": .addedSugars,
        "sugar alcohol": .sugarAlcohol,
        "sugar alcohols": .sugarAlcohol,
        "sugar alc": .sugarAlcohol,
        "polyols": .sugarAlcohol,

        // Specific Sugar Alcohols (§ 101.9(c)(6)(iv) & (c)(1)(i)(F))
        "isomalt": .isomalt,
        "lactitol": .lactitol,
        "xylitol": .xylitol,
        "maltitol": .maltitol,
        "sorbitol": .sorbitol,
        "hydrogenated starch hydrolysates": .hydrogenatedStarchHydrolysates,
        "hydrogenated starch hydrolysate": .hydrogenatedStarchHydrolysates,
        "mannitol": .mannitol,
        "erythritol": .erythritol,

        // Protein (§ 101.9(c)(7))
        "protein": .protein,
        "proteins": .protein,
        "protein/proteinas": .protein,
        "protein/proteínas": .protein,

        // Mandatory 4 Micronutrients (§ 101.9(c)(8)(ii))
        "vitamin d": .vitaminD,
        "vit d": .vitaminD,
        "vitamin d3": .vitaminD,
        "vitamin d2": .vitaminD,
        "vitamin d (cholecalciferol)": .vitaminD,
        "vitamin d (ergocalciferol)": .vitaminD,
        "cholecalciferol": .vitaminD,
        "ergocalciferol": .vitaminD,
        "calcium": .calcium,
        "calcium/calcio": .calcium,
        "iron": .iron,
        "iron/hierro": .iron,
        "potassium": .potassium,
        "potas": .potassium,
        "potassium/potasio": .potassium,

        // Voluntary / Conditional 23 RDI Micronutrients (§ 101.9(c)(8)(iv))
        "vitamin a": .vitaminA,
        "vit a": .vitaminA,
        "vitamin c": .vitaminC,
        "vit c": .vitaminC,
        "vitamin c (ascorbic acid)": .vitaminC,
        "ascorbic acid": .vitaminC,
        "vitamin e": .vitaminE,
        "vit e": .vitaminE,
        "vitamin e (alpha-tocopherol)": .vitaminE,
        "vitamin k": .vitaminK,
        "vit k": .vitaminK,
        "vitamin k1": .vitaminK,
        "vitamin k2": .vitaminK,
        "phylloquinone": .vitaminK,
        "menaquinone": .vitaminK,
        "thiamin": .thiamin,
        "thiamine": .thiamin,
        "thiamin (vitamin b1)": .thiamin,
        "thiamine (vitamin b1)": .thiamin,
        "vitamin b1": .thiamin,
        "vit b1": .thiamin,
        "riboflavin": .riboflavin,
        "riboflavin (vitamin b2)": .riboflavin,
        "vitamin b2": .riboflavin,
        "vit b2": .riboflavin,
        "niacin": .niacin,
        "niacin (vitamin b3)": .niacin,
        "niacinamide": .niacin,
        "nicotinic acid": .niacin,
        "vitamin b3": .niacin,
        "vitamin b6": .vitaminB6,
        "vit b6": .vitaminB6,
        "vitamin b-6": .vitaminB6,
        "pyridoxine": .vitaminB6,
        "folate": .folate,
        "folate and folic acid": .folate,
        "folacin": .folate,
        "vitamin b9": .folate,
        "folic acid": .folicAcid,
        "vitamin b12": .vitaminB12,
        "vit b12": .vitaminB12,
        "vitamin b-12": .vitaminB12,
        "cobalamin": .vitaminB12,
        "cyanocobalamin": .vitaminB12,
        "methylcobalamin": .vitaminB12,
        "biotin": .biotin,
        "vitamin b7": .biotin,
        "pantothenic acid": .pantothenicAcid,
        "vitamin b5": .pantothenicAcid,
        "d-calcium pantothenate": .pantothenicAcid,
        "phosphorus": .phosphorus,
        "iodine": .iodine,
        "magnesium": .magnesium,
        "zinc": .zinc,
        "selenium": .selenium,
        "copper": .copper,
        "manganese": .manganese,
        "chromium": .chromium,
        "molybdenum": .molybdenum,
        "chloride": .chloride,
        "choline": .choline,

        // Supplement Tier-2 & Sub-Declarations (§ 101.36(b)(3) & (c))
        "proprietary blend": .proprietaryBlend,
        "beta-carotene": .betaCarotenePercentage
    ]

    // MARK: - 3. Defensive Decoy & Mandatory Boxed Warning Filters (Part 5.2, Part 6.5, & Part 1.1.10)

    /// Relative-claim comparative keywords placed adjacent to the Nutrition Facts box (`21 CFR §§ 101.54–101.62`, Part 5.2) that must be rejected so the reference food's nutrient weight is never ingested.
    static let decoyComparativeSubstrings: [String] = [
        "reduced from",
        "lowered from",
        "compared with",
        "compared to",
        "per 3 oz",
        "regular",
        "not a low",
        "not a sodium free",
        "not for control of sodium",
        "fiber content of",
        "calorie content has been",
        "sugar content has been",
        "sodium content has been",
        "fat content has been",
        "cholesterol lowered from",
        "than regular",
        "less fat than",
        "fewer calories than"
    ]

    /// Mandatory `21 CFR § 101.17` hairline-boxed warning phrases (Part 6.5) that must be rejected so a warning box is never misclassified as a Nutrition Facts or Supplement Facts table.
    static let mandatoryBoxedWarningSubstrings: [String] = [
        // § 101.17(e) Dietary supplements containing iron in solid oral dosage form
        "accidental overdose of iron-containing products",
        "leading cause of fatal poisoning in children under 6",
        "poison control center immediately",
        // § 101.17(g) Unpasteurized fruit and vegetable juices
        "has not been pasteurized",
        "harmful bacteria that can cause serious illness",
        "weakened immune systems",
        // § 101.17(h) Shell eggs safe handling instructions
        "safe handling instructions",
        "to prevent illness from bacteria",
        "keep eggs refrigerated",
        "cook eggs until yolks are firm",
        "cook foods containing eggs thoroughly",
        // § 101.17(a)–(b) Self-pressurized containers & propellants
        "avoid spraying in eyes",
        "contents under pressure",
        "do not puncture",
        "deliberately concentrating and inhaling",
        // § 101.17(d) High-protein weight-reduction products
        "very low calorie protein diets",
        "below 400 calories per day",
        "do not use for weight reduction",
        "without medical supervision",
        // § 101.17(f) Dry or incompletely hydrated psyllium husk foods
        "full glass of liquid",
        "without enough liquid may cause choking",
        "difficulty in swallowing"
    ]

    /// Returns `true` if `text` is a Subpart D decoy comparative nutrient string (`21 CFR §§ 101.54–101.62`) or sodium disclaimer adjacent to the nutrition panel.
    static func isDecoyComparativeString(_ text: String) -> Bool {
        let lower = text.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        for keyword in decoyComparativeSubstrings {
            if keyword == "regular" {
                // Match "regular" when used in comparative prose (e.g. "regular cheesecake—300 calories" or "regular product")
                if lower.range(of: "\\bregular\\b", options: .regularExpression) != nil {
                    return true
                }
            } else if lower.contains(keyword) {
                return true
            }
        }
        return false
    }

    /// Returns `true` if `text` matches a mandatory `21 CFR § 101.17` hairline-boxed warning or safe-handling block.
    static func isMandatoryBoxedWarning(_ text: String) -> Bool {
        let lower = text.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        for warningPhrase in mandatoryBoxedWarningSubstrings {
            if lower.contains(warningPhrase) {
                return true
            }
        }
        return false
    }

    /// Detects legitimate regulatory exemption replacement strings when a package omits a Nutrition Facts panel (`21 CFR § 101.9(j)(13)(i)(A)` & `(j)(15)`).
    static func detectLegitimateExemption(_ text: String) -> FDALegitimateExemptionKind? {
        let lower = text.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        if lower.contains("not labeled for retail sale") || lower.contains("not labeled for individual retail sale") {
            return .multiunitNotLabeledForRetailSale
        }
        if lower.contains("for nutrition information, call")
            || lower.contains("for nutrition information call")
            || lower.contains("for nutrition information, write")
            || lower.contains("for nutrition information write") {
            return .smallPackageContactString
        }
        return nil
    }

    /// Returns `true` when a Dual-Column header represents a cereal or product combined with milk
    /// (`Example M`: `"Cereal With 1/2 Cup Fat Free Milk"`, `"With 1/2 cup skim milk"`, `"with milk"`, etc.).
    /// Such columns are automatically excluded so the user can log the base cereal and choose their own milk.
    static func isCombinedWithMilkColumnHeader(_ text: String) -> Bool {
        let lower = text
            .replacingOccurrences(of: "<br>", with: " ", options: .caseInsensitive)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard lower.contains("milk") else { return false }

        let milkCombinationIndicators = [
            "with",
            "w/",
            "cereal",
            "skim",
            "fat free",
            "fat-free",
            "nonfat",
            "non-fat",
            "lowfat",
            "low-fat",
            "cup",
            "1/2",
            "3/4",
            "½",
            "¾",
            "+"
        ]
        if milkCombinationIndicators.contains(where: { lower.contains($0) }) {
            return true
        }
        // Standalone "Milk" or "... Milk" column header on a multi-column panel
        return lower == "milk" || lower.hasSuffix(" milk")
    }

    // MARK: - 4. Text Sanitization, Dot-Leader Stripping & Supplement Source Stripping (Part 3.3 & 3.4)

    /// Strips small-package supplement dot-leader runs (`\.{2,}`, `21 CFR § 101.36(i)(2)(v)`) and normalizes whitespace.
    static func stripDotLeaders(_ text: String) -> String {
        text.replacingOccurrences(of: "\\.{2,}", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "[•·]", with: " • ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strips inline supplement source compound declarations (`"as ..."` / `"from ..."` in parentheses or trailing clauses per `21 CFR § 101.36(d)`), while extracting nested beta-carotene percentage (`§ 101.36(b)(2)(i)(B)(3)`) and folic acid `mcg` (`§ 101.9(c)(8)(ii)(B)`).
    static func stripSupplementSourceCompounds(_ text: String) -> (
        cleanedText: String,
        sourceCompound: String?,
        betaCarotenePercent: Double?,
        folicAcidMcg: Double?
    ) {
        var working = stripDotLeaders(text)
        var extractedSources: [String] = []
        var betaCarotenePct: Double? = nil
        var folicAcidWeight: Double? = nil

        // 1. Check for nested Beta-Carotene syntax: e.g. "(90% (810 mcg) as beta-carotene)" or "(90% as beta-carotene)"
        let betaPattern = "\\(\\s*(\\d+(?:\\.\\d+)?)\\s*%\\s*(?:\\(\\s*\\d+(?:\\.\\d+)?\\s*mcg\\s*\\)\\s*)?(?:as\\s+)?beta[-\\s]?carotene\\s*\\)"
        if let regex = try? NSRegularExpression(pattern: betaPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: working, options: [], range: NSRange(working.startIndex..., in: working)),
           let fullRange = Range(match.range(at: 0), in: working),
           let pctRange = Range(match.range(at: 1), in: working) {
            betaCarotenePct = Double(working[pctRange])
            extractedSources.append(String(working[fullRange]))
            working.removeSubrange(fullRange)
        }

        // 2. Check for parenthetical folic acid syntax: e.g. "(120mcg folic acid)" or "(120 mcg folic acid)"
        let folicPattern = "\\(\\s*(\\d+(?:\\.\\d+)?)\\s*mcg\\s+folic\\s+acid\\s*\\)"
        if let regex = try? NSRegularExpression(pattern: folicPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: working, options: [], range: NSRange(working.startIndex..., in: working)),
           let fullRange = Range(match.range(at: 0), in: working),
           let valRange = Range(match.range(at: 1), in: working) {
            folicAcidWeight = Double(working[valRange])
            extractedSources.append(String(working[fullRange]))
            working.removeSubrange(fullRange)
        }

        // 3. Strip parenthetical source compounds prefaced by "as" or "from": e.g. "(as calcium carbonate USP)" or "(from magnesium oxide)"
        let sourceParenPattern = "\\(\\s*(?:as|from)\\b[^)]*\\)"
        if let regex = try? NSRegularExpression(pattern: sourceParenPattern, options: [.caseInsensitive]) {
            let matches = regex.matches(in: working, options: [], range: NSRange(working.startIndex..., in: working)).reversed()
            for match in matches {
                if let r = Range(match.range, in: working) {
                    extractedSources.insert(String(working[r]), at: 0)
                    working.removeSubrange(r)
                }
            }
        }

        // 4. Strip unparenthesized inline "as [compound]" following a nutrient name before the weight or at the end
        let inlineAsPattern = "\\b(?:as|from)\\s+[a-z][a-z0-9\\s,\\-]{3,}(?=\\s+\\d|$)"
        if let regex = try? NSRegularExpression(pattern: inlineAsPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: working, options: [], range: NSRange(working.startIndex..., in: working)),
           let r = Range(match.range, in: working) {
            let candidate = String(working[r]).lowercased()
            if !candidate.contains("added sugar") && !candidate.contains("saturated") {
                extractedSources.append(String(working[r]).trimmingCharacters(in: .whitespaces))
                working.removeSubrange(r)
            }
        }

        let cleaned = working
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let combinedSource = extractedSources.isEmpty ? nil : extractedSources.joined(separator: " ")
        return (cleaned, combinedSource, betaCarotenePct, folicAcidWeight)
    }

    /// Strips footnote symbols (`*`, `†`, `‡`) and trailing superscript digits (e.g., `"Folate 6"` -> `"Folate"`) without corrupting vitamin numbers (`Vitamin B1`, `B2`, `B6`, `B12`, `D2`, `D3`, `K1`, `K2`).
    static func stripFootnoteSuperscripts(_ text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "[*†‡§]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip trailing single digit superscripts after non-"b/d/k" words (e.g., "Folate 6" -> "Folate", "Niacin 1" -> "Niacin")
        let trailingFootnoteRegex = try? NSRegularExpression(
            pattern: "^(.*?\\b(?!(?:vitamin|vit\\.?|b|d|k)\\s*$)[a-z]{3,})\\s+\\d$",
            options: [.caseInsensitive]
        )
        if let regex = trailingFootnoteRegex,
           let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(cleaned.startIndex..., in: cleaned)),
           let baseRange = Range(match.range(at: 1), in: cleaned) {
            let base = String(cleaned[baseRange])
            // Ensure we never strip the number from "Vitamin B6", "Vitamin B12", "Vitamin B1", "Vitamin B2", "Vitamin D3", "Vitamin K2"
            let lowerBase = base.lowercased()
            if !lowerBase.hasSuffix("vitamin b")
                && !lowerBase.hasSuffix("vit b")
                && !lowerBase.hasSuffix("vitamin d")
                && !lowerBase.hasSuffix("vitamin k") {
                cleaned = base
            }
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Expands small-package and dual-column abbreviations (`Part 1.3`) into their full canonical strings.
    static func expandAuthorizedAbbreviations(_ text: String) -> String {
        var working = text.lowercased()
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let exactHeader = structuralHeaderAbbreviations[working] {
            return exactHeader
        }

        for (pattern, replacement) in authorizedAbbreviationExpansions {
            working = working.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        return working
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 5. Order-Independent Nutrient Resolver (Part 1.2, 1.3, 1.6.1, & 3.2)

    /// Resolves any raw nutrient label cell or prefix into its canonical `CanonicalNutrientID`, rejecting footnote references (`"2,000 calories"`, `"1,000 calories"`, `"Calories per gram"`) and decoy strings.
    static func resolveNutrientID(from rawText: String) -> CanonicalNutrientID? {
        guard !isDecoyComparativeString(rawText), !isMandatoryBoxedWarning(rawText) else {
            return nil
        }

        let sourceStripped = stripSupplementSourceCompounds(rawText).cleanedText
        let withoutFootnotes = stripFootnoteSuperscripts(sourceStripped)
        let expanded = expandAuthorizedAbbreviations(withoutFootnotes)

        // Reject footnote and header lines that mention calories or daily values
        if expanded.contains("2,000 calories")
            || expanded.contains("2000 calories")
            || expanded.contains("1,000 calories")
            || expanded.contains("1000 calories")
            || expanded.contains("calories a day")
            || expanded.contains("calories per gram")
            || expanded.contains("tells you how much")
            || expanded.contains("not a significant source")
            || expanded.contains("daily value not established")
            || expanded.contains("based on a 2,000")
            || expanded.contains("based on a 1,000")
            || expanded == "amount per serving"
            || expanded == "% daily value"
            || expanded == "per serving"
            || expanded.hasPrefix("serving size")
            || expanded.hasPrefix("servings per container") {
            return nil
        }

        // Strip inline numeric weights and units to isolate the nutrient name
        let nameOnly = stripInlineQuantitiesAndUnits(from: expanded)
        if let exact = canonicalNutrientSynonyms[nameOnly] {
            return exact
        }

        // Disambiguate specific multi-token nutrients in priority order (most specific child before parent)
        if nameOnly.contains("added sugar") {
            return .addedSugars
        }
        if nameOnly.contains("calories from saturated") || nameOnly.contains("sat fat cal") {
            return .caloriesFromSaturatedFat
        }
        if nameOnly.contains("calories from fat") || nameOnly.contains("fat cal") {
            return .caloriesFromFat
        }
        if nameOnly.contains("soluble fiber") {
            return .solubleFiber
        }
        if nameOnly.contains("insoluble fiber") {
            return .insolubleFiber
        }
        if nameOnly.contains("dietary fiber") || nameOnly == "fiber" {
            return .dietaryFiber
        }
        if nameOnly.contains("total sugar") || nameOnly == "sugars" {
            return .totalSugars
        }
        if nameOnly.contains("sugar alcohol") {
            return .sugarAlcohol
        }
        if nameOnly.contains("polyunsaturated") || nameOnly.contains("poly-unsaturated") {
            return .polyunsaturatedFat
        }
        if nameOnly.contains("monounsaturated") {
            return .monounsaturatedFat
        }
        if nameOnly.contains("saturated fat") || nameOnly == "saturated" {
            return .saturatedFat
        }
        if nameOnly.contains("trans fat") || nameOnly == "trans" {
            return .transFat
        }
        if nameOnly.contains("total fat") || nameOnly == "fat, total" {
            return .totalFat
        }
        if nameOnly.contains("total carbohydrate") || nameOnly.contains("carbohydrate, total") || nameOnly == "total carb" {
            return .totalCarbohydrate
        }
        if nameOnly.contains("vitamin b12") || nameOnly.contains("vitamin b-12") || nameOnly.contains("cobalamin") {
            return .vitaminB12
        }
        if nameOnly.contains("vitamin b6") || nameOnly.contains("vitamin b-6") || nameOnly.contains("pyridoxine") {
            return .vitaminB6
        }
        if nameOnly.contains("thiamin") || nameOnly.contains("vitamin b1") {
            return .thiamin
        }
        if nameOnly.contains("riboflavin") || nameOnly.contains("vitamin b2") {
            return .riboflavin
        }
        if nameOnly.contains("niacin") || nameOnly.contains("vitamin b3") {
            return .niacin
        }
        if nameOnly.contains("pantothenic") || nameOnly.contains("vitamin b5") {
            return .pantothenicAcid
        }
        if nameOnly.contains("biotin") || nameOnly.contains("vitamin b7") {
            return .biotin
        }
        if nameOnly.contains("folate") || nameOnly.contains("folacin") {
            return .folate
        }
        if nameOnly.contains("folic acid") {
            return .folicAcid
        }
        if nameOnly.contains("vitamin d") || nameOnly.contains("cholecalciferol") || nameOnly.contains("ergocalciferol") {
            return .vitaminD
        }
        if nameOnly.contains("vitamin a") {
            return .vitaminA
        }
        if nameOnly.contains("vitamin c") || nameOnly.contains("ascorbic acid") {
            return .vitaminC
        }
        if nameOnly.contains("vitamin e") || nameOnly.contains("tocopherol") {
            return .vitaminE
        }
        if nameOnly.contains("vitamin k") || nameOnly.contains("phylloquinone") || nameOnly.contains("menaquinone") {
            return .vitaminK
        }
        if nameOnly.contains("proprietary blend") {
            return .proprietaryBlend
        }

        // Check remaining single-token canonical synonyms by prefix/word boundary
        for (synonym, id) in canonicalNutrientSynonyms {
            if nameOnly == synonym {
                return id
            }
        }
        return nil
    }

    // MARK: - 6. Nutrient Row, Inline Weight, & Added Sugars Parser (Part 1.2.6, 3.2, 3.3, 3.4)

    /// Parses a table row (represented as an array of cell strings across columns) into one or more `ParsedNutrientRow` values.
    /// Supports:
    /// - Standard 2-column vertical rows (`["Total Fat 8g", "10%"]`)
    /// - Separate-column weight rows (`["Total Fat", "8g", "10%"]`)
    /// - Dual-column & Tabular rows (`["Total Fat", "5g", "6%", "10g", "13%"]` or `["Total Fat 1.5g", "2%", "Total Carbohydrate 36g", "13%"]`)
    /// - Inline `"Includes [X]g Added Sugars"` and `"Incl. [X]g Added Sugars"` syntax
    /// - Side-by-side micronutrient rows (`["Vit. D 2mcg 10%", "Calcium 260mg 20%"]`) and bullet-delimited horizontal micronutrient footers (`"Vitamin D 0mcg 0% • Calcium 80mg 6%"`)
    static func parseNutrientRow(
        cells: [String],
        isSupplement: Bool = false,
        defaultColumnIndex: Int = 0
    ) -> [ParsedNutrientRow] {
        let nonEmptyCells = cells
            .map { stripDotLeaders($0) }
            .filter { !$0.isEmpty }
        guard !nonEmptyCells.isEmpty else { return [] }

        let joinedLine = nonEmptyCells.joined(separator: " ")
        guard !isDecoyComparativeString(joinedLine), !isMandatoryBoxedWarning(joinedLine) else {
            return []
        }

        // 1. Check if any cell contains bullet-delimited horizontal micronutrients (Archetypes A & K)
        if joinedLine.contains("•") {
            let bulletSegments = joinedLine
                .components(separatedBy: "•")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if bulletSegments.count > 1 {
                return bulletSegments.flatMap { parseSingleInlineSegment($0, isSupplement: isSupplement, columnIndex: defaultColumnIndex) }
            }
        }

        // 2. Check for Tabular Horizontal parallel nutrient stacks (e.g., ["Total Fat 1.5g", "2%", "Total Carbohydrate 36g", "13%"])
        if nonEmptyCells.count >= 2 {
            var distinctNutrientCellIndices: [Int] = []
            for (idx, cell) in nonEmptyCells.enumerated() {
                if resolveNutrientID(from: cell) != nil {
                    distinctNutrientCellIndices.append(idx)
                }
            }
            if distinctNutrientCellIndices.count >= 2 {
                var results: [ParsedNutrientRow] = []
                for (i, startIdx) in distinctNutrientCellIndices.enumerated() {
                    let endIdx = (i + 1 < distinctNutrientCellIndices.count) ? distinctNutrientCellIndices[i + 1] : nonEmptyCells.count
                    let slice = Array(nonEmptyCells[startIdx..<endIdx])
                    results.append(contentsOf: parseSingleNutrientSlice(cells: slice, isSupplement: isSupplement, defaultColumnIndex: defaultColumnIndex))
                }
                return results
            }
        }

        return parseSingleNutrientSlice(cells: nonEmptyCells, isSupplement: isSupplement, defaultColumnIndex: defaultColumnIndex)
    }

    /// Parses a `"Not a significant source of ..."` footer statement (`21 CFR § 101.9(f)(4)`) into the set of omitted `CanonicalNutrientID`s.
    static func parseInsignificantSourceFooter(_ text: String) -> Set<CanonicalNutrientID> {
        let lower = expandAuthorizedAbbreviations(text)
        guard let range = lower.range(of: "not a significant source of") else {
            return []
        }
        let tail = String(lower[range.upperBound...])
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "\\band\\b", with: ",", options: .regularExpression)
            .replacingOccurrences(of: "\\bor\\b", with: ",", options: .regularExpression)

        var omittedSet: Set<CanonicalNutrientID> = []
        for token in tail.components(separatedBy: ",") {
            let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
            if let id = resolveNutrientID(from: cleaned) {
                omittedSet.insert(id)
            } else if cleaned == "calories from saturated fat" || cleaned == "saturated fat calories" {
                omittedSet.insert(.caloriesFromSaturatedFat)
            }
        }
        return omittedSet
    }

    /// Parses a small-package Linear Display panel (`21 CFR § 101.9(j)(13)(ii)(A)(2)`, Archetype L) into a `ParsedServingSize` and array of `ParsedNutrientRow`s.
    static func parseLinearDisplayPanel(
        _ text: String,
        isSupplement: Bool = false
    ) -> (servingSize: ParsedServingSize?, rows: [ParsedNutrientRow]) {
        let normalized = text
            .replacingOccurrences(of: "<br>", with: " ", options: .caseInsensitive)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var parsedServing: ParsedServingSize? = nil
        if let servRange = normalized.range(of: "(?:serv\\.?\\s*size|serving\\s*size)\\s*:?\\s*([^,]+)", options: [.regularExpression, .caseInsensitive]) {
            let servSub = String(normalized[servRange])
            parsedServing = parseServingSize(from: servSub, isSupplement: isSupplement)
        }

        let bodyText: String
        if let amountRange = normalized.range(of: "amount\\s*(?:per|/)\\s*serving\\s*:?", options: [.regularExpression, .caseInsensitive]) {
            bodyText = String(normalized[amountRange.upperBound...])
        } else {
            bodyText = normalized
        }

        // Split on commas Outside parentheses so "(Incl. 2g Added Sugars, 4% DV)" stays intact first
        var segments: [String] = []
        var current = ""
        var parenDepth = 0
        for ch in bodyText {
            if ch == "(" { parenDepth += 1 }
            else if ch == ")" { parenDepth = max(0, parenDepth - 1) }

            if ch == "," && parenDepth == 0 {
                segments.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(ch)
            }
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            segments.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        var rows: [ParsedNutrientRow] = []
        for seg in segments {
            // Check for nested "(Incl. 2g Added Sugars, 4% DV)" inside a Total Sugars linear segment
            if let inclRange = seg.range(of: "\\(\\s*(?:incl\\.?|includes)\\s+[^)]+added\\s+sugars[^)]*\\)", options: [.regularExpression, .caseInsensitive]) {
                let outerSeg = seg.replacingCharacters(in: inclRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let innerSeg = String(seg[inclRange])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "() "))
                rows.append(contentsOf: parseSingleInlineSegment(outerSeg, isSupplement: isSupplement, columnIndex: 0))
                rows.append(contentsOf: parseSingleInlineSegment(innerSeg, isSupplement: isSupplement, columnIndex: 0))
            } else {
                rows.append(contentsOf: parseSingleInlineSegment(seg, isSupplement: isSupplement, columnIndex: 0))
            }
        }
        return (parsedServing, rows)
    }

    // MARK: - 7. Serving Size, Fraction, & Household Measure Parser (Part 1.4.1 & Part 3.1)

    /// Map of Unicode vulgar fraction characters to their decimal values.
    static let unicodeFractionMap: [Character: Double] = [
        "¼": 0.25,
        "½": 0.5,
        "¾": 0.75,
        "⅓": 0.33,
        "⅔": 0.67,
        "⅕": 0.2,
        "⅖": 0.4,
        "⅗": 0.6,
        "⅘": 0.8,
        "⅙": 0.17,
        "⅚": 0.83,
        "⅛": 0.125,
        "⅜": 0.375,
        "⅝": 0.625,
        "⅞": 0.875
    ]

    /// Parses decimal numbers (`"2.5"`), vulgar fractions (`"1/4"` -> `0.25`, `"1/3"` -> `0.33`, `"2/3"` -> `0.67`), mixed fractions (`"1 1/2"` -> `1.5`), and Unicode fraction glyphs (`¼`, `½`, `¾`, `⅓`, `⅔`) into a `Double`.
    static func parseFractionOrNumber(_ rawToken: String) -> Double? {
        var token = rawToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "⁄", with: "/") // Unicode fraction slash

        guard !token.isEmpty else { return nil }

        // 1. Check for single Unicode fraction character or mixed number ending with Unicode fraction (e.g. "1½")
        for (glyph, fracVal) in unicodeFractionMap {
            if token == String(glyph) {
                return fracVal
            }
            if token.hasSuffix(String(glyph)) {
                let prefix = token.dropLast().trimmingCharacters(in: .whitespaces)
                if let whole = Double(prefix) {
                    return whole + fracVal
                }
            }
        }

        // 2. Check for mixed fraction "W N/D" (e.g. "1 1/2", "1 1/3", "1 2/3")
        let mixedPattern = "^(\\d+)\\s+(\\d+)\\s*/\\s*(\\d+)$"
        if let regex = try? NSRegularExpression(pattern: mixedPattern),
           let match = regex.firstMatch(in: token, range: NSRange(token.startIndex..., in: token)),
           let wRange = Range(match.range(at: 1), in: token),
           let nRange = Range(match.range(at: 2), in: token),
           let dRange = Range(match.range(at: 3), in: token),
           let whole = Double(token[wRange]),
           let num = Double(token[nRange]),
           let den = Double(token[dRange]),
           den > 0 {
            return whole + roundCommonThirdsFraction(numerator: num, denominator: den)
        }

        // 3. Check for vulgar fraction "N/D" (e.g. "1/4", "1/3", "1/2", "2/3", "3/4")
        let vulgarPattern = "^(\\d+)\\s*/\\s*(\\d+)$"
        if let regex = try? NSRegularExpression(pattern: vulgarPattern),
           let match = regex.firstMatch(in: token, range: NSRange(token.startIndex..., in: token)),
           let nRange = Range(match.range(at: 1), in: token),
           let dRange = Range(match.range(at: 2), in: token),
           let num = Double(token[nRange]),
           let den = Double(token[dRange]),
           den > 0 {
            return roundCommonThirdsFraction(numerator: num, denominator: den)
        }

        // 4. Plain decimal or integer
        token = token.replacingOccurrences(of: ",", with: "")
        return Double(token)
    }

    /// Normalizes any gram or milliliter unit spelling strictly to `"g"` or `"ml"` for `AddFoodView`'s segmented/menu picker.
    static func normalizeServingMetricUnit(_ rawUnit: String) -> String? {
        let lower = rawUnit
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,()")))
            .lowercased()
        switch lower {
        case "g", "gram", "grams", "gm", "gms", "gr":
            return "g"
        case "ml", "milliliter", "milliliters", "millilitre", "millilitres":
            return "ml"
        default:
            return nil
        }
    }

    /// Parses an FDA `"Serving size"` line (and optional `"Servings per container"` line) into a `ParsedServingSize` model (`21 CFR § 101.9(b)` & `§ 101.36(b)(1)`).
    static func parseServingSize(
        from rawServingSizeText: String,
        servingsPerContainerText: String? = nil,
        isSupplement: Bool = false
    ) -> ParsedServingSize? {
        var working = rawServingSizeText
            .replacingOccurrences(of: "<br>", with: " ", options: .caseInsensitive)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !working.isEmpty else { return nil }

        // 1. Parse optional servings per container & modifier ("about", "usually", "varied")
        var parsedServingsPerContainer: Double? = nil
        var parsedServingsModifier: String? = nil
        if let containerText = servingsPerContainerText {
            let (count, modifier) = parseServingsPerContainerClause(containerText)
            parsedServingsPerContainer = count
            parsedServingsModifier = modifier
        } else if working.lowercased().contains("servings per container") || working.lowercased().contains("serving per container") {
            let (count, modifier) = parseServingsPerContainerClause(working)
            parsedServingsPerContainer = count
            parsedServingsModifier = modifier
            working = working.replacingOccurrences(
                of: "(?:about|usually|varied)?\\s*\\d*(?:\\.\\d+)?\\s*servings?\\s+per\\s+container",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 2. Extract and strip Supplement Facts "Per Day" multiplier parentheticals (§ 101.36(e)(9))
        var perDayMultiplier: Int? = nil
        let multiplyPatterns = [
            "\\(\\s*multiply\\s+amounts\\s+by\\s+(\\d+)[^)]*\\)",
            "\\(\\s*total\\s+daily\\s+amount\\s*:\\s*(\\d+)[^)]*\\)"
        ]
        for pattern in multiplyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: working, range: NSRange(working.startIndex..., in: working)),
               let fullRange = Range(match.range(at: 0), in: working),
               let multRange = Range(match.range(at: 1), in: working),
               let mult = Int(working[multRange]) {
                perDayMultiplier = mult
                working.removeSubrange(fullRange)
            }
        }

        // 3. Strip prepared-product parenthetical suffixes (§ 101.9(b)(7)(v), e.g. "(makes 1 cup prepared)")
        let preparedSuffixPattern = "\\(\\s*makes\\b[^)]*\\)"
        working = working.replacingOccurrences(
            of: preparedSuffixPattern,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // 4. Strip leading "Serving size", "Serv. size", "Each [Unit] Contains", "Amount Per [N] [Units]"
        if let regex = try? NSRegularExpression(
            pattern: "^(?:serving\\s+size|serv\\.?\\s+size|tamaño\\s+de\\s+la\\s+porción|tamano\\s+de\\s+la\\s+porcion)\\s*:?\\s*",
            options: [.caseInsensitive]
        ) {
            let range = NSRange(working.startIndex..., in: working)
            working = regex.stringByReplacingMatches(in: working, options: [], range: range, withTemplate: "")
        } else if isSupplement {
            if let eachMatch = working.range(of: "^each\\s+([a-z]+)\\s+contains\\b", options: [.regularExpression, .caseInsensitive]) {
                let header = String(working[eachMatch])
                let unitWord = header
                    .replacingOccurrences(of: "^each\\s+", with: "", options: [.regularExpression, .caseInsensitive])
                    .replacingOccurrences(of: "\\s+contains$", with: "", options: [.regularExpression, .caseInsensitive])
                working = "1 \(unitWord)"
            } else if let amountPerMatch = working.range(of: "^amount\\s+per\\s+(\\d+\\s+[a-z]+)", options: [.regularExpression, .caseInsensitive]) {
                let header = String(working[amountPerMatch])
                working = header.replacingOccurrences(of: "^amount\\s+per\\s+", with: "", options: [.regularExpression, .caseInsensitive])
            }
        }

        working = working.trimmingCharacters(in: CharacterSet(charactersIn: " :,-"))

        // 5. Extract parenthetical metric weight/volume: e.g. "(225g)", "(240 mL)", "(28g/1 oz)", "(28 g/about 1/2 pickle)"
        var metricValue: Double? = nil
        var metricUnit: String? = nil
        var householdPart = working

        let metricParenPattern = "\\(\\s*(?:about\\s+|approx\\.?\\s+)?(\\d+(?:\\.\\d+)?)\\s*(g|grams?|gm|ml|milliliters?|millilitres?)(?:\\s*/[^)]*)?\\s*\\)"
        if let regex = try? NSRegularExpression(pattern: metricParenPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: working, range: NSRange(working.startIndex..., in: working)),
           let fullRange = Range(match.range(at: 0), in: working),
           let numRange = Range(match.range(at: 1), in: working),
           let unitRange = Range(match.range(at: 2), in: working),
           let val = Double(working[numRange]),
           let normUnit = normalizeServingMetricUnit(String(working[unitRange])) {
            metricValue = val
            metricUnit = normUnit
            householdPart.removeSubrange(fullRange)
        } else {
            // Check for parenthetical household volume/weight in single-serving containers, e.g. "1 can (12 fl oz)"
            let fallbackParenPattern = "\\(\\s*(\\d+(?:\\.\\d+)?)\\s*(fl\\.?\\s*oz\\.?|fluid\\s+ounces?|oz\\.?|ounces?|cups?|tbsp|tsp)\\s*\\)"
            if let regex = try? NSRegularExpression(pattern: fallbackParenPattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: working, range: NSRange(working.startIndex..., in: working)),
               let fullRange = Range(match.range(at: 0), in: working),
               let numRange = Range(match.range(at: 1), in: working),
               let unitRange = Range(match.range(at: 2), in: working),
               let val = Double(working[numRange]),
               let converted = FDARegulatoryConstants.metricEquivalent(forHouseholdUnit: String(working[unitRange]), amount: val) {
                metricValue = converted.metricAmount
                metricUnit = converted.metricUnit
                householdPart.removeSubrange(fullRange)
            }
        }

        // 6. Parse household quantity and household unit from `householdPart`
        let (hhAmount, hhUnit) = parseHouseholdQuantityAndUnit(from: householdPart)

        // 7. Resolve metric fallback when parenthetical (g/mL) is omitted (§ 101.9(b)(7)(i) & § 101.36(b)(1))
        var usedFallback = false
        if metricValue == nil {
            if let hhAmount, let hhUnit {
                // Direct metric unit on serving line (e.g. "Serving size: 32g")
                if let directMetricUnit = normalizeServingMetricUnit(hhUnit) {
                    return ParsedServingSize(
                        servingSize: hhAmount,
                        servingUnit: directMetricUnit,
                        commonHouseholdMeasurementAmount: nil,
                        commonHouseholdMeasurement: nil,
                        servingsPerContainer: parsedServingsPerContainer,
                        servingsPerContainerModifier: parsedServingsModifier,
                        perDayMultiplier: perDayMultiplier,
                        usedMetricFallbackConversion: false
                    )
                }
                // Standard FDA household-to-metric conversion (1 cup = 240 ml, 1 fl oz = 30 ml, 1 oz = 28 g, 1 tbsp = 15 ml, 1 tsp = 5 ml)
                if let converted = FDARegulatoryConstants.metricEquivalent(forHouseholdUnit: hhUnit, amount: hhAmount) {
                    metricValue = converted.metricAmount
                    metricUnit = converted.metricUnit
                    usedFallback = true
                } else {
                    // Discrete supplement or single-serving unit without weight ("2 Capsules" -> servingSize = 2.0)
                    metricValue = hhAmount
                    metricUnit = "g"
                    usedFallback = true
                }
            } else {
                return nil
            }
        }

        return ParsedServingSize(
            servingSize: metricValue ?? 0.0,
            servingUnit: metricUnit ?? "g",
            commonHouseholdMeasurementAmount: hhAmount,
            commonHouseholdMeasurement: hhUnit,
            servingsPerContainer: parsedServingsPerContainer,
            servingsPerContainerModifier: parsedServingsModifier,
            perDayMultiplier: perDayMultiplier,
            usedMetricFallbackConversion: usedFallback
        )
    }

    // MARK: - 8. Topology Classifier Helper

    /// Classifies the `FDALabelTopology` from raw panel text lines and observed column count.
    static func classifyTopology(fromLines lines: [String], tableColumnCount: Int = 2) -> FDALabelTopology {
        let joined = lines.joined(separator: " ").lowercased()

        if joined.contains("supplement facts") {
            return .supplementFacts
        }
        if joined.contains("not a significant source of")
            && (!joined.contains("saturated fat") || !joined.contains("cholesterol") || !joined.contains("dietary fiber")) {
            return .simplified
        }
        if tableColumnCount == 0 || (lines.count <= 3 && joined.contains("serv. size:") && joined.contains("total carb.")) {
            return .linearString
        }
        let amountPerServingOccurrences = joined.components(separatedBy: "amount/serving").count - 1
        if amountPerServingOccurrences >= 2 {
            if joined.contains("about") && joined.contains("sat. fat") {
                return .smallPackageTabular
            }
            return .tabularHorizontal
        }
        if joined.contains("per serving") && joined.contains("per container") {
            return tableColumnCount >= 8 ? .tabularDualColumn : .dualColumnPerContainer
        }
        if tableColumnCount >= 4 {
            if joined.contains("dry mix") || joined.contains("prepared") || joined.contains("baked") || joined.contains("with milk") {
                return .dualColumnSameFood
            }
            if joined.contains("per 1 ") || joined.contains("per unit") {
                return .dualColumnPerUnit
            }
            if !joined.contains("per ") {
                return .aggregateVariety
            }
            return .dualColumnSameFood
        }
        if joined.contains("•") || (joined.contains("vit. d") && joined.contains("potas.")) {
            return .sideBySideMicronutrients
        }
        return .standardVertical
    }

    // MARK: - Private Lexical Helpers

    private static func roundCommonThirdsFraction(numerator: Double, denominator: Double) -> Double {
        let ratio = numerator / denominator
        if abs(ratio - (1.0 / 3.0)) < 0.001 {
            return 0.33
        }
        if abs(ratio - (2.0 / 3.0)) < 0.001 {
            return 0.67
        }
        if abs(ratio - (1.0 / 6.0)) < 0.001 {
            return 0.17
        }
        if abs(ratio - (5.0 / 6.0)) < 0.001 {
            return 0.83
        }
        return (ratio * 1000.0).rounded() / 1000.0
    }

    private static func parseServingsPerContainerClause(_ text: String) -> (count: Double?, modifier: String?) {
        let lower = text.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        var detectedModifier: String? = nil
        for mod in ["about", "usually", "varied"] {
            if lower.range(of: "\\b\(mod)\\b", options: .regularExpression) != nil {
                detectedModifier = mod
                break
            }
        }
        // Check "Servings: 12" or "8 servings per container" or "about 3.5 servings"
        let patterns = [
            "(\\d+(?:\\.\\d+)?)\\s*servings?",
            "servings?(?:\\s+per\\s+container)?\\s*:?\\s*(?:about\\s+|usually\\s+)?(\\d+(?:\\.\\d+)?)"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
               let r = Range(match.range(at: 1), in: lower),
               let val = Double(lower[r]) {
                return (val, detectedModifier)
            }
        }
        return (nil, detectedModifier)
    }

    private static func parseHouseholdQuantityAndUnit(from rawHouseholdPart: String) -> (amount: Double?, unit: String?) {
        var cleaned = rawHouseholdPart
            .replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,.:;-"))

        // Strip leading approximation modifiers ("about", "approx.", "approximately", "usually", "varied")
        let modifierPattern = "^(?:about|approx\\.?|approximately|usually|varied)\\s+"
        cleaned = cleaned.replacingOccurrences(of: modifierPattern, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return (nil, nil) }

        // Match leading mixed fraction, vulgar fraction, Unicode fraction, or decimal number
        let leadingNumberPattern = "^(\\d+\\s+\\d+\\s*/\\s*\\d+|\\d+\\s*/\\s*\\d+|\\d*[¼½¾⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]|\\d+(?:\\.\\d+)?)\\s*(.*)$"
        if let regex = try? NSRegularExpression(pattern: leadingNumberPattern),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let numRange = Range(match.range(at: 1), in: cleaned),
           let unitRange = Range(match.range(at: 2), in: cleaned),
           let amount = parseFractionOrNumber(String(cleaned[numRange])) {
            let unitRaw = String(cleaned[unitRange])
                .trimmingCharacters(in: CharacterSet(charactersIn: " ,.:;-"))
            let unitCleaned = normalizeHouseholdUnitString(unitRaw)
            return (amount, unitCleaned.isEmpty ? nil : unitCleaned)
        }
        return (nil, nil)
    }

    private static func normalizeHouseholdUnitString(_ rawUnit: String) -> String {
        let trimmed = rawUnit
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ."))
        guard !trimmed.isEmpty else { return "" }
        // Check if MeasurementUnitCatalog has a canonical definition (preserving common plural or singular forms cleanly)
        if let def = MeasurementUnitCatalog.definition(for: trimmed) {
            return def.name
        }
        return trimmed
    }

    private static func stripInlineQuantitiesAndUnits(from expandedText: String) -> String {
        var s = expandedText
        // Repair common OCR glyph swaps on numeric-unit tokens ("Omcg" -> "0mcg", "Omg" -> "0mg", "Og" -> "0g", "O%" -> "0%", "lmg" -> "1mg") prior to stripping
        s = s.replacingOccurrences(
            of: "\\b[oO]\\s*(?:(mcg\\s*dfe|mcg\\s*rae|mg\\s*ne|mcg|µg|ug|mg|g|iu)\\b|(%))",
            with: "0$1$2",
            options: [.regularExpression, .caseInsensitive]
        )
        s = s.replacingOccurrences(
            of: "\\b[lI]\\s*(mcg\\s*dfe|mcg\\s*rae|mg\\s*ne|mcg|µg|ug|mg|g|iu)\\b",
            with: "1$1",
            options: [.regularExpression, .caseInsensitive]
        )
        s = s.replacingOccurrences(
            of: "(\\d+(?:\\.\\d+)?)\\s*q\\b",
            with: "$1g",
            options: [.regularExpression, .caseInsensitive]
        )
        // Strip parenthetical quantities like "(80 iu)" or "(120mcg folic acid)" but keep vitamin synonyms like "(vitamin b1)"
        s = s.replacingOccurrences(
            of: "\\(\\s*\\d+[^)]*\\)",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // Strip "includes [X]g" prefix if present before "added sugars"
        s = s.replacingOccurrences(
            of: "^(?:includes|incl\\.?)\\s+(?:(?:contains\\s+)?less\\s+than\\s+|<?\\s*)?\\d*(?:\\.\\d+)?\\s*(?:g|grams?|mg)?\\s*",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // Strip threshold expressions and trailing numbers/units (note: '%' is a non-word character so it must not require a trailing \b)
        s = s.replacingOccurrences(
            of: "\\b(?:contains\\s+)?less\\s+than\\s+\\d+(?:\\.\\d+)?\\s*(?:(?:grams?|milligrams?|mcg|µg|ug|g|mg)\\b|%)?",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        s = s.replacingOccurrences(
            of: "<?\\s*\\d+(?:\\.\\d+)?\\s*(?:(?:mcg\\s+dfe|mcg\\s+rae|mg\\s+ne|grams?|milligrams?|mcg|µg|ug|mg|g|iu|kcal|cal|kj)\\b|%)",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        s = s.replacingOccurrences(of: "\\b\\d+(?:\\.\\d+)?\\b$", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: CharacterSet(charactersIn: " :,-*†‡."))
    }

    private static func parseSingleInlineSegment(
        _ segment: String,
        isSupplement: Bool,
        columnIndex: Int
    ) -> [ParsedNutrientRow] {
        parseSingleNutrientSlice(cells: [segment], isSupplement: isSupplement, defaultColumnIndex: columnIndex)
    }

    private static func parseSingleNutrientSlice(
        cells: [String],
        isSupplement: Bool,
        defaultColumnIndex: Int
    ) -> [ParsedNutrientRow] {
        guard let firstCell = cells.first else { return [] }

        let (cleanedFirst, sourceCompound, betaCarotenePct, folicAcidMcg) = stripSupplementSourceCompounds(firstCell)
        let joinedCells = ([cleanedFirst] + cells.dropFirst()).joined(separator: " | ")

        // Special Case 1: Inline "Includes [X]g Added Sugars" or "Incl. Added Sugars"
        if cleanedFirst.lowercased().contains("added sugar") {
            if cells.count >= 3 {
                let tailCells = Array(cells.dropFirst())
                let columnPairs = extractMultiColumnPairs(from: tailCells, for: .addedSugars)
                if columnPairs.count >= 2 {
                    return columnPairs.enumerated().map { idx, pair in
                        ParsedNutrientRow(
                            nutrient: .addedSugars,
                            rawName: firstCell,
                            amount: pair.amount,
                            percentDV: pair.percentDV,
                            indentationLevel: .level2,
                            sourceCompoundDescription: nil,
                            columnIndex: idx
                        )
                    }
                }
            }
            if let addedRow = parseAddedSugarsRow(cells: [cleanedFirst] + Array(cells.dropFirst()), columnIndex: defaultColumnIndex) {
                return [addedRow]
            }
        }

        guard let nutrientID = resolveNutrientID(from: cleanedFirst) else {
            return []
        }

        // Multi-column detection when cells contain multiple (Weight, %DV) pairs, merged "40mcg DFE 10%" cells, or %DV-only micronutrient columns
        if cells.count >= 3 {
            let tailCells = Array(cells.dropFirst())
            let columnPairs = extractMultiColumnPairs(from: tailCells, for: nutrientID)
            if columnPairs.count >= 2 {
                var multiRows: [ParsedNutrientRow] = []
                for (idx, pair) in columnPairs.enumerated() {
                    multiRows.append(
                        ParsedNutrientRow(
                            nutrient: nutrientID,
                            rawName: firstCell,
                            amount: pair.amount,
                            percentDV: pair.percentDV,
                            indentationLevel: nutrientID.indentationLevel,
                            sourceCompoundDescription: sourceCompound,
                            columnIndex: idx
                        )
                    )
                    if let folicAcidMcg {
                        multiRows.append(
                            ParsedNutrientRow(
                                nutrient: .folicAcid,
                                rawName: "Folic Acid",
                                amount: .exact(value: folicAcidMcg, unit: .mcg),
                                percentDV: .omitted,
                                indentationLevel: .level1,
                                sourceCompoundDescription: nil,
                                columnIndex: idx
                            )
                        )
                    }
                    if let betaCarotenePct {
                        multiRows.append(
                            ParsedNutrientRow(
                                nutrient: .betaCarotenePercentage,
                                rawName: "Beta-Carotene",
                                amount: .exact(value: betaCarotenePct, unit: .percent),
                                percentDV: .omitted,
                                indentationLevel: .level1,
                                sourceCompoundDescription: nil,
                                columnIndex: idx
                            )
                        )
                    }
                }
                return multiRows
            }
        }

        // Standard single-column extraction across `cells`
        let amount = extractDeclaredAmount(from: joinedCells, for: nutrientID)
        let percentDV = extractDeclaredPercentDV(from: cells, for: nutrientID)

        var rows: [ParsedNutrientRow] = [
            ParsedNutrientRow(
                nutrient: nutrientID,
                rawName: firstCell,
                amount: amount,
                percentDV: percentDV,
                indentationLevel: nutrientID.indentationLevel,
                sourceCompoundDescription: sourceCompound,
                columnIndex: defaultColumnIndex
            )
        ]

        if let folicAcidMcg {
            rows.append(
                ParsedNutrientRow(
                    nutrient: .folicAcid,
                    rawName: "Folic Acid",
                    amount: .exact(value: folicAcidMcg, unit: .mcg),
                    percentDV: .omitted,
                    indentationLevel: .level1,
                    sourceCompoundDescription: nil,
                    columnIndex: defaultColumnIndex
                )
            )
        }
        if let betaCarotenePct {
            rows.append(
                ParsedNutrientRow(
                    nutrient: .betaCarotenePercentage,
                    rawName: "Beta-Carotene",
                    amount: .exact(value: betaCarotenePct, unit: .percent),
                    percentDV: .omitted,
                    indentationLevel: .level1,
                    sourceCompoundDescription: nil,
                    columnIndex: defaultColumnIndex
                )
            )
        }

        return rows
    }

    private static func parseAddedSugarsRow(cells: [String], columnIndex: Int) -> ParsedNutrientRow? {
        let joined = cells.joined(separator: " ")
        let amount = extractDeclaredAmount(from: joined, for: .addedSugars)
        let percentDV = extractDeclaredPercentDV(from: cells, for: .addedSugars)
        return ParsedNutrientRow(
            nutrient: .addedSugars,
            rawName: cells.first ?? "Added Sugars",
            amount: amount,
            percentDV: percentDV,
            indentationLevel: .level2,
            sourceCompoundDescription: nil,
            columnIndex: columnIndex
        )
    }

    private static func extractMultiColumnPairs(
        from tailCells: [String],
        for nutrient: CanonicalNutrientID
    ) -> [(amount: DeclaredNutrientAmount, percentDV: DeclaredPercentDV)] {
        var pairs: [(amount: DeclaredNutrientAmount, percentDV: DeclaredPercentDV)] = []
        var i = 0
        while i < tailCells.count {
            let cell = tailCells[i]
            let amt = extractDeclaredAmount(from: cell, for: nutrient)
            let sameCellDV = extractDeclaredPercentDV(from: [cell], for: nutrient)

            if amt != .omitted {
                // Case 1: Cell already contains both weight and % DV (e.g., "40mcg DFE 10%" in Example M)
                if sameCellDV != .omitted {
                    pairs.append((amt, sameCellDV))
                    i += 1
                    continue
                }
                // Case 2: Weight in `tailCells[i]`, optional % DV in `tailCells[i + 1]`
                var dv: DeclaredPercentDV = .omitted
                if i + 1 < tailCells.count {
                    let nextCell = tailCells[i + 1]
                    let nextAmt = extractDeclaredAmount(from: nextCell, for: nutrient)
                    let candidateDV = extractDeclaredPercentDV(from: [nextCell], for: nutrient)
                    if nextAmt == .omitted && (candidateDV != .omitted || nextCell.trimmingCharacters(in: .whitespaces).isEmpty) {
                        dv = candidateDV
                        i += 2
                        pairs.append((amt, dv))
                        continue
                    }
                }
                pairs.append((amt, dv))
                i += 1
            } else if sameCellDV != .omitted && nutrient.isMicronutrientRDI {
                // Case 3: % DV-only micronutrient cell in multi-column table (Examples E & M, e.g., ["Thiamin", "70%", "70%"])
                pairs.append((.omitted, sameCellDV))
                i += 1
            } else {
                i += 1
            }
        }
        return pairs
    }

    /// Extracts a `DeclaredNutrientAmount` from a raw cell or joined row transcript, handling OCR glyph swaps (`O` -> `0`, `l` -> `1`, `9`/`q` -> `g`) and threshold strings (`<1g`, `<0.5g`, `<5mg`).
    static func extractDeclaredAmount(
        from rawText: String,
        for nutrient: CanonicalNutrientID
    ) -> DeclaredNutrientAmount {
        // Remove vitamin designators ("Vitamin B6", "Vitamin B12", "Vitamin B1", "Vitamin B2", "Vitamin D3", "Vitamin K2") so their digits are never misread as weights
        let sanitized = rawText.replacingOccurrences(
            of: "\\b(?:vitamin|vit\\.?)\\s*[bdk][-\\s]?\\d+\\b",
            with: "vitamin",
            options: [.regularExpression, .caseInsensitive]
        )
        let lower = sanitized.lowercased()

        // 1. Check for threshold strings first
        if lower.range(of: "(?:contains\\s+)?less\\s+than\\s+1\\s*(?:gram|g)\\b|<\\s*1\\s*(?:gram|g)\\b", options: .regularExpression) != nil {
            return .threshold(.lessThanOneGram, unit: .g)
        }
        if lower.range(of: "(?:contains\\s+)?less\\s+than\\s+0\\.5\\s*(?:gram|g)\\b|<\\s*0\\.5\\s*(?:gram|g)\\b", options: .regularExpression) != nil {
            return .threshold(.lessThanHalfGram, unit: .g)
        }
        if lower.range(of: "(?:contains\\s+)?less\\s+than\\s+5\\s*(?:milligrams?|mg)\\b|<\\s*5\\s*(?:milligrams?|mg)\\b", options: .regularExpression) != nil {
            return .threshold(.lessThanFiveMilligrams, unit: .mg)
        }
        if (nutrient == .calories || nutrient == .caloriesFromSaturatedFat)
            && lower.range(of: "(?:less\\s+than|<)\\s*5\\b", options: .regularExpression) != nil {
            return .threshold(.lessThanFiveCalories, unit: .kcal)
        }

        // 2. Check for calories (unitless integer or followed by cal/kcal)
        if nutrient == .calories || nutrient == .caloriesFromSaturatedFat || nutrient == .caloriesFromFat {
            let calStripped = lower.replacingOccurrences(
                of: "\\b\\d+(?:\\.\\d+)?\\s*%",
                with: "",
                options: .regularExpression
            )
            if let regex = try? NSRegularExpression(pattern: "\\b([oO0-9]+)\\b"),
               let match = regex.firstMatch(in: calStripped, range: NSRange(calStripped.startIndex..., in: calStripped)),
               let r = Range(match.range(at: 1), in: calStripped) {
                let token = String(calStripped[r])
                    .replacingOccurrences(of: "o", with: "0")
                    .replacingOccurrences(of: "O", with: "0")
                if let val = Double(token) {
                    return val == 0.0 ? .explicitZero(unit: .kcal) : .exact(value: val, unit: .kcal)
                }
            }
            return .omitted
        }

        // 3. Repair classic OCR glyph swaps before unit matching ("Omcg" -> "0mcg", "0g" vs "Og", "lmg" -> "1mg")
        let ocrNormalized = normalizeOCRNumericUnitTokens(in: lower, for: nutrient)

        // 4. Match primary numeric weight + unit (and optional secondary parenthetical unit like "(80 IU)")
        let quantityUnitPattern = "(\\d+(?:\\.\\d+)?)\\s*(mcg\\s*dfe|mcg\\s*rae|mg\\s*ne|mcg|mg|grams?|g|iu)\\b(?:\\s*\\(\\s*(\\d+(?:\\.\\d+)?)\\s*(iu|mcg|mg)\\s*\\))?"
        if let regex = try? NSRegularExpression(pattern: quantityUnitPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: ocrNormalized, range: NSRange(ocrNormalized.startIndex..., in: ocrNormalized)),
           let valRange = Range(match.range(at: 1), in: ocrNormalized),
           let unitRange = Range(match.range(at: 2), in: ocrNormalized),
           let value = Double(ocrNormalized[valRange]) {
            let parsedUnit = resolveNutrientUnit(String(ocrNormalized[unitRange]), fallback: nutrient.primaryUnit)
            var secondaryVal: Double? = nil
            var secondaryUnit: NutrientUnit? = nil
            if match.range(at: 3).location != NSNotFound,
               match.range(at: 4).location != NSNotFound,
               let secValRange = Range(match.range(at: 3), in: ocrNormalized),
               let secUnitRange = Range(match.range(at: 4), in: ocrNormalized) {
                secondaryVal = Double(ocrNormalized[secValRange])
                secondaryUnit = resolveNutrientUnit(String(ocrNormalized[secUnitRange]), fallback: .iu)
            }
            if value == 0.0 {
                return .explicitZero(unit: parsedUnit)
            }
            return .exact(value: value, unit: parsedUnit, secondaryValue: secondaryVal, secondaryUnit: secondaryUnit)
        }

        // 5. Check for footnote insignificance marker ("*" or "<2%") when no weight is present
        if lower.contains("less than 2 percent") || lower.contains("<2%") || lower.contains("< 2%") {
            return .insignificantFootnote(symbol: "*", reason: "Contains less than 2 percent of the Daily Value")
        }

        return .omitted
    }

    /// Extracts a `DeclaredPercentDV` from a row's cells.
    static func extractDeclaredPercentDV(
        from cells: [String],
        for nutrient: CanonicalNutrientID
    ) -> DeclaredPercentDV {
        let joined = cells.joined(separator: " ").lowercased()

        if joined.range(of: "(?:less\\s+than|<)\\s*1\\s*%", options: .regularExpression) != nil {
            return .threshold(.lessThanOnePercentDV)
        }
        if joined.range(of: "(?:less\\s+than|<)\\s*2\\s*%", options: .regularExpression) != nil {
            return .threshold(.lessThanTwoPercentDV)
        }

        // Search from rightmost cell to leftmost for `[N]%` (excluding beta-carotene percentage in parentheses)
        for cell in cells.reversed() {
            let strippedBeta = cell.replacingOccurrences(
                of: "\\(\\s*\\d+(?:\\.\\d+)?\\s*%[^)]*beta[-\\s]?carotene[^)]*\\)",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            if let regex = try? NSRegularExpression(pattern: "([oO0-9]+)\\s*%"),
               let match = regex.firstMatch(in: strippedBeta, range: NSRange(strippedBeta.startIndex..., in: strippedBeta)),
               let r = Range(match.range(at: 1), in: strippedBeta) {
                let token = String(strippedBeta[r])
                    .replacingOccurrences(of: "o", with: "0")
                    .replacingOccurrences(of: "O", with: "0")
                if let pct = Int(token) {
                    return .exact(pct)
                }
            }
            let trimmed = cell.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "†" || trimmed == "‡" || trimmed == "*" {
                return .notEstablished(symbol: trimmed)
            }
        }

        return .omitted
    }

    /// Repairs classic OCR glyph confusions on numeric-unit tokens (`Omcg` -> `0mcg`, `Og` -> `0g`, `lmg` -> `1mg`, trailing `9`/`q` misread for `g`).
    static func normalizeOCRNumericUnitTokens(in text: String, for nutrient: CanonicalNutrientID) -> String {
        var s = text
        // "Omcg", "Omg", "Og", "O%" -> "0mcg", "0mg", "0g", "0%"
        s = s.replacingOccurrences(
            of: "\\b[oO]\\s*(?:(mcg\\s*dfe|mcg\\s*rae|mg\\s*ne|mcg|µg|ug|mg|g|iu)\\b|(%))",
            with: "0$1$2",
            options: [.regularExpression, .caseInsensitive]
        )
        // "lmg", "lmcg", "lg" -> "1mg", "1mcg", "1g"
        s = s.replacingOccurrences(
            of: "\\b[lI]\\s*(mcg\\s*dfe|mcg\\s*rae|mg\\s*ne|mcg|µg|ug|mg|g|iu)\\b",
            with: "1$1",
            options: [.regularExpression, .caseInsensitive]
        )
        // For gram-unit nutrients, repair trailing 'q' misread for 'g' after a digit (e.g., "8q" -> "8g")
        if nutrient.primaryUnit == .g {
            s = s.replacingOccurrences(
                of: "(\\d+(?:\\.\\d+)?)\\s*q\\b",
                with: "$1g",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        return s
    }

    private static func resolveNutrientUnit(_ rawUnit: String, fallback: NutrientUnit) -> NutrientUnit {
        let normalized = rawUnit
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized {
        case "g", "gram", "grams":
            return .g
        case "mg", "milligram", "milligrams":
            return .mg
        case "mcg":
            return .mcg
        case "mcg dfe":
            return .mcgDFE
        case "mcg rae":
            return .mcgRAE
        case "mg ne":
            return .mgNE
        case "iu":
            return .iu
        case "kcal", "cal":
            return .kcal
        case "kj":
            return .kJ
        case "%":
            return .percent
        default:
            return fallback
        }
    }
}
