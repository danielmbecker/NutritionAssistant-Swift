import Foundation

// MARK: - FDANutritionValidator (21 CFR § 101.9 & § 101.36 Mathematical Cross-Validation & Self-Healing Engine)

/// Performs demographic inference, unit/glyph disambiguation, `% DV` decimal-shift self-healing, sub-nutrient ceiling checks with legal rounding slop, Atwater 4-4-9 + sugar alcohol caloric validation, and `ScannedNutritionPayload` assembly.
enum FDANutritionValidator {

    // MARK: - 1. Demographic Detection (Part 1.1.9 & Part 3.4)

    /// Automatically infers the active `FDADemographicGroup` from explicit column headers, footnote calorie references (`"1,000 calories"` vs. `"2,000 calories"`), or infant structural rules (`21 CFR § 101.9(j)(5)(i)`).
    static func inferDemographicGroup(
        fromRawTexts rawTexts: [String],
        rows: [ParsedNutrientRow]
    ) -> FDADemographicGroup {
        let joined = rawTexts
            .joined(separator: " ")
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // 1. Explicit multi-demographic column headers or target statements (§ 101.9(e) & § 101.36(b)(2)(iii)(E))
        if joined.contains("pregnant and lactating")
            || joined.contains("pregnant or lactating")
            || joined.contains("pregnant/lactating") {
            return .pregnantAndLactatingWomen
        }
        if joined.contains("infants through 12 months")
            || joined.contains("infants <= 12 months")
            || joined.contains("infants up to 12 months") {
            return .infantsThrough12Months
        }
        if joined.contains("children 1 through 3 years")
            || joined.contains("children 1-3 years")
            || joined.contains("children 1 to 3 years") {
            return .children1Through3Years
        }

        // 2. Footnote calorie diet basis (§ 101.9(d)(9) & (j)(5)(ii))
        if joined.contains("1,000 calories a day")
            || joined.contains("1000 calories a day")
            || joined.contains("1,000 calorie diet")
            || joined.contains("1000 calorie diet") {
            return .children1Through3Years
        }
        if joined.contains("2,000 calories a day")
            || joined.contains("2000 calories a day")
            || joined.contains("2,000 calorie diet")
            || joined.contains("2000 calorie diet") {
            return .adultsAndChildren4OrMoreYears
        }

        // 3. Structural infant signature (§ 101.9(j)(5)(i)):
        // Infant labels must NOT declare % DV for saturatedFat, transFat, cholesterol, sodium, dietaryFiber, totalSugars, or addedSugars,
        // while declaring % DV for totalFat, totalCarbohydrate, or protein (or micronutrients) and omitting the 2,000-calorie footnote.
        let primaryRows = rows.filter { $0.columnIndex == 0 }
        let hasInfantRestrictedDV = primaryRows.contains { row in
            FDARegulatoryConstants.infantProhibitedPercentDVNutrients.contains(row.nutrient)
                && row.percentDV.numericPercent != nil
        }
        let hasInfantPermittedMacroDV = primaryRows.contains { row in
            (row.nutrient == .totalFat || row.nutrient == .totalCarbohydrate || row.nutrient == .protein)
                && row.percentDV.numericPercent != nil
        }
        let hasPresentRestrictedMacroRows = primaryRows.contains { row in
            (row.nutrient == .saturatedFat || row.nutrient == .sodium || row.nutrient == .dietaryFiber || row.nutrient == .addedSugars)
                && row.amount != .omitted
        }

        if !hasInfantRestrictedDV && hasInfantPermittedMacroDV && hasPresentRestrictedMacroRows {
            // Confirm whether the observed % DV on Total Fat / Carb / Protein matches Infant DRVs better than Adult DRVs
            let infantMatches = countDemographicPercentDVMatches(in: primaryRows, demographic: .infantsThrough12Months)
            let adultMatches = countDemographicPercentDVMatches(in: primaryRows, demographic: .adultsAndChildren4OrMoreYears)
            if infantMatches > adultMatches {
                return .infantsThrough12Months
            }
        }

        return .adultsAndChildren4OrMoreYears
    }

    // MARK: - 2. Unit & Glyph Disambiguation (Milestone 3.4.4)

    /// Enforces strict legal units per `CanonicalNutrientID` (`g`, `mg`, `mcg`, `IU`, `mcg DFE`, `mg NE`, `mcg RAE`), repairing OCR unit/glyph confusions (e.g., `mg` misread as `g` on Sodium/Cholesterol/Calcium, or trailing `9` glued to a gram weight like `159` -> `15g` when validated by `% DV`).
    static func enforceLegalUnitAndDisambiguateGlyphs(
        row: ParsedNutrientRow,
        demographic: FDADemographicGroup,
        isSupplement: Bool
    ) -> (updatedRow: ParsedNutrientRow, wasHealed: Bool, diagnostic: ValidationDiagnostic?) {
        var updated = row
        let nutrient = row.nutrient

        guard case .exact(let rawValue, let rawUnit, let secVal, let secUnit) = row.amount else {
            return (updated, false, nil)
        }

        var correctedValue = rawValue
        var correctedUnit = rawUnit
        var healed = false
        var diag: ValidationDiagnostic? = nil

        // 1. Enforce legal unit family for the nutrient (e.g. if OCR read "160g" for Sodium instead of "160mg")
        if !nutrient.allowedUnits.contains(rawUnit) {
            correctedUnit = nutrient.primaryUnit
            healed = true
            diag = ValidationDiagnostic(
                severity: .healed,
                nutrient: nutrient,
                code: "UNIT_COERCION",
                message: "Coerced illegal unit '\(rawUnit.rawValue)' to canonical unit '\(correctedUnit.rawValue)' for \(nutrient.rawValue)."
            )
        }

        // 2. Check for trailing '9' misread from 'g' (e.g., "8g" read as "89" or "1.5g" read as "1.59") when unit is .g
        if correctedUnit == .g && correctedValue >= 10.0 {
            let textRep = String(format: "%g", correctedValue)
            if textRep.hasSuffix("9"), let stripped = Double(textRep.dropLast()), stripped > 0 {
                // Only apply trailing '9' -> 'g' strip if `% DV` confirms `stripped` and rejects `correctedValue`
                if isCandidateConfirmedByPercentDV(
                    candidateValue: stripped,
                    originalValue: correctedValue,
                    unit: correctedUnit,
                    nutrient: nutrient,
                    percentDV: row.percentDV,
                    demographic: demographic,
                    isSupplement: isSupplement
                ) {
                    let oldVal = correctedValue
                    correctedValue = stripped
                    healed = true
                    diag = ValidationDiagnostic(
                        severity: .healed,
                        nutrient: nutrient,
                        code: "GLYPH_TRAILING_9_TO_G",
                        message: "Healed OCR glyph swap '\(oldVal)g' -> '\(correctedValue)g' confirmed by % DV."
                    )
                }
            }
        }

        if healed {
            updated.amount = correctedValue == 0.0
                ? .explicitZero(unit: correctedUnit)
                : .exact(value: correctedValue, unit: correctedUnit, secondaryValue: secVal, secondaryUnit: secUnit)
        }
        return (updated, healed, diag)
    }

    // MARK: - 3. % DV Cross-Check & Conservative Decimal/Glyph Self-Healing (Milestone 3.4.1)

    /// Cross-checks `(ScannedAmount / DRV_or_RDI) * 100 ≈ ScannedPercentDV` and conservatively self-heals `ScannedAmount` ONLY when:
    /// 1. The raw scanned amount fails validation against the legal `% DV` rounding interval, AND
    /// 2. Applying a `0.1x` or `0.01x` decimal shift (`15g` -> `1.5g`) or single-glyph swap (`8` -> `0`, `6` -> `0`) brings the candidate strictly inside the legal rounding interval of the scanned `% DV`.
    static func validateAndHealAgainstPercentDV(
        row: ParsedNutrientRow,
        demographic: FDADemographicGroup,
        isSupplement: Bool
    ) -> (updatedRow: ParsedNutrientRow, wasHealed: Bool, diagnostic: ValidationDiagnostic?) {
        let nutrient = row.nutrient
        guard let scannedPct = row.percentDV.numericPercent,
              let (refVal, _) = FDARegulatoryConstants.dailyReferenceValue(for: nutrient, demographic: demographic),
              refVal > 0 else {
            return (row, false, nil)
        }

        // Check if current declared amount already produces a legal % DV interval containing `scannedPct`
        if let legalPctRange = FDARegulatoryConstants.legalPercentDVInterval(
            for: nutrient,
            declaredAmount: row.amount,
            demographic: demographic,
            isSupplement: isSupplement
        ), legalPctRange.contains(scannedPct) {
            return (row, false, nil)
        }

        // Current amount failed % DV validation. Extract raw numeric value to test conservative healing candidates.
        guard case .exact(let rawValue, let unit, let secVal, let secUnit) = row.amount, rawValue > 0 else {
            return (
                row,
                false,
                ValidationDiagnostic(
                    severity: .warning,
                    nutrient: nutrient,
                    code: "PERCENT_DV_MISMATCH",
                    message: "Declared amount for \(nutrient.rawValue) does not match scanned \(Int(scannedPct))% DV."
                )
            )
        }

        // Build ordered candidate list:
        // (a) 0.1x dropped decimal point (e.g. "15g" -> "1.5g", "25g" -> "2.5g", "45mg" -> "4.5mg")
        // (b) 0.01x dropped decimal point (e.g. "125mg" -> "1.25mg")
        // (c) Single-glyph swap to zero when scanned % DV is 0% (e.g. "8g" or "6g" misread from "0g" with "0% DV")
        var candidates: [(value: Double, reasonCode: String, description: String)] = [
            (rawValue * 0.1, "DECIMAL_SHIFT_0_1X", "0.1x decimal shift (\(rawValue) -> \(rawValue * 0.1))"),
            (rawValue * 0.01, "DECIMAL_SHIFT_0_01X", "0.01x decimal shift (\(rawValue) -> \(rawValue * 0.01))")
        ]

        if scannedPct == 0.0 && (rawValue == 8.0 || rawValue == 6.0 || rawValue == 9.0) {
            candidates.append((0.0, "GLYPH_SWAP_TO_ZERO", "single-glyph zero swap (\(rawValue) -> 0)"))
        }

        // Also test single leading/trailing digit glyph swaps (e.g., '8' <-> '3', '5' <-> '6', '1' <-> '7') if still unmatched
        candidates.append(contentsOf: singleDigitGlyphSwapCandidates(for: rawValue))

        for candidate in candidates {
            let candidateDeclared: DeclaredNutrientAmount = candidate.value == 0.0
                ? .explicitZero(unit: unit)
                : .exact(value: candidate.value, unit: unit, secondaryValue: secVal, secondaryUnit: secUnit)

            if let candidatePctInterval = FDARegulatoryConstants.legalPercentDVInterval(
                for: nutrient,
                declaredAmount: candidateDeclared,
                demographic: demographic,
                isSupplement: isSupplement
            ), candidatePctInterval.contains(scannedPct),
               isFDALegalStepValue(candidate.value, for: nutrient, isSupplement: isSupplement) {
                var healedRow = row
                healedRow.amount = candidateDeclared
                let diag = ValidationDiagnostic(
                    severity: .healed,
                    nutrient: nutrient,
                    code: candidate.reasonCode,
                    message: "Healed \(nutrient.rawValue) via \(candidate.description) to match \(Int(scannedPct))% DV."
                )
                return (healedRow, true, diag)
            }
        }

        let expectedRange = FDARegulatoryConstants.legalPercentDVInterval(
            for: nutrient,
            declaredAmount: row.amount,
            demographic: demographic,
            isSupplement: isSupplement
        )
        let rangeDesc = expectedRange.map { "\(Int($0.lowerBound))%...\(Int($0.upperBound))%" } ?? "N/A"
        return (
            row,
            false,
            ValidationDiagnostic(
                severity: .warning,
                nutrient: nutrient,
                code: "PERCENT_DV_MISMATCH",
                message: "Scanned \(Int(scannedPct))% DV for \(nutrient.rawValue) (\(rawValue)\(unit.rawValue)) falls outside expected \(rangeDesc)."
            )
        )
    }

    // MARK: - 4. Sub-Nutrient Ceiling Invariants with Legal Rounding Slop (Milestone 3.4.2 & Part 1.5.3)

    /// Enforces FDA sub-nutrient ceiling invariants (`Added Sugars <= Total Sugars + Slop`, `Total Sugars <= Total Carbohydrate + Slop`, `Fiber + Sugars + SugarAlcohol <= Total Carbohydrate + Slop`, and `Sat + Trans + Poly + Mono <= Total Fat + Slop`), healing `0.1x` dropped-decimal errors on sub-nutrients when unambiguous.
    static func enforceSubNutrientCeilings(
        nutrients: inout [CanonicalNutrientID: ParsedNutrientRow],
        demographic: FDADemographicGroup,
        isSupplement: Bool
    ) -> (healedNutrients: Set<CanonicalNutrientID>, diagnostics: [ValidationDiagnostic]) {
        var healedSet: Set<CanonicalNutrientID> = []
        var diagnostics: [ValidationDiagnostic] = []

        // Helper to attempt a 0.1x decimal shift on a child nutrient if it exceeds its parent ceiling
        func attemptChildCeilingHeal(
            childID: CanonicalNutrientID,
            parentCeiling: Double,
            tolerance: Double
        ) -> Bool {
            guard let childRow = nutrients[childID],
                  case .exact(let childVal, let unit, let secVal, let secUnit) = childRow.amount,
                  childVal > parentCeiling + tolerance else {
                return false
            }
            let shifted = childVal * 0.1
            guard shifted <= parentCeiling + tolerance,
                  isFDALegalStepValue(shifted, for: childID, isSupplement: isSupplement) else {
                return false
            }
            let candidateAmount: DeclaredNutrientAmount = .exact(
                value: shifted,
                unit: unit,
                secondaryValue: secVal,
                secondaryUnit: secUnit
            )
            // If child also has a % DV, ensure the shifted value does not violate % DV
            if let pct = childRow.percentDV.numericPercent,
               let interval = FDARegulatoryConstants.legalPercentDVInterval(
                   for: childID,
                   declaredAmount: candidateAmount,
                   demographic: demographic,
                   isSupplement: isSupplement
               ),
               !interval.contains(pct) {
                return false
            }
            var updated = childRow
            updated.amount = candidateAmount
            nutrients[childID] = updated
            healedSet.insert(childID)
            diagnostics.append(
                ValidationDiagnostic(
                    severity: .healed,
                    nutrient: childID,
                    code: "CEILING_DECIMAL_SHIFT_HEAL",
                    message: "Healed \(childID.rawValue) (\(childVal)g -> \(shifted)g) to satisfy parent ceiling (\(parentCeiling)g)."
                )
            )
            return true
        }

        // 1. Added Sugars <= Total Sugars (§ 101.9(g)(10)(v)(B), with 1.0g rounding slop for two independent ±0.5g roundings)
        if let totalSugarsRow = nutrients[.totalSugars],
           totalSugarsRow.amount != .omitted,
           let addedSugarsRow = nutrients[.addedSugars],
           addedSugarsRow.amount != .omitted {
            let totalSugarsVal = totalSugarsRow.amount.resolvedValue(for: .totalSugars)
            let addedSugarsVal = addedSugarsRow.amount.resolvedValue(for: .addedSugars)
            let slop = 1.0
            if addedSugarsVal > totalSugarsVal + slop {
                if !attemptChildCeilingHeal(childID: .addedSugars, parentCeiling: totalSugarsVal, tolerance: slop) {
                    diagnostics.append(
                        ValidationDiagnostic(
                            severity: .warning,
                            nutrient: .addedSugars,
                            code: "CEILING_ADDED_EXCEEDS_TOTAL_SUGARS",
                            message: "Added Sugars (\(addedSugarsVal)g) exceeds Total Sugars (\(totalSugarsVal)g) beyond legal rounding tolerance."
                        )
                    )
                }
            }
        }

        // 2. Carbohydrate Sub-Components <= Total Carbohydrate
        if let totalCarbRow = nutrients[.totalCarbohydrate], totalCarbRow.amount != .omitted {
            let totalCarbVal = totalCarbRow.amount.resolvedValue(for: .totalCarbohydrate)
            let carbHalfStep = FDARegulatoryConstants.roundingHalfStepTolerance(
                for: .totalCarbohydrate,
                declaredValue: totalCarbVal,
                isSupplement: isSupplement
            )

            // Check individual carbohydrate children first (in case one has a dropped decimal like Dietary Fiber 20g under Carb 22g -> 2.0g)
            for childID in [CanonicalNutrientID.dietaryFiber, .totalSugars, .addedSugars, .sugarAlcohol] {
                if let childRow = nutrients[childID], childRow.amount != .omitted {
                    let childVal = childRow.amount.resolvedValue(for: childID)
                    let childStep = FDARegulatoryConstants.roundingHalfStepTolerance(
                        for: childID,
                        declaredValue: childVal,
                        isSupplement: isSupplement
                    )
                    if childVal > totalCarbVal + carbHalfStep + childStep {
                        _ = attemptChildCeilingHeal(
                            childID: childID,
                            parentCeiling: totalCarbVal,
                            tolerance: carbHalfStep + childStep
                        )
                    }
                }
            }

            // Now check cumulative sum: Dietary Fiber + Total Sugars (or Added Sugars if Total Sugars omitted) + Sugar Alcohol <= Total Carbohydrate + Cumulative Rounding Slop
            let fiberVal = nutrients[.dietaryFiber]?.amount.resolvedValue(for: .dietaryFiber) ?? 0.0
            let sugarsVal = nutrients[.totalSugars]?.amount.resolvedValue(for: .totalSugars)
                ?? nutrients[.addedSugars]?.amount.resolvedValue(for: .addedSugars)
                ?? 0.0
            let polyolVal = resolvedTotalSugarAlcoholGrams(from: nutrients)

            var activeCarbChildren = 0
            if fiberVal > 0 { activeCarbChildren += 1 }
            if sugarsVal > 0 { activeCarbChildren += 1 }
            if polyolVal > 0 { activeCarbChildren += 1 }

            let cumulativeCarbSlop = carbHalfStep + (Double(max(1, activeCarbChildren)) * 0.5)
            let carbSubSum = fiberVal + sugarsVal + polyolVal
            if carbSubSum > totalCarbVal + cumulativeCarbSlop {
                diagnostics.append(
                    ValidationDiagnostic(
                        severity: .warning,
                        nutrient: .totalCarbohydrate,
                        code: "CEILING_CARB_SUBCOMPONENTS_EXCEED_TOTAL",
                        message: "Sum of Carbohydrate sub-nutrients (\(carbSubSum)g) exceeds Total Carbohydrate (\(totalCarbVal)g) + rounding tolerance (\(cumulativeCarbSlop)g)."
                    )
                )
            }
        }

        // 3. Soluble + Insoluble Fiber <= Dietary Fiber
        if let fiberRow = nutrients[.dietaryFiber], fiberRow.amount != .omitted {
            let fiberVal = fiberRow.amount.resolvedValue(for: .dietaryFiber)
            let solVal = nutrients[.solubleFiber]?.amount.resolvedValue(for: .solubleFiber) ?? 0.0
            let insolVal = nutrients[.insolubleFiber]?.amount.resolvedValue(for: .insolubleFiber) ?? 0.0
            let fiberSlop = 1.5 // Three independent ±0.5g roundings
            if (solVal + insolVal) > fiberVal + fiberSlop {
                diagnostics.append(
                    ValidationDiagnostic(
                        severity: .warning,
                        nutrient: .dietaryFiber,
                        code: "CEILING_FIBER_SUBCOMPONENTS_EXCEED_DIETARY_FIBER",
                        message: "Soluble (\(solVal)g) + Insoluble (\(insolVal)g) Fiber exceeds Dietary Fiber (\(fiberVal)g) + rounding tolerance."
                    )
                )
            }
        }

        // 4. Fat Sub-Components (Saturated + Trans + Polyunsaturated + Monounsaturated) <= Total Fat + SumOfConstituentRoundingTolerances
        if let totalFatRow = nutrients[.totalFat], totalFatRow.amount != .omitted {
            let totalFatVal = totalFatRow.amount.resolvedValue(for: .totalFat)
            let totalFatHalfStep = FDARegulatoryConstants.roundingHalfStepTolerance(
                for: .totalFat,
                declaredValue: totalFatVal,
                isSupplement: isSupplement
            )

            let fatChildren: [CanonicalNutrientID] = [.saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat]
            for childID in fatChildren {
                if let childRow = nutrients[childID], childRow.amount != .omitted {
                    let childVal = childRow.amount.resolvedValue(for: childID)
                    let childStep = FDARegulatoryConstants.roundingHalfStepTolerance(
                        for: childID,
                        declaredValue: childVal,
                        isSupplement: isSupplement
                    )
                    if childVal > totalFatVal + totalFatHalfStep + childStep {
                        _ = attemptChildCeilingHeal(
                            childID: childID,
                            parentCeiling: totalFatVal,
                            tolerance: totalFatHalfStep + childStep
                        )
                    }
                }
            }

            var fatSubSum = 0.0
            var constituentRoundingSlop = totalFatHalfStep
            for childID in fatChildren {
                if let childRow = nutrients[childID], childRow.amount != .omitted {
                    let v = childRow.amount.resolvedValue(for: childID)
                    fatSubSum += v
                    constituentRoundingSlop += FDARegulatoryConstants.roundingHalfStepTolerance(
                        for: childID,
                        declaredValue: v,
                        isSupplement: isSupplement
                    )
                }
            }

            if fatSubSum > totalFatVal + constituentRoundingSlop {
                diagnostics.append(
                    ValidationDiagnostic(
                        severity: .warning,
                        nutrient: .totalFat,
                        code: "CEILING_FAT_SUBCOMPONENTS_EXCEED_TOTAL",
                        message: "Sum of Fat sub-nutrients (\(fatSubSum)g) exceeds Total Fat (\(totalFatVal)g) + constituent rounding tolerance (\(constituentRoundingSlop)g)."
                    )
                )
            }
        }

        return (healedSet, diagnostics)
    }

    // MARK: - 5. Atwater 4-4-9 & Sugar Alcohol Calorie Cross-Check (Milestone 3.4.3 & Part 1.5.3)

    /// Cross-checks declared `Calories` against `4*Protein + 4*(Carbs - InsolubleFiber - SugarAlcoholAdjustment) + 9*Fat`, accounting for:
    /// - Unrounded intervals of `Total Fat`, `Total Carbohydrate`, `Dietary Fiber` (`Soluble` at `2 kcal/g`, `Insoluble` at `0 kcal/g`), `Sugar Alcohol` (`0.0...3.0 kcal/g` or specific polyol factor), and `Protein`
    /// - Legal `21 CFR § 101.9(c)(1)` calorie rounding steps (`±2.5 kcal` up to `50 kcal`, `±5.0 kcal` above `50 kcal`).
    /// Never overwrites the declared `Calories` value; returns `(passed, expectedCalorieRange, diagnostic)`.
    static func evaluateAtwaterCalorieInvariants(
        nutrients: [CanonicalNutrientID: ParsedNutrientRow],
        isSupplement: Bool
    ) -> (passed: Bool, expectedRange: ClosedRange<Int>, diagnostic: ValidationDiagnostic?) {
        let declaredCalories = nutrients[.calories]?.amount.resolvedCalories() ?? 0

        let fatAmount = nutrients[.totalFat]?.amount ?? .omitted
        let carbAmount = nutrients[.totalCarbohydrate]?.amount ?? .omitted
        let proteinAmount = nutrients[.protein]?.amount ?? .omitted

        // If all macros are omitted (e.g., micronutrient/botanical-only Supplement Facts panel), Atwater trivially passes if Calories == 0
        if fatAmount == .omitted && carbAmount == .omitted && proteinAmount == .omitted {
            let passed = declaredCalories == 0
            return (passed, 0...0, nil)
        }

        let fatInterval = FDARegulatoryConstants.legalActualInterval(
            for: .totalFat,
            declared: fatAmount,
            isSupplement: isSupplement
        ) ?? 0.0...0.0
        let carbInterval = FDARegulatoryConstants.legalActualInterval(
            for: .totalCarbohydrate,
            declared: carbAmount,
            isSupplement: isSupplement
        ) ?? 0.0...0.0
        let proteinInterval = FDARegulatoryConstants.legalActualInterval(
            for: .protein,
            declared: proteinAmount,
            isSupplement: isSupplement
        ) ?? 0.0...0.0

        let fiberInterval: ClosedRange<Double>
        if let fiberRow = nutrients[.dietaryFiber], fiberRow.amount != .omitted {
            fiberInterval = FDARegulatoryConstants.legalActualInterval(
                for: .dietaryFiber,
                declared: fiberRow.amount,
                isSupplement: isSupplement
            ) ?? 0.0...0.0
        } else {
            fiberInterval = 0.0...0.0
        }

        let insolubleFiberInterval: ClosedRange<Double>? = nutrients[.insolubleFiber].flatMap {
            FDARegulatoryConstants.legalActualInterval(for: .insolubleFiber, declared: $0.amount, isSupplement: isSupplement)
        }
        let solubleFiberInterval: ClosedRange<Double>? = nutrients[.solubleFiber].flatMap {
            FDARegulatoryConstants.legalActualInterval(for: .solubleFiber, declared: $0.amount, isSupplement: isSupplement)
        }

        // Compute minimum possible carbohydrate calories (deducting maximum non-digestible fiber and sugar alcohol adjustments)
        let (polyolGramsMin, polyolGramsMax, polyolMinKcalPerGram, polyolMaxKcalPerGram) = resolveSugarAlcoholCaloricBounds(
            from: nutrients,
            isSupplement: isSupplement
        )

        let minCarbKcal: Double
        let maxCarbKcal: Double

        if let insol = insolubleFiberInterval, let sol = solubleFiberInterval {
            let minNetDigestible = max(0.0, carbInterval.lowerBound - insol.upperBound - sol.upperBound - polyolGramsMax)
            let maxNetDigestible = max(0.0, carbInterval.upperBound - insol.lowerBound - sol.lowerBound - polyolGramsMin)
            minCarbKcal = (minNetDigestible * FDARegulatoryConstants.CaloricFactors.totalCarbohydrateKcalPerGram)
                + (sol.lowerBound * FDARegulatoryConstants.CaloricFactors.solubleNonDigestibleCarbohydrateKcalPerGram)
                + (polyolGramsMin * polyolMinKcalPerGram)
            maxCarbKcal = (maxNetDigestible * FDARegulatoryConstants.CaloricFactors.totalCarbohydrateKcalPerGram)
                + (sol.upperBound * FDARegulatoryConstants.CaloricFactors.solubleNonDigestibleCarbohydrateKcalPerGram)
                + (polyolGramsMax * polyolMaxKcalPerGram)
        } else {
            // When soluble vs. insoluble split is not declared, dietary fiber may contribute between 0 kcal/g (all insoluble) and 4 kcal/g (if not subtracted by manufacturer)
            let minDigestible = max(0.0, carbInterval.lowerBound - fiberInterval.upperBound - polyolGramsMax)
            let maxDigestible = max(0.0, carbInterval.upperBound - polyolGramsMin)
            minCarbKcal = (minDigestible * FDARegulatoryConstants.CaloricFactors.totalCarbohydrateKcalPerGram)
                + (polyolGramsMin * polyolMinKcalPerGram)
            maxCarbKcal = (maxDigestible * FDARegulatoryConstants.CaloricFactors.totalCarbohydrateKcalPerGram)
                + (polyolGramsMax * polyolMaxKcalPerGram)
        }

        let minUnroundedKcal = (fatInterval.lowerBound * FDARegulatoryConstants.CaloricFactors.totalFatKcalPerGram)
            + (proteinInterval.lowerBound * FDARegulatoryConstants.CaloricFactors.proteinKcalPerGram)
            + minCarbKcal
        let maxUnroundedKcal = (fatInterval.upperBound * FDARegulatoryConstants.CaloricFactors.totalFatKcalPerGram)
            + (proteinInterval.upperBound * FDARegulatoryConstants.CaloricFactors.proteinKcalPerGram)
            + maxCarbKcal

        // Expand by legal 21 CFR § 101.9(c)(1) calorie rounding tolerance (±5 kcal up to 50, ±10 kcal above 50)
        let calHalfStepLow = minUnroundedKcal <= 50.0 ? 5.0 : 10.0
        let calHalfStepHigh = maxUnroundedKcal <= 50.0 ? 5.0 : 10.0

        let minAllowedCal = max(0, Int((minUnroundedKcal - calHalfStepLow).rounded(.down)))
        let maxAllowedCal = max(minAllowedCal, Int((maxUnroundedKcal + calHalfStepHigh).rounded(.up)))
        let expectedRange = minAllowedCal...maxAllowedCal

        let passed = expectedRange.contains(declaredCalories)
        let diag: ValidationDiagnostic? = passed ? nil : ValidationDiagnostic(
            severity: .warning,
            nutrient: .calories,
            code: "ATWATER_CALORIE_DEVIATION",
            message: "Declared Calories (\(declaredCalories)) falls outside expected Atwater 4-4-9 range (\(minAllowedCal)...\(maxAllowedCal) kcal)."
        )
        return (passed, expectedRange, diag)
    }

    // MARK: - 6. ScannedNutritionPayload Builder (Milestone 3.4 Assembly)

    /// Validates a collection of `ParsedNutrientRow`s, applies conservative OCR self-healing, enforces sub-nutrient ceilings and Atwater calorie checks, selects the primary `"Per Serving"` column (`selectedColumnIndex = 0` by default for Dual-Column/Aggregate panels), and builds a `ScannedNutritionPayload` ready for `AddFoodView`.
    static func buildPayload(
        topology: FDALabelTopology,
        servingSize: ParsedServingSize?,
        rows: [ParsedNutrientRow],
        insignificantNutrients: Set<CanonicalNutrientID> = [],
        rawPanelTexts: [String] = [],
        selectedColumnIndex: Int = 0
    ) -> ScannedNutritionPayload {
        let isSupplement = topology.isSupplementFacts
        let demographic = inferDemographicGroup(fromRawTexts: rawPanelTexts, rows: rows)

        // Filter to the target column (primary "Per Serving" left column = 0 by default)
        let targetRows = rows.filter { $0.columnIndex == selectedColumnIndex }
        let activeRows = targetRows.isEmpty ? rows : targetRows

        var nutrientMap: [CanonicalNutrientID: ParsedNutrientRow] = [:]
        var healedSet: Set<CanonicalNutrientID> = []
        var derivedFromDVSet: Set<CanonicalNutrientID> = []
        var diagnostics: [ValidationDiagnostic] = []

        // 1. Seed footnote-insignificant nutrients ("Not a significant source of...")
        for omittedNutrient in insignificantNutrients {
            nutrientMap[omittedNutrient] = ParsedNutrientRow(
                nutrient: omittedNutrient,
                rawName: omittedNutrient.rawValue,
                amount: .insignificantFootnote(symbol: nil, reason: "Not a significant source footer"),
                percentDV: .omitted,
                indentationLevel: omittedNutrient.indentationLevel,
                sourceCompoundDescription: nil,
                columnIndex: selectedColumnIndex
            )
        }

        // 2. Run Unit/Glyph Disambiguation, % DV-only RDI Back-Calculation (Examples E, K, & M), & % DV Cross-Validation on each row
        for rawRow in activeRows {
            var candidateRow = rawRow

            // If an RDI micronutrient row declares only % DV with a blank weight cell (e.g. "Thiamin 70%", "Zinc 10%" in Examples E, K, & M),
            // automatically derive the mg/mcg weight from the FDA RDI behind the scenes.
            if candidateRow.amount == .omitted,
               candidateRow.nutrient.isMicronutrientRDI,
               let pct = candidateRow.percentDV.numericPercent,
               let (rdiVal, rdiUnit) = FDARegulatoryConstants.dailyReferenceValue(
                   for: candidateRow.nutrient,
                   demographic: demographic
               ),
               rdiVal > 0 {
                let derivedVal = ((pct / 100.0) * rdiVal * 1000.0).rounded() / 1000.0
                candidateRow.amount = (derivedVal == 0.0)
                    ? .explicitZero(unit: rdiUnit)
                    : .exact(value: derivedVal, unit: rdiUnit)
                derivedFromDVSet.insert(candidateRow.nutrient)
            }

            let (unitDisambiguatedRow, unitHealed, unitDiag) = enforceLegalUnitAndDisambiguateGlyphs(
                row: candidateRow,
                demographic: demographic,
                isSupplement: isSupplement
            )
            if unitHealed {
                healedSet.insert(rawRow.nutrient)
            }
            if let unitDiag {
                diagnostics.append(unitDiag)
            }

            let (dvValidatedRow, dvHealed, dvDiag) = validateAndHealAgainstPercentDV(
                row: unitDisambiguatedRow,
                demographic: demographic,
                isSupplement: isSupplement
            )
            if dvHealed {
                healedSet.insert(rawRow.nutrient)
            }
            if let dvDiag {
                diagnostics.append(dvDiag)
            }

            // Preserve first-seen primary nutrient row unless previously omitted
            if let existing = nutrientMap[dvValidatedRow.nutrient], existing.amount != .omitted {
                if case .insignificantFootnote = existing.amount {
                    nutrientMap[dvValidatedRow.nutrient] = dvValidatedRow
                }
            } else {
                nutrientMap[dvValidatedRow.nutrient] = dvValidatedRow
            }
        }

        // 3. Enforce Sub-Nutrient Ceiling Invariants (Added Sugars <= Total Sugars, Sub-Fats <= Total Fat, Sub-Carbs <= Total Carb)
        let (ceilingHealed, ceilingDiagnostics) = enforceSubNutrientCeilings(
            nutrients: &nutrientMap,
            demographic: demographic,
            isSupplement: isSupplement
        )
        healedSet.formUnion(ceilingHealed)
        diagnostics.append(contentsOf: ceilingDiagnostics)

        // 4. Evaluate Atwater 4-4-9 & Sugar Alcohol Calorie Invariant
        let (atwaterPassed, atwaterRange, atwaterDiag) = evaluateAtwaterCalorieInvariants(
            nutrients: nutrientMap,
            isSupplement: isSupplement
        )
        if let atwaterDiag {
            diagnostics.append(atwaterDiag)
        }

        // 5. Compute overall confidence score in 0.0...1.0
        let warningCount = diagnostics.filter { $0.severity == .warning || $0.severity == .error }.count
        var confidence = 1.0 - (Double(warningCount) * 0.12) - (Double(healedSet.count) * 0.03)
        if !atwaterPassed {
            confidence -= 0.10
        }
        if servingSize == nil {
            confidence -= 0.15
        }
        confidence = min(1.0, max(0.0, confidence))

        // 6. Resolve Target `AddFoodView` / `FoodItem` Properties (with all omission & threshold defaults)
        let resolvedServingSize = servingSize?.servingSize ?? 0.0
        let resolvedServingUnit = FDALexicalNormalizer.normalizeServingMetricUnit(servingSize?.servingUnit ?? "g") ?? "g"

        // Ensure household measurement pair satisfies `FoodItem.isValidHouseholdPair`
        let hhName: String?
        let hhAmount: Double?
        if let candName = servingSize?.commonHouseholdMeasurement,
           let candAmount = servingSize?.commonHouseholdMeasurementAmount,
           FoodItem.isValidHouseholdPair(name: candName, amount: candAmount) {
            hhName = candName
            hhAmount = candAmount
        } else {
            hhName = nil
            hhAmount = nil
        }

        let resolvedCalories = nutrientMap[.calories]?.amount.resolvedCalories() ?? 0
        let resolvedFat = nutrientMap[.totalFat]?.amount.resolvedValue(for: .totalFat) ?? 0.0
        let resolvedSaturatedFat = nutrientMap[.saturatedFat]?.amount.resolvedValue(for: .saturatedFat) ?? 0.0
        let resolvedTransFat = nutrientMap[.transFat]?.amount.resolvedValue(for: .transFat) ?? 0.0
        let resolvedCarb = nutrientMap[.totalCarbohydrate]?.amount.resolvedValue(for: .totalCarbohydrate) ?? 0.0
        let resolvedDietaryFiber = nutrientMap[.dietaryFiber]?.amount.resolvedValue(for: .dietaryFiber) ?? 0.0
        let resolvedAddedSugar = nutrientMap[.addedSugars]?.amount.resolvedValue(for: .addedSugars) ?? 0.0
        let resolvedProtein = nutrientMap[.protein]?.amount.resolvedValue(for: .protein) ?? 0.0

        var allAmounts: [CanonicalNutrientID: DeclaredNutrientAmount] = [:]
        var allPercentDVs: [CanonicalNutrientID: DeclaredPercentDV] = [:]
        var allSources: [CanonicalNutrientID: String] = [:]
        for (id, row) in nutrientMap {
            allAmounts[id] = row.amount
            if row.percentDV != .omitted {
                allPercentDVs[id] = row.percentDV
            }
            if let src = row.sourceCompoundDescription, !src.isEmpty {
                allSources[id] = src
            }
        }

        return ScannedNutritionPayload(
            isSupplement: isSupplement,
            servingSize: resolvedServingSize,
            servingUnit: resolvedServingUnit,
            commonHouseholdMeasurement: hhName,
            commonHouseholdMeasurementAmount: hhAmount,
            servingsPerContainer: servingSize?.servingsPerContainer,
            servingsPerContainerModifier: servingSize?.servingsPerContainerModifier,
            perDayMultiplier: servingSize?.perDayMultiplier,
            calories: resolvedCalories,
            fat: resolvedFat,
            saturatedFat: resolvedSaturatedFat,
            transFat: resolvedTransFat,
            carb: resolvedCarb,
            dietaryFiber: resolvedDietaryFiber,
            addedSugar: resolvedAddedSugar,
            protein: resolvedProtein,
            topology: topology,
            demographicGroup: demographic,
            confidenceScore: confidence,
            atwaterCalorieCheckPassed: atwaterPassed,
            expectedAtwaterCalorieRange: atwaterRange,
            healedNutrients: healedSet,
            diagnostics: diagnostics,
            allParsedNutrients: allAmounts,
            allParsedPercentDVs: allPercentDVs,
            derivedFromPercentDVNutrients: derivedFromDVSet,
            sourceCompounds: allSources
        )
    }

    // MARK: - Private Validation Helpers

    private static func countDemographicPercentDVMatches(
        in rows: [ParsedNutrientRow],
        demographic: FDADemographicGroup
    ) -> Int {
        var matches = 0
        for row in rows {
            guard let pct = row.percentDV.numericPercent,
                  let interval = FDARegulatoryConstants.legalPercentDVInterval(
                      for: row.nutrient,
                      declaredAmount: row.amount,
                      demographic: demographic,
                      isSupplement: false
                  ) else {
                continue
            }
            if interval.contains(pct) {
                matches += 1
            }
        }
        return matches
    }

    private static func isCandidateConfirmedByPercentDV(
        candidateValue: Double,
        originalValue: Double,
        unit: NutrientUnit,
        nutrient: CanonicalNutrientID,
        percentDV: DeclaredPercentDV,
        demographic: FDADemographicGroup,
        isSupplement: Bool
    ) -> Bool {
        guard let scannedPct = percentDV.numericPercent else { return false }
        let originalDeclared: DeclaredNutrientAmount = .exact(value: originalValue, unit: unit)
        let candidateDeclared: DeclaredNutrientAmount = .exact(value: candidateValue, unit: unit)

        let origInterval = FDARegulatoryConstants.legalPercentDVInterval(
            for: nutrient,
            declaredAmount: originalDeclared,
            demographic: demographic,
            isSupplement: isSupplement
        )
        let candInterval = FDARegulatoryConstants.legalPercentDVInterval(
            for: nutrient,
            declaredAmount: candidateDeclared,
            demographic: demographic,
            isSupplement: isSupplement
        )
        let origMatches = origInterval?.contains(scannedPct) ?? false
        let candMatches = candInterval?.contains(scannedPct) ?? false
        return !origMatches && candMatches
    }

    private static func isFDALegalStepValue(
        _ value: Double,
        for nutrient: CanonicalNutrientID,
        isSupplement: Bool
    ) -> Bool {
        guard value >= 0 else { return false }
        if isSupplement && nutrient.isMicronutrientRDI {
            return true
        }
        switch nutrient {
        case .totalFat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat:
            if value < 5.0 {
                let twice = value * 2.0
                return abs(twice - twice.rounded()) < 0.001
            } else {
                return abs(value - value.rounded()) < 0.001
            }
        case .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
             .totalSugars, .addedSugars, .sugarAlcohol, .protein:
            return value >= 1.0 && abs(value - value.rounded()) < 0.001
        case .cholesterol:
            return value >= 5.0 && abs((value / 5.0) - (value / 5.0).rounded()) < 0.001
        case .sodium:
            if value <= 140.0 {
                return abs((value / 5.0) - (value / 5.0).rounded()) < 0.001
            } else {
                return abs((value / 10.0) - (value / 10.0).rounded()) < 0.001
            }
        default:
            return true
        }
    }

    private static func singleDigitGlyphSwapCandidates(
        for rawValue: Double
    ) -> [(value: Double, reasonCode: String, description: String)] {
        // Common single-digit OCR confusions: 8 <-> 3, 8 <-> 0, 6 <-> 0, 5 <-> 6, 1 <-> 7
        let swapTable: [Character: [Character]] = [
            "8": ["3", "0", "6"],
            "6": ["5", "0", "8"],
            "5": ["6", "3"],
            "3": ["8", "5"],
            "7": ["1"],
            "1": ["7"]
        ]
        let formatted = String(format: "%g", rawValue)
        guard !formatted.contains("."), formatted.count <= 3 else { return [] }

        var results: [(value: Double, reasonCode: String, description: String)] = []
        let chars = Array(formatted)
        for (idx, ch) in chars.enumerated() {
            guard let replacements = swapTable[ch] else { continue }
            for rep in replacements {
                var mutated = chars
                mutated[idx] = rep
                let candidateStr = String(mutated)
                if let val = Double(candidateStr), val != rawValue {
                    results.append((
                        val,
                        "GLYPH_DIGIT_SWAP",
                        "single-glyph digit swap (\(formatted) -> \(candidateStr))"
                    ))
                }
            }
        }
        return results
    }

    private static func resolvedTotalSugarAlcoholGrams(
        from nutrients: [CanonicalNutrientID: ParsedNutrientRow]
    ) -> Double {
        if let generic = nutrients[.sugarAlcohol], generic.amount != .omitted {
            return generic.amount.resolvedValue(for: .sugarAlcohol)
        }
        var sum = 0.0
        for (id, _) in FDARegulatoryConstants.CaloricFactors.sugarAlcoholKcalPerGram {
            if let row = nutrients[id], row.amount != .omitted {
                sum += row.amount.resolvedValue(for: id)
            }
        }
        return sum
    }

    private static func resolveSugarAlcoholCaloricBounds(
        from nutrients: [CanonicalNutrientID: ParsedNutrientRow],
        isSupplement: Bool
    ) -> (minGrams: Double, maxGrams: Double, minKcalPerGram: Double, maxKcalPerGram: Double) {
        // Check specific named sugar alcohols first
        var specificMinGrams = 0.0
        var specificMaxGrams = 0.0
        var weightedFactorSum = 0.0
        var foundSpecific = false

        for (polyolID, factor) in FDARegulatoryConstants.CaloricFactors.sugarAlcoholKcalPerGram {
            if let row = nutrients[polyolID], row.amount != .omitted,
               let interval = FDARegulatoryConstants.legalActualInterval(
                   for: polyolID,
                   declared: row.amount,
                   isSupplement: isSupplement
               ) {
                foundSpecific = true
                specificMinGrams += interval.lowerBound
                specificMaxGrams += interval.upperBound
                weightedFactorSum += factor
            }
        }

        if foundSpecific {
            let avgFactor = weightedFactorSum
            return (specificMinGrams, specificMaxGrams, avgFactor, avgFactor)
        }

        if let genericRow = nutrients[.sugarAlcohol], genericRow.amount != .omitted,
           let interval = FDARegulatoryConstants.legalActualInterval(
               for: .sugarAlcohol,
               declared: genericRow.amount,
               isSupplement: isSupplement
           ) {
            let range = FDARegulatoryConstants.CaloricFactors.genericSugarAlcoholKcalPerGramRange
            return (interval.lowerBound, interval.upperBound, range.lowerBound, range.upperBound)
        }

        return (0.0, 0.0, 0.0, 0.0)
    }
}
