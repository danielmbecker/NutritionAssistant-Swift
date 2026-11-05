//
//  VisionTableRowExtractor.swift
//  NutritionAssistant
//
//  Milestone 4.3: 2D Grid Unpacker for Topologies A–K & Supplement Facts
//  Unpacks ScannedTableGrid into an ordered [RawExtractedRow] sequence, solving the
//  Tabular Horizontal Row Trap (Topologies A, I, K), isolating the primary "Per Serving" /
//  "As Packaged" column pair in Dual-Column & Aggregate tables (Topologies E, F, G, H, I),
//  and unpacking bullet-delimited (•) and side-by-side (Topology D) micronutrient rows.
//

import CoreGraphics
import Foundation

/// Metadata describing a single non-milk nutrition column extracted from a scanned table.
struct ExtractedTableColumnMetadata: Codable, Sendable, Equatable, Hashable {
    /// Zero-based index among kept (non-milk) columns (`0, 1, 2, ...`).
    let columnIndex: Int
    /// Zero-based index of this column pair in the raw table before milk-column filtering (`0, 1, 2, ...`).
    let rawPairIndex: Int
    /// Display header title for this column (e.g., `"Wheat Squares Sweetened"`, `"Per 1/4 cup dry mix"`, `"Per Serving"`).
    let headerTitle: String
    /// Optional per-column serving size transcript override (e.g., `"Serving size 1 box (35g)"` in Aggregate Variety Pack `Example E`).
    let servingSizeTranscript: String?
    /// Per-column calories value when present in the header/calories row (e.g., `130`, `70`, `100` in `Example E`).
    let caloriesValue: Int?
}

enum VisionTableRowExtractor {

    // MARK: - Public API

    /// Unpacks a classified `ScannedTableGrid` and `FDAClassifiedLabel` into an ordered array of `[RawExtractedRow]`
    /// for Phase 1 normalization and validation.
    static func extractRows(
        from table: ScannedTableGrid,
        classifiedLabel: FDAClassifiedLabel
    ) -> [RawExtractedRow] {
        extractRows(
            from: table,
            topology: classifiedLabel.topology,
            isSupplement: classifiedLabel.isSupplement,
            supplementaryTables: classifiedLabel.supplementaryTables,
            inferredCaloriesValue: classifiedLabel.inferredCaloriesValue,
            preserveAllColumnCells: false
        )
    }

    /// Unpacks a `ScannedTableGrid` and `FDAClassifiedLabel` into:
    /// - `columns`: Ordered `[ExtractedTableColumnMetadata]` for all kept columns (automatically discarding `Example M` combined-with-milk columns).
    /// - `allColumnRows`: `[RawExtractedRow]` preserving all column cells in `rawCells` so `FDALexicalNormalizer.parseNutrientRow` emits `ParsedNutrientRow`s for every `rawPairIndex`.
    /// - `hadDiscardedMilkColumn`: `true` when one or more `"combined with milk"` columns (`Example M`) were filtered out.
    static func extractMultiColumnData(
        from table: ScannedTableGrid,
        classifiedLabel: FDAClassifiedLabel
    ) -> (
        columns: [ExtractedTableColumnMetadata],
        allColumnRows: [RawExtractedRow],
        hadDiscardedMilkColumn: Bool
    ) {
        let allColumnRows = extractRows(
            from: table,
            topology: classifiedLabel.topology,
            isSupplement: classifiedLabel.isSupplement,
            supplementaryTables: classifiedLabel.supplementaryTables,
            inferredCaloriesValue: classifiedLabel.inferredCaloriesValue,
            preserveAllColumnCells: true
        )
        let (columns, hadDiscardedMilkColumn) = extractColumnMetadata(
            from: table,
            classifiedLabel: classifiedLabel
        )
        return (columns, allColumnRows, hadDiscardedMilkColumn)
    }

    /// Unpacks a `ScannedTableGrid` given an explicit `FDALabelTopology` and optional supplementary continuation tables.
    static func extractRows(
        from table: ScannedTableGrid,
        topology: FDALabelTopology,
        isSupplement: Bool = false,
        supplementaryTables: [ScannedTableGrid] = [],
        inferredCaloriesValue: Int? = nil,
        preserveAllColumnCells: Bool = false
    ) -> [RawExtractedRow] {
        let rawRows: [RawExtractedRow]

        if topology.isTabularLayout || shouldUseTabularUnpacker(for: table) {
            rawRows = extractTabularHorizontalRows(
                from: table,
                topology: topology,
                isSupplement: isSupplement,
                supplementaryTables: supplementaryTables,
                preserveAllColumnCells: preserveAllColumnCells
            )
        } else if topology.isMultiColumn || table.columnCount >= 4 {
            rawRows = extractMultiColumnVerticalRows(
                from: table,
                topology: topology,
                isSupplement: isSupplement,
                supplementaryTables: supplementaryTables,
                preserveAllColumnCells: preserveAllColumnCells
            )
        } else {
            rawRows = extractStandardOrSideBySideVerticalRows(
                from: table,
                topology: topology,
                isSupplement: isSupplement,
                supplementaryTables: supplementaryTables,
                preserveAllColumnCells: preserveAllColumnCells
            )
        }

        return ensureCaloriesRowIfNeeded(
            in: rawRows,
            table: table,
            inferredCaloriesValue: inferredCaloriesValue
        )
    }

    // MARK: - 1. Tabular Horizontal Unpacker (Topologies A, I, K & Split-Continuation Supplements)

    /// Solves the Tabular Horizontal Row Trap (`Topologies A, I, K`):
    /// `RecognizeDocumentsRequest` groups cells by horizontal Y-slice, placing Left Stack and Right Stack nutrients
    /// in the same `Table.rows[i]`. This method splits each horizontal row into Left Stack and Right Stack records,
    /// isolates the primary `"Per Serving"` column pair on `Topology I`, and serializes Left Stack top-to-bottom
    /// followed by Right Stack top-to-bottom and bullet-delimited (`•`) micronutrient footers.
    private static func extractTabularHorizontalRows(
        from table: ScannedTableGrid,
        topology: FDALabelTopology,
        isSupplement: Bool,
        supplementaryTables: [ScannedTableGrid],
        preserveAllColumnCells: Bool = false
    ) -> [RawExtractedRow] {
        var leftStackRows: [RawExtractedRow] = []
        var rightStackRows: [RawExtractedRow] = []
        var footerMicroRows: [RawExtractedRow] = []
        var extractedCaloriesRow: RawExtractedRow?

        let columnLayout = analyzeTabularColumnLayout(in: table)
        let leftBaseMinX = computeStackBaselineMinX(in: table, stackSide: .left, layout: columnLayout)
        let rightBaseMinX = computeStackBaselineMinX(in: table, stackSide: .right, layout: columnLayout)

        var processedBulletCellSpans = Set<String>()

        for row in table.rows {
            // 1. Check for calorie declaration in the sidebar or row before filtering sidebar cells.
            if extractedCaloriesRow == nil,
               let calRow = tryExtractCalorieRow(
                   from: row,
                   in: table,
                   preserveAllColumnCells: preserveAllColumnCells
               ) {
                extractedCaloriesRow = calRow
            }

            // 2. Extract any bullet-delimited (`•`) micronutrient footer cells (Topologies A & K).
            for cell in row where containsBulletDelimitedMicronutrients(cell.transcript) {
                let spanKey = "\(cell.rowRange.lowerBound)-\(cell.rowRange.upperBound):\(cell.columnRange.lowerBound)-\(cell.columnRange.upperBound)"
                if processedBulletCellSpans.insert(spanKey).inserted {
                    let unpackedBullets = unpackBulletDelimitedCell(cell, isSupplement: isSupplement)
                    footerMicroRows.append(contentsOf: unpackedBullets)
                }
            }

            // 3. Filter out sidebar metadata cells (Nutrition Facts title, servings/container, serving size, calories, footnote)
            //    and column header cells ("Amount/serving", "% Daily Value*", "Per Serving").
            let candidateCells = row.filter { cell in
                let text = cell.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return false }
                if containsBulletDelimitedMicronutrients(text) { return false }
                if isFootnoteCell(text) { return false }
                if isTabularSidebarMetadataCell(cell, in: table, layout: columnLayout) { return false }
                if isPureColumnHeaderCell(text) { return false }
                return true
            }

            guard !candidateCells.isEmpty else { continue }

            // 4. Partition `candidateCells` into Left Nutrient Stack and Right Nutrient Stack.
            let (leftCells, rightCells) = partitionTabularRowCells(
                candidateCells,
                layout: columnLayout,
                isSupplement: isSupplement
            )

            if let leftRow = buildExtractedRowFromStackCells(
                leftCells,
                baselineMinX: leftBaseMinX,
                isSupplement: isSupplement,
                preserveAllColumnCells: preserveAllColumnCells
            ) {
                leftStackRows.append(leftRow)
            }

            if let rightRow = buildExtractedRowFromStackCells(
                rightCells,
                baselineMinX: rightBaseMinX,
                isSupplement: isSupplement,
                preserveAllColumnCells: preserveAllColumnCells
            ) {
                rightStackRows.append(rightRow)
            }
        }

        // 5. If supplementary tables exist (e.g., right-hand continuation split emitted as a separate table), unpack them.
        for suppTable in supplementaryTables {
            let suppExtracted = extractStandardOrSideBySideVerticalRows(
                from: suppTable,
                topology: .standardVertical,
                isSupplement: isSupplement,
                supplementaryTables: [],
                preserveAllColumnCells: preserveAllColumnCells
            )
            rightStackRows.append(contentsOf: suppExtracted)
        }

        var combined: [RawExtractedRow] = []
        if let calRow = extractedCaloriesRow {
            combined.append(calRow)
        }
        combined.append(contentsOf: deduplicateExtractedRows(leftStackRows))
        combined.append(contentsOf: deduplicateExtractedRows(rightStackRows))
        combined.append(contentsOf: deduplicateExtractedRows(footerMicroRows))
        return combined
    }

    private enum TabularStackSide {
        case left
        case right
    }

    private struct TabularColumnLayout {
        var sidebarMaxColumn: Int?
        var rightStackStartColumn: Int?
        var footnoteMinColumn: Int?
    }

    private static func analyzeTabularColumnLayout(in table: ScannedTableGrid) -> TabularColumnLayout {
        var layout = TabularColumnLayout()

        // Inspect cells to find left sidebar columns, repeated "Amount/serving" or "Total Carb" start columns, and right footnote columns.
        var amountHeaderColumns: [Int] = []
        var rightMacroStartColumns: [Int] = []
        let rightStackKeywords: Set<CanonicalNutrientID> = [
            .totalCarbohydrate, .dietaryFiber, .totalSugars, .addedSugars, .protein
        ]

        for cell in table.allUniqueCells {
            let lower = cell.transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            if lower.contains("nutrition facts")
                || lower.contains("supplement facts")
                || lower.contains("serving size")
                || lower.contains("serv. size")
                || lower.contains("servings per container") {
                if cell.columnRange.lowerBound == 0 && cell.columnRange.upperBound < max(2, table.columnCount - 2) {
                    layout.sidebarMaxColumn = max(layout.sidebarMaxColumn ?? 0, cell.columnRange.upperBound)
                }
            }

            if isFootnoteCell(cell.transcript) && cell.columnRange.lowerBound >= 3 && cell.rowSpan >= 3 {
                layout.footnoteMinColumn = min(layout.footnoteMinColumn ?? Int.max, cell.columnRange.lowerBound)
            }

            if lower.contains("amount/serving") || lower.contains("amount per serving") {
                amountHeaderColumns.append(cell.columnRange.lowerBound)
            }

            let firstLine = cell.transcript.components(separatedBy: .newlines).first ?? cell.transcript
            if let nutrient = FDALexicalNormalizer.resolveNutrientID(from: firstLine),
               rightStackKeywords.contains(nutrient),
               cell.columnRange.lowerBound >= 2 {
                rightMacroStartColumns.append(cell.columnRange.lowerBound)
            }
        }

        let sortedAmountCols = Array(Set(amountHeaderColumns)).sorted()
        if sortedAmountCols.count >= 2 {
            layout.rightStackStartColumn = sortedAmountCols[1]
        } else if let minRightMacroCol = rightMacroStartColumns.min() {
            layout.rightStackStartColumn = minRightMacroCol
        }

        return layout
    }

    private static func partitionTabularRowCells(
        _ cells: [ScannedTableCell],
        layout: TabularColumnLayout,
        isSupplement: Bool
    ) -> (left: [ScannedTableCell], right: [ScannedTableCell]) {
        guard !cells.isEmpty else { return ([], []) }

        let rightStackMacros: Set<CanonicalNutrientID> = [
            .totalCarbohydrate, .dietaryFiber, .solubleFiber, .insolubleFiber,
            .totalSugars, .addedSugars, .sugarAlcohol, .protein
        ]

        // 1. Look for an explicit second nutrient anchor cell after the first cell in the row.
        if cells.count >= 2 {
            for idx in 1..<cells.count {
                let candidateText = cells[idx].transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let nutrient = FDALexicalNormalizer.resolveNutrientID(from: candidateText) else {
                    continue
                }
                // Make sure this cell isn't just a standalone unit or number; it must contain alphabetic letters matching a nutrient name.
                let hasNutrientLetters = candidateText.unicodeScalars.contains { CharacterSet.letters.contains($0) }
                    && !isPureUnitOrPercentToken(candidateText)
                guard hasNutrientLetters else { continue }

                if rightStackMacros.contains(nutrient) || idx >= 2 || isSupplement {
                    let leftSlice = Array(cells[0..<idx])
                    let rightSlice = Array(cells[idx..<cells.count])
                    return (leftSlice, rightSlice)
                }
            }
        }

        // 2. Fallback to column-index split if `rightStackStartColumn` is known and cells didn't shift horizontally.
        if let splitCol = layout.rightStackStartColumn {
            let leftByCol = cells.filter { $0.columnRange.lowerBound < splitCol }
            let rightByCol = cells.filter { $0.columnRange.lowerBound >= splitCol }
            if !leftByCol.isEmpty || !rightByCol.isEmpty {
                return (leftByCol, rightByCol)
            }
        }

        // 3. If only one stack is populated on this row, check whether its nutrient belongs to the right macro stack.
        if let firstCell = cells.first,
           let nutrient = FDALexicalNormalizer.resolveNutrientID(from: firstCell.transcript),
           rightStackMacros.contains(nutrient) {
            return ([], cells)
        }

        return (cells, [])
    }

    /// Converts the cells of a single stack (either Left Stack or Right Stack) on a single row into a `RawExtractedRow`,
    /// isolating the primary `"Per Serving"` column pair when the stack is dual-column (`Topology I`) unless `preserveAllColumnCells` is `true`.
    private static func buildExtractedRowFromStackCells(
        _ stackCells: [ScannedTableCell],
        baselineMinX: CGFloat,
        isSupplement: Bool,
        preserveAllColumnCells: Bool = false
    ) -> RawExtractedRow? {
        guard !stackCells.isEmpty else { return nil }

        // Select the primary ("Per Serving" / "As Packaged") cells from the stack.
        let primaryCells = selectPrimaryColumnCells(from: stackCells)
        let primaryCellStrings = primaryCells
            .map { $0.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let allCellStrings = stackCells
            .map { $0.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !primaryCellStrings.isEmpty else { return nil }
        let combined = primaryCellStrings.joined(separator: " ")

        // Must resolve to a canonical nutrient or inline Added Sugars declaration.
        // Prefer resolving from the primary nutrient label cell first so trailing `% DV` cells never interfere with single-token nutrient names.
        guard let nutrient = FDALexicalNormalizer.resolveNutrientID(from: primaryCellStrings[0])
            ?? FDALexicalNormalizer.resolveNutrientID(from: combined) else {
            return nil
        }

        let leadCell = primaryCells[0]
        let indentation = resolveIndentationLevel(
            for: leadCell,
            resolvedNutrient: nutrient,
            baselineMinX: baselineMinX
        )

        let (labelPart, weightPart, dvPart) = decomposePrimaryCellParts(primaryCellStrings)
        let targetCells = preserveAllColumnCells ? stackCells : primaryCells
        let unionBox = targetCells.dropFirst().reduce(leadCell.boundingBox) { $0.union($1.boundingBox) }

        return RawExtractedRow(
            nutrientLabelTranscript: labelPart,
            weightTranscript: weightPart,
            percentDVTranscript: dvPart,
            rawCells: preserveAllColumnCells ? allCellStrings : primaryCellStrings,
            minX: leadCell.lines.first?.minX ?? leadCell.minX,
            midY: unionBox.midY,
            boundingBox: unionBox,
            indentationLevel: indentation,
            columnIndex: 0,
            isHeaderOrFooter: false
        )
    }

    // MARK: - 2. Multi-Column Vertical Unpacker (Topologies E, F, G, H & Multi-Column Supplements)

    /// Unpacks vertical Dual-Column (`F, G, H`) and Aggregate Variety Pack (`E`) tables,
    /// isolating the primary `"Per Serving"` / `"As Packaged"` column pair (`columnIndex = 0`)
    /// so `FoodItem` never accidentally ingests whole-container or prepared values, unless `preserveAllColumnCells` is `true`.
    private static func extractMultiColumnVerticalRows(
        from table: ScannedTableGrid,
        topology: FDALabelTopology,
        isSupplement: Bool,
        supplementaryTables: [ScannedTableGrid],
        preserveAllColumnCells: Bool = false
    ) -> [RawExtractedRow] {
        var extracted: [RawExtractedRow] = []
        let baselineMinX = computeVerticalBaselineMinX(in: table)
        var processedBulletCellSpans = Set<String>()

        for row in table.rows {
            // 1. Check for bullet-delimited micronutrient footer cells.
            for cell in row where containsBulletDelimitedMicronutrients(cell.transcript) {
                let spanKey = "\(cell.rowRange.lowerBound)-\(cell.rowRange.upperBound):\(cell.columnRange.lowerBound)-\(cell.columnRange.upperBound)"
                if processedBulletCellSpans.insert(spanKey).inserted {
                    extracted.append(contentsOf: unpackBulletDelimitedCell(cell, isSupplement: isSupplement))
                }
            }

            // 2. Check if this row is the Calories header row (e.g., ["Calories", "170", "300"] in Topology F, or ["Amount per serving", "", "130", "70", "100"] + ["Calories"] in Topology E).
            if !extracted.contains(where: { FDALexicalNormalizer.resolveNutrientID(from: $0.combinedTranscript) == .calories }),
               let calRow = tryExtractCalorieRow(
                   from: row,
                   in: table,
                   preserveAllColumnCells: preserveAllColumnCells
               ) {
                extracted.append(calRow)
                continue
            }

            // 3. Filter out non-nutrient header/footer cells.
            let nonEmptyCells = row.filter { cell in
                let text = cell.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return false }
                if containsBulletDelimitedMicronutrients(text) { return false }
                if isFootnoteCell(text) || isPureColumnHeaderCell(text) || isHeaderMetadataLine(text) {
                    return false
                }
                return true
            }

            guard !nonEmptyCells.isEmpty else { continue }

            // 4. Handle multi-line cells if Vision merged consecutive nutrient rows into a single table row across 1 or more columns.
            let unpackedMultiLineRows = tryUnpackMultiLineMergedRow(nonEmptyCells)
            if unpackedMultiLineRows.count >= 2 {
                extracted.append(contentsOf: unpackedMultiLineRows)
                continue
            }

            // 5. Select only the nutrient label cell + primary column pair (first weight + first %DV), or all cells when `preserveAllColumnCells` is `true`.
            if let rowRecord = buildExtractedRowFromStackCells(
                nonEmptyCells,
                baselineMinX: baselineMinX,
                isSupplement: isSupplement,
                preserveAllColumnCells: preserveAllColumnCells
            ) {
                extracted.append(rowRecord)
            }
        }

        for suppTable in supplementaryTables {
            let suppRows = extractStandardOrSideBySideVerticalRows(
                from: suppTable,
                topology: .standardVertical,
                isSupplement: isSupplement,
                supplementaryTables: [],
                preserveAllColumnCells: preserveAllColumnCells
            )
            extracted.append(contentsOf: suppRows)
        }

        return deduplicateExtractedRows(extracted)
    }

    // MARK: - 3. Standard Vertical, Simplified (J), Side-by-Side Micronutrient (D) & Supplement Unpacker

    private static func extractStandardOrSideBySideVerticalRows(
        from table: ScannedTableGrid,
        topology: FDALabelTopology,
        isSupplement: Bool,
        supplementaryTables: [ScannedTableGrid],
        preserveAllColumnCells: Bool = false
    ) -> [RawExtractedRow] {
        var extracted: [RawExtractedRow] = []
        let baselineMinX = computeVerticalBaselineMinX(in: table)
        var processedBulletCellSpans = Set<String>()

        for row in table.rows {
            // 1. Check for bullet-delimited micronutrient footer cells.
            for cell in row where containsBulletDelimitedMicronutrients(cell.transcript) {
                let spanKey = "\(cell.rowRange.lowerBound)-\(cell.rowRange.upperBound):\(cell.columnRange.lowerBound)-\(cell.columnRange.upperBound)"
                if processedBulletCellSpans.insert(spanKey).inserted {
                    extracted.append(contentsOf: unpackBulletDelimitedCell(cell, isSupplement: isSupplement))
                }
            }

            // 2. Check for Calories row (handling rowspan="2" calorie value beside "Amount per serving" and "Calories").
            if !extracted.contains(where: { FDALexicalNormalizer.resolveNutrientID(from: $0.combinedTranscript) == .calories }),
               let calRow = tryExtractCalorieRow(
                   from: row,
                   in: table,
                   preserveAllColumnCells: preserveAllColumnCells
               ) {
                extracted.append(calRow)
                continue
            }

            // 3. Check for Topology D Side-by-Side Micronutrients (e.g., `["Vit. D 2mcg 10%", "Calcium 260mg 20%"]`).
            let sideBySideRows = tryExtractSideBySideMicronutrientRow(row, isSupplement: isSupplement)
            if sideBySideRows.count >= 2 {
                extracted.append(contentsOf: sideBySideRows)
                continue
            }

            // 4. Filter out non-nutrient header/footer cells.
            let cleanCells = row.filter { cell in
                let text = cell.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return false }
                if containsBulletDelimitedMicronutrients(text) { return false }
                if isFootnoteCell(text) || isPureColumnHeaderCell(text) || isHeaderMetadataLine(text) {
                    return false
                }
                return true
            }

            guard !cleanCells.isEmpty else { continue }

            // 5. Handle multi-line cells if Vision merged consecutive nutrient rows into a single table row across 1 or more columns.
            let unpackedMultiLineRows = tryUnpackMultiLineMergedRow(cleanCells)
            if unpackedMultiLineRows.count >= 2 {
                extracted.append(contentsOf: unpackedMultiLineRows)
                continue
            }

            if let rowRecord = buildExtractedRowFromStackCells(
                cleanCells,
                baselineMinX: baselineMinX,
                isSupplement: isSupplement,
                preserveAllColumnCells: preserveAllColumnCells
            ) {
                extracted.append(rowRecord)
            }
        }

        for suppTable in supplementaryTables {
            let suppRows = extractStandardOrSideBySideVerticalRows(
                from: suppTable,
                topology: .standardVertical,
                isSupplement: isSupplement,
                supplementaryTables: [],
                preserveAllColumnCells: preserveAllColumnCells
            )
            extracted.append(contentsOf: suppRows)
        }

        return deduplicateExtractedRows(extracted)
    }

    // MARK: - Primary Column Selection (Dual-Column & Aggregate Isolation)

    /// Given the cells belonging to a single nutrient row (or a single stack of a Tabular Dual-Column row),
    /// isolates the nutrient name cell and the **first** `(quantitativeWeight, % DV)` column pair (`columnIndex = 0`).
    private static func selectPrimaryColumnCells(from cells: [ScannedTableCell]) -> [ScannedTableCell] {
        guard cells.count > 2 else {
            return cells
        }

        let firstCellText = cells[0].transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let firstCellHasWeight = containsQuantitativeWeightToken(firstCellText)

        // Case A: First cell already contains the nutrient name AND weight (e.g. "Total Fat 1.5g"),
        // so `cells[1]` is the primary `% DV` cell.
        if firstCellHasWeight {
            if isPercentOrFootnoteSymbolToken(cells[1].transcript) {
                return [cells[0], cells[1]]
            }
            return [cells[0]]
        }

        // Case B: Separate columns `[NutrientName, PrimaryWeight, Primary%DV, SecondaryWeight, Secondary%DV, ...]`.
        var selected: [ScannedTableCell] = [cells[0]]
        if cells.count >= 2 {
            selected.append(cells[1])
        }
        if cells.count >= 3 {
            let secondText = cells[1].transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            let thirdText = cells[2].transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            // Include the third cell ONLY if `cells[1]` was NOT already a `% DV` token (e.g. `% DV`-only rows like `["Thiamin", "70%", "75%"]`),
            // and `cells[2]` IS a `% DV` token and NOT the start of the second weight column.
            if !isPercentOrFootnoteSymbolToken(secondText)
                && isPercentOrFootnoteSymbolToken(thirdText)
                && !containsQuantitativeWeightToken(thirdText) {
                selected.append(cells[2])
            }
        }
        return selected
    }

    // MARK: - Bullet-Delimited (•) & Side-by-Side (Topology D) Micronutrient Unpacking

    private static func containsBulletDelimitedMicronutrients(_ text: String) -> Bool {
        guard text.contains("•") || text.contains("\u{2022}") || text.contains("\u{00B7}") else {
            return false
        }
        return FDALexicalNormalizer.resolveNutrientID(from: text) != nil
    }

    private static func unpackBulletDelimitedCell(
        _ cell: ScannedTableCell,
        isSupplement: Bool
    ) -> [RawExtractedRow] {
        let bulletSeparators = CharacterSet(charactersIn: "•\u{2022}\u{00B7}\n\r")
        let segments = cell.transcript
            .components(separatedBy: bulletSeparators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var rows: [RawExtractedRow] = []
        for segment in segments {
            guard let nutrient = FDALexicalNormalizer.resolveNutrientID(from: segment) else {
                continue
            }
            let (labelPart, weightPart, dvPart) = decomposePrimaryCellParts([segment])
            rows.append(
                RawExtractedRow(
                    nutrientLabelTranscript: labelPart,
                    weightTranscript: weightPart,
                    percentDVTranscript: dvPart,
                    rawCells: [segment],
                    minX: cell.minX,
                    midY: cell.midY,
                    boundingBox: cell.boundingBox,
                    indentationLevel: nutrient.indentationLevel,
                    columnIndex: 0
                )
            )
        }
        return rows
    }

    private static func tryExtractSideBySideMicronutrientRow(
        _ row: [ScannedTableCell],
        isSupplement: Bool
    ) -> [RawExtractedRow] {
        guard row.count >= 2 else { return [] }

        var microSegments: [(cell: ScannedTableCell, nutrient: CanonicalNutrientID)] = []
        for cell in row {
            let clean = cell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, !containsBulletDelimitedMicronutrients(clean) else { continue }
            let hasLetters = clean.unicodeScalars.contains { CharacterSet.letters.contains($0) }
                && !isPureUnitOrPercentToken(clean)
            guard hasLetters,
                  let nutrient = FDALexicalNormalizer.resolveNutrientID(from: clean),
                  nutrient.isMicronutrientRDI else {
                continue
            }
            microSegments.append((cell, nutrient))
        }

        // Only treat as Topology D side-by-side row if at least 2 distinct RDI micronutrients sit on the same row.
        let uniqueNutrients = Set(microSegments.map(\.nutrient))
        guard uniqueNutrients.count >= 2 else { return [] }

        // Group cells belonging to each micronutrient segment across the row.
        var results: [RawExtractedRow] = []
        var currentGroup: [ScannedTableCell] = []
        var currentNutrient: CanonicalNutrientID?

        for cell in row {
            let clean = cell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { continue }
            let hasLetters = clean.unicodeScalars.contains { CharacterSet.letters.contains($0) }
                && !isPureUnitOrPercentToken(clean)
            if hasLetters,
               let resolved = FDALexicalNormalizer.resolveNutrientID(from: clean),
               resolved.isMicronutrientRDI {
                if !currentGroup.isEmpty, let activeNutrient = currentNutrient {
                    results.append(makeSideBySideMicroRow(from: currentGroup, nutrient: activeNutrient))
                }
                currentGroup = [cell]
                currentNutrient = resolved
            } else if !currentGroup.isEmpty {
                currentGroup.append(cell)
            }
        }
        if !currentGroup.isEmpty, let activeNutrient = currentNutrient {
            results.append(makeSideBySideMicroRow(from: currentGroup, nutrient: activeNutrient))
        }

        return results
    }

    private static func makeSideBySideMicroRow(
        from group: [ScannedTableCell],
        nutrient: CanonicalNutrientID
    ) -> RawExtractedRow {
        let cellStrings = group
            .map { $0.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let (labelPart, weightPart, dvPart) = decomposePrimaryCellParts(cellStrings)
        let lead = group[0]
        let unionBox = group.dropFirst().reduce(lead.boundingBox) { $0.union($1.boundingBox) }
        return RawExtractedRow(
            nutrientLabelTranscript: labelPart,
            weightTranscript: weightPart,
            percentDVTranscript: dvPart,
            rawCells: cellStrings,
            minX: lead.minX,
            midY: unionBox.midY,
            boundingBox: unionBox,
            indentationLevel: nutrient.indentationLevel,
            columnIndex: 0
        )
    }

    // MARK: - Calories Row Extraction & Guarantee

    private static func tryExtractCalorieRow(
        from row: [ScannedTableCell],
        in table: ScannedTableGrid,
        preserveAllColumnCells: Bool = false
    ) -> RawExtractedRow? {
        for cell in row {
            let clean = cell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = clean.lowercased()
            guard lower.contains("calories")
                    && !lower.contains("calories from")
                    && !lower.contains("2,000 calories")
                    && !lower.contains("1,000 calories")
                    && !lower.contains("calories per gram") else {
                continue
            }

            // 1. Inline "Calories 230" in the same cell.
            if let inlineVal = extractInlineCalorieInt(from: clean) {
                return RawExtractedRow(
                    nutrientLabelTranscript: "Calories",
                    weightTranscript: "\(inlineVal)",
                    percentDVTranscript: "",
                    rawCells: ["Calories", "\(inlineVal)"],
                    minX: cell.minX,
                    midY: cell.midY,
                    boundingBox: cell.boundingBox,
                    indentationLevel: .level0,
                    columnIndex: 0
                )
            }

            // 2. Check other cells in the same row first (e.g. Topology F: `["Calories", "170", "300"]`).
            let sameRowNumericSiblings: [(cell: ScannedTableCell, value: Int)] = row.compactMap { sibling in
                guard sibling != cell else { return nil }
                let sibClean = sibling.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                guard let val = extractPureCalorieInt(from: sibClean) else { return nil }
                return (sibling, val)
            }
            if let firstSibling = sameRowNumericSiblings.first {
                let targetCells = preserveAllColumnCells ? sameRowNumericSiblings.map(\.cell) : [firstSibling.cell]
                let box = targetCells.reduce(cell.boundingBox) { $0.union($1.boundingBox) }
                let rawCalStrings = preserveAllColumnCells
                    ? (["Calories"] + sameRowNumericSiblings.map { "\($0.value)" })
                    : ["Calories", "\(firstSibling.value)"]
                return RawExtractedRow(
                    nutrientLabelTranscript: "Calories",
                    weightTranscript: "\(firstSibling.value)",
                    percentDVTranscript: "",
                    rawCells: rawCalStrings,
                    minX: cell.minX,
                    midY: box.midY,
                    boundingBox: box,
                    indentationLevel: .level0,
                    columnIndex: 0
                )
            }

            // 3. Check spanned cells across the table whose `rowRange` overlaps `cell.rowRange`
            //    (e.g. Topologies B, C, D, E, J where `230` or `130, 70, 100` has `rowspan="2"` starting on the `"Amount per serving"` row above `"Calories"`,
            //    or Topology I where `220, 440` is on the row immediately below `"Calories"`).
            let overlappingCells = table.allUniqueCells.filter { candidate in
                candidate != cell
                    && (candidate.rowRange.overlaps(cell.rowRange) || candidate.rowRange.lowerBound == cell.rowRange.upperBound + 1)
            }
            .sorted { lhs, rhs in
                if lhs.rowRange.overlaps(cell.rowRange) != rhs.rowRange.overlaps(cell.rowRange) {
                    return lhs.rowRange.overlaps(cell.rowRange)
                }
                return lhs.columnRange.lowerBound < rhs.columnRange.lowerBound
            }

            let overlappingCalorieNeighbors: [(cell: ScannedTableCell, value: Int)] = overlappingCells.compactMap { neighbor in
                let neighborClean = neighbor.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                guard let val = extractPureCalorieInt(from: neighborClean) else { return nil }
                return (neighbor, val)
            }
            if let firstNeighbor = overlappingCalorieNeighbors.first {
                let targetCells = preserveAllColumnCells ? overlappingCalorieNeighbors.map(\.cell) : [firstNeighbor.cell]
                let box = targetCells.reduce(cell.boundingBox) { $0.union($1.boundingBox) }
                let rawCalStrings = preserveAllColumnCells
                    ? (["Calories"] + overlappingCalorieNeighbors.map { "\($0.value)" })
                    : ["Calories", "\(firstNeighbor.value)"]
                return RawExtractedRow(
                    nutrientLabelTranscript: "Calories",
                    weightTranscript: "\(firstNeighbor.value)",
                    percentDVTranscript: "",
                    rawCells: rawCalStrings,
                    minX: cell.minX,
                    midY: box.midY,
                    boundingBox: box,
                    indentationLevel: .level0,
                    columnIndex: 0
                )
            }
        }
        return nil
    }

    // MARK: - Multi-Column Header, Serving & Milk-Column Filtering (Examples E, F, G, H, I, & M)

    private static func extractColumnMetadata(
        from table: ScannedTableGrid,
        classifiedLabel: FDAClassifiedLabel
    ) -> (columns: [ExtractedTableColumnMetadata], hadDiscardedMilkColumn: Bool) {
        let calorieValues = extractAllCalorieValues(in: table, fallbackCalorie: classifiedLabel.inferredCaloriesValue)

        // Case 1: Tabular Dual-Column (`Topology I`)
        if classifiedLabel.topology == .tabularDualColumn {
            let titles = ["Per Serving", "Per Container"]
            let cols = titles.enumerated().map { idx, title in
                ExtractedTableColumnMetadata(
                    columnIndex: idx,
                    rawPairIndex: idx,
                    headerTitle: title,
                    servingSizeTranscript: classifiedLabel.servingSizeTranscript,
                    caloriesValue: idx < calorieValues.count ? calorieValues[idx] : calorieValues.first
                )
            }
            return (cols, false)
        }

        // Case 2: Multi-Column Vertical (`Topologies E, F, G, H, M` or `table.columnCount >= 4`)
        if classifiedLabel.topology.isMultiColumn || table.columnCount >= 4 {
            var rawHeaders = discoverVerticalColumnHeaderTitles(in: table)
            let expectedColCount = max(rawHeaders.count, calorieValues.count)

            if rawHeaders.isEmpty && expectedColCount >= 2 {
                rawHeaders = (0..<expectedColCount).map { idx in
                    idx == 0 ? "Per Serving" : "Column \(idx + 1)"
                }
            } else if rawHeaders.count < expectedColCount {
                for idx in rawHeaders.count..<expectedColCount {
                    rawHeaders.append("Column \(idx + 1)")
                }
            }

            if rawHeaders.count >= 2 {
                let perColumnServings = extractPerColumnServingSizeTranscripts(
                    in: table,
                    rawColumnCount: rawHeaders.count,
                    fallbackServingLine: classifiedLabel.servingSizeTranscript
                )

                var keptColumns: [ExtractedTableColumnMetadata] = []
                var discardedMilk = false

                for rawIdx in 0..<rawHeaders.count {
                    let headerTitle = rawHeaders[rawIdx]
                    // Example M Rule: Discard any secondary column header that represents cereal combined with milk.
                    if rawIdx >= 1 && FDALexicalNormalizer.isCombinedWithMilkColumnHeader(headerTitle) {
                        discardedMilk = true
                        continue
                    }

                    let keptIdx = keptColumns.count
                    let servingLine = rawIdx < perColumnServings.count ? perColumnServings[rawIdx] : classifiedLabel.servingSizeTranscript
                    let calVal = rawIdx < calorieValues.count ? calorieValues[rawIdx] : calorieValues.first
                    keptColumns.append(
                        ExtractedTableColumnMetadata(
                            columnIndex: keptIdx,
                            rawPairIndex: rawIdx,
                            headerTitle: headerTitle,
                            servingSizeTranscript: servingLine,
                            caloriesValue: calVal
                        )
                    )
                }

                if !keptColumns.isEmpty {
                    return (keptColumns, discardedMilk)
                }
            }
        }

        // Default Single-Column Metadata
        let singleColumn = ExtractedTableColumnMetadata(
            columnIndex: 0,
            rawPairIndex: 0,
            headerTitle: "Per Serving",
            servingSizeTranscript: classifiedLabel.servingSizeTranscript,
            caloriesValue: calorieValues.first ?? classifiedLabel.inferredCaloriesValue
        )
        return ([singleColumn], false)
    }

    private static func discoverVerticalColumnHeaderTitles(in table: ScannedTableGrid) -> [String] {
        // Find the row index of the first macronutrient row (`Total Fat`) so we only inspect header rows above it.
        var firstMacroRowIndex = table.rows.count
        for (rIdx, row) in table.rows.enumerated() {
            let hasTotalFat = row.contains { cell in
                let firstLine = cell.transcript.components(separatedBy: .newlines).first ?? cell.transcript
                return FDALexicalNormalizer.resolveNutrientID(from: firstLine) == .totalFat
            }
            if hasTotalFat {
                firstMacroRowIndex = rIdx
                break
            }
        }

        let headerSearchRows = table.rows.prefix(firstMacroRowIndex)
        for row in headerSearchRows {
            var candidateTitles: [String] = []
            for cell in row.sorted(by: { $0.columnRange.lowerBound < $1.columnRange.lowerBound }) {
                let clean = cell.transcript
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty else { continue }
                let lower = clean.lowercased()

                // Exclude structural metadata cells, `% DV*` subheaders, serving size lines, and pure numeric/weight tokens.
                if lower == "nutrition facts"
                    || lower == "supplement facts"
                    || lower.contains("servings per container")
                    || lower.contains("serving per container")
                    || lower == "serving size"
                    || lower == "serv. size"
                    || lower == "amount per serving"
                    || lower == "amount/serving"
                    || lower == "calories"
                    || lower.hasPrefix("% daily value")
                    || lower.hasPrefix("% dv")
                    || extractPureCalorieInt(from: clean) != nil
                    || isStandaloneParenthesizedWeight(clean)
                    || isFootnoteCell(clean) {
                    continue
                }

                // Exclude cells that are pure serving size values on the "Serving size" row (e.g. "1/4 cup dry mix (44g)", "1 cup (255g)", "1 box")
                let rowHasServingSizeLabel = row.contains {
                    let l = $0.transcript.lowercased()
                    return l.contains("serving size") || l.contains("serv. size") || l.contains("servings per container")
                }
                if rowHasServingSizeLabel {
                    continue
                }

                candidateTitles.append(clean)
            }

            if candidateTitles.count >= 2 {
                return candidateTitles
            }
        }

        return []
    }

    private static func extractPerColumnServingSizeTranscripts(
        in table: ScannedTableGrid,
        rawColumnCount: Int,
        fallbackServingLine: String?
    ) -> [String?] {
        // Check for Aggregate Variety Pack (`Example E`) pattern where `rawColumnCount` parenthesized metric weights
        // (e.g. `(35g)`, `(19g)`, `(27g)`) sit alongside a shared household measure (e.g. `1 box`).
        var metricCells: [ScannedTableCell] = []
        var sharedHouseholdText: String?

        for cell in table.allUniqueCells where cell.rowRange.lowerBound <= 2 {
            let clean = cell.transcript
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { continue }
            if isStandaloneParenthesizedWeight(clean) {
                metricCells.append(cell)
            } else {
                let lower = clean.lowercased()
                if !lower.contains("nutrition facts")
                    && !lower.contains("supplement facts")
                    && !lower.contains("serving per container")
                    && !lower.contains("servings per container")
                    && !lower.contains("serving size")
                    && !lower.contains("amount per serving")
                    && !lower.contains("calories")
                    && clean.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) })
                    && clean.unicodeScalars.contains(where: { CharacterSet.letters.contains($0) }) {
                    if sharedHouseholdText == nil {
                        sharedHouseholdText = clean
                    }
                }
            }
        }

        metricCells.sort { $0.columnRange.lowerBound < $1.columnRange.lowerBound }
        if metricCells.count == rawColumnCount {
            let hhPrefix = sharedHouseholdText.map { "\($0) " } ?? ""
            return metricCells.map { cell in
                let weightText = cell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                return "Serving size \(hhPrefix)\(weightText)"
            }
        }

        return Array(repeating: fallbackServingLine, count: rawColumnCount)
    }

    private static func extractAllCalorieValues(
        in table: ScannedTableGrid,
        fallbackCalorie: Int?
    ) -> [Int] {
        for row in table.rows {
            if let calRow = tryExtractCalorieRow(from: row, in: table, preserveAllColumnCells: true) {
                let values = calRow.rawCells.dropFirst().compactMap { extractPureCalorieInt(from: $0) }
                if !values.isEmpty {
                    return values
                }
            }
        }
        if let fallbackCalorie {
            return [fallbackCalorie]
        }
        return []
    }

    private static func isStandaloneParenthesizedWeight(_ text: String) -> Bool {
        let pattern = #"^\(\s*[0-9]+(?:\.[0-9]+)?\s*(?:g|grams?|ml|oz)\s*\)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func ensureCaloriesRowIfNeeded(
        in rows: [RawExtractedRow],
        table: ScannedTableGrid,
        inferredCaloriesValue: Int?
    ) -> [RawExtractedRow] {
        let alreadyHasCalories = rows.contains { row in
            FDALexicalNormalizer.resolveNutrientID(from: row.combinedTranscript) == .calories
        }
        guard !alreadyHasCalories, let calValue = inferredCaloriesValue else {
            return rows
        }

        let synthesizedCalorieRow = RawExtractedRow(
            nutrientLabelTranscript: "Calories",
            weightTranscript: "\(calValue)",
            percentDVTranscript: "",
            rawCells: ["Calories", "\(calValue)"],
            minX: table.minX,
            midY: table.minY,
            boundingBox: CGRect(x: table.minX, y: table.minY, width: table.width, height: 0.02),
            indentationLevel: .level0,
            columnIndex: 0
        )
        return [synthesizedCalorieRow] + rows
    }

    // MARK: - Cell Decomposition & Indentation Helpers

    private static func decomposePrimaryCellParts(
        _ cellStrings: [String]
    ) -> (label: String, weight: String, percentDV: String) {
        guard !cellStrings.isEmpty else { return ("", "", "") }

        if cellStrings.count == 1 {
            let single = FDALexicalNormalizer.stripDotLeaders(cellStrings[0])
            let dvMatch = extractPercentToken(from: single) ?? ""
            let weightMatch = extractFirstWeightToken(from: single) ?? ""
            return (single, weightMatch, dvMatch)
        }

        if cellStrings.count == 2 {
            let first = FDALexicalNormalizer.stripDotLeaders(cellStrings[0])
            let second = cellStrings[1]
            if isPercentOrFootnoteSymbolToken(second) && !containsQuantitativeWeightToken(second) {
                let weightMatch = extractFirstWeightToken(from: first) ?? ""
                return (first, weightMatch, second)
            } else {
                let dvMatch = extractPercentToken(from: second) ?? ""
                return (first, second, dvMatch)
            }
        }

        let first = FDALexicalNormalizer.stripDotLeaders(cellStrings[0])
        let second = cellStrings[1]
        let third = cellStrings[2]
        return (first, second, third)
    }

    private static func resolveIndentationLevel(
        for cell: ScannedTableCell,
        resolvedNutrient: CanonicalNutrientID,
        baselineMinX: CGFloat
    ) -> NutrientIndentationLevel {
        // 1. Check leading non-breaking or ASCII spaces in the raw cell text.
        let rawLine = cell.transcript.components(separatedBy: .newlines).first ?? cell.transcript
        var leadingSpaces = 0
        for ch in rawLine {
            if ch == " " || ch == "\u{00A0}" {
                leadingSpaces += 1
            } else if ch == "\t" {
                leadingSpaces += 4
            } else {
                break
            }
        }
        if leadingSpaces >= 6 {
            return .level2
        } else if leadingSpaces >= 2 {
            return .level1
        }

        // 2. Check normalized `minX` offset of the first line observation inside the cell relative to the stack baseline.
        let effectiveMinX = cell.lines.first?.minX ?? cell.minX
        let deltaX = effectiveMinX - baselineMinX
        if deltaX >= 0.045 {
            return .level2
        } else if deltaX >= 0.018 {
            return .level1
        }

        // 3. Fallback to canonical FDA nutrient indentation hierarchy (§ 101.9(c)).
        return resolvedNutrient.indentationLevel
    }

    private static func computeStackBaselineMinX(
        in table: ScannedTableGrid,
        stackSide: TabularStackSide,
        layout: TabularColumnLayout
    ) -> CGFloat {
        let targetNutrients: Set<CanonicalNutrientID> = (stackSide == .left)
            ? [.totalFat, .cholesterol, .sodium]
            : [.totalCarbohydrate, .protein]

        let matchingMinXs: [CGFloat] = table.allUniqueCells.compactMap { cell in
            let firstLine = cell.transcript.components(separatedBy: .newlines).first ?? cell.transcript
            guard let id = FDALexicalNormalizer.resolveNutrientID(from: firstLine),
                  targetNutrients.contains(id) else {
                return nil
            }
            return cell.lines.first?.minX ?? cell.minX
        }

        return matchingMinXs.min() ?? table.minX
    }

    private static func computeVerticalBaselineMinX(in table: ScannedTableGrid) -> CGFloat {
        let topLevelNutrients: Set<CanonicalNutrientID> = [
            .totalFat, .cholesterol, .sodium, .totalCarbohydrate, .protein
        ]
        let matchingMinXs: [CGFloat] = table.allUniqueCells.compactMap { cell in
            let firstLine = cell.transcript.components(separatedBy: .newlines).first ?? cell.transcript
            guard let id = FDALexicalNormalizer.resolveNutrientID(from: firstLine),
                  topLevelNutrients.contains(id) else {
                return nil
            }
            return cell.lines.first?.minX ?? cell.minX
        }
        return matchingMinXs.min() ?? table.minX
    }

    // MARK: - Classification & Filtering Predicates

    private static func shouldUseTabularUnpacker(for table: ScannedTableGrid) -> Bool {
        let leftMacros: Set<CanonicalNutrientID> = [.totalFat, .saturatedFat, .transFat, .cholesterol, .sodium]
        let rightMacros: Set<CanonicalNutrientID> = [.totalCarbohydrate, .dietaryFiber, .totalSugars, .addedSugars, .protein]

        for row in table.rows {
            var hasLeft = false
            var hasRight = false
            for cell in row {
                let firstLine = cell.transcript.components(separatedBy: .newlines).first ?? cell.transcript
                if let id = FDALexicalNormalizer.resolveNutrientID(from: firstLine) {
                    if leftMacros.contains(id) { hasLeft = true }
                    if rightMacros.contains(id) { hasRight = true }
                }
            }
            if hasLeft && hasRight {
                return true
            }
        }
        return false
    }

    private static func isTabularSidebarMetadataCell(
        _ cell: ScannedTableCell,
        in table: ScannedTableGrid,
        layout: TabularColumnLayout
    ) -> Bool {
        let clean = cell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if isHeaderMetadataLine(clean) {
            return true
        }
        // Also filter out pure calorie integer cells (e.g. "170", "90", "220", "440") and standalone household serving lines (e.g. "1 cup (255g)" or "1/3 cup (56g)") in the left sidebar columns.
        if let maxSidebarCol = layout.sidebarMaxColumn,
           cell.columnRange.upperBound <= maxSidebarCol {
            if FDALexicalNormalizer.resolveNutrientID(from: clean) == nil {
                return true
            }
            if FDALexicalNormalizer.resolveNutrientID(from: clean) == .calories {
                return true
            }
        }
        if extractPureCalorieInt(from: clean) != nil && cell.rowSpan >= 2 && cell.columnRange.lowerBound <= 1 {
            return true
        }
        return false
    }

    private static func isHeaderMetadataLine(_ text: String) -> Bool {
        let expanded = FDALexicalNormalizer.expandAuthorizedAbbreviations(text)
        let lower = expanded.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if lower == "nutrition facts"
            || lower == "supplement facts"
            || lower == "per serving"
            || lower == "per container"
            || lower == "amount per serving"
            || lower == "amount/serving"
            || lower == "calories" {
            return true
        }

        if (lower.contains("nutrition facts") || lower.contains("supplement facts") || lower.contains("serving size") || lower.contains("servings per container") || lower.contains("about ") && lower.contains("servings"))
            && FDALexicalNormalizer.resolveNutrientID(from: text) == nil {
            return true
        }

        return false
    }

    private static func isPureColumnHeaderCell(_ text: String) -> Bool {
        let lower = text.replacingOccurrences(of: "\n", with: " ")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if FDALexicalNormalizer.resolveNutrientID(from: lower) != nil {
            return false
        }

        let headerPatterns = [
            "amount/serving",
            "amount per serving",
            "% daily value",
            "% daily value*",
            "% dv",
            "% dv*",
            "per serving",
            "per container",
            "per unit",
            "per day",
            "dry mix",
            "baked portion",
            "prepared portion",
            "as packaged",
            "as prepared"
        ]
        return headerPatterns.contains { lower == $0 || lower.hasPrefix($0) }
    }

    private static func isFootnoteCell(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("tells you how much a nutrient")
            || lower.contains("2,000 calories a day is used")
            || lower.contains("1,000 calories a day is used")
            || lower.contains("not a significant source of")
            || lower.contains("% dv = % daily value")
            || lower.contains("daily value not established")
            || lower.contains("percent daily values are based on")
    }

    private static func tryUnpackMultiLineMergedRow(_ cells: [ScannedTableCell]) -> [RawExtractedRow] {
        guard let leadCell = cells.first else { return [] }
        let multiLines = leadCell.transcript
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard multiLines.count >= 2 else { return [] }

        let resolvedCount = multiLines.compactMap { FDALexicalNormalizer.resolveNutrientID(from: $0) }.count
        guard resolvedCount >= 2 else { return [] }

        let tailCellLines: [[String]] = cells.dropFirst().map { cell in
            cell.transcript
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        let unionBox = cells.dropFirst().reduce(leadCell.boundingBox) { $0.union($1.boundingBox) }
        let sliceHeight = max(0.01, unionBox.height / CGFloat(multiLines.count))

        var unpacked: [RawExtractedRow] = []
        for (idx, lineText) in multiLines.enumerated() {
            guard let nutrient = FDALexicalNormalizer.resolveNutrientID(from: lineText) else { continue }
            var rowCells: [String] = [lineText]
            for tailLines in tailCellLines where tailLines.count == multiLines.count {
                rowCells.append(tailLines[idx])
            }
            let (labelPart, weightPart, dvPart) = decomposePrimaryCellParts(rowCells)
            let sliceBox = CGRect(
                x: unionBox.minX,
                y: unionBox.minY + CGFloat(idx) * sliceHeight,
                width: unionBox.width,
                height: sliceHeight
            )
            unpacked.append(
                RawExtractedRow(
                    nutrientLabelTranscript: labelPart,
                    weightTranscript: weightPart,
                    percentDVTranscript: dvPart,
                    rawCells: rowCells,
                    minX: leadCell.minX,
                    midY: sliceBox.midY,
                    boundingBox: sliceBox,
                    indentationLevel: nutrient.indentationLevel,
                    columnIndex: 0
                )
            )
        }
        return unpacked
    }

    private static func containsQuantitativeWeightToken(_ text: String) -> Bool {
        let pattern = #"(?i)(?:<|less\s+than\s+)?[oO0-9]+(?:\.[0-9]+)?\s*(?:g|mg|mcg|µg|ug|iu|kcal|cal)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func isPercentOrFootnoteSymbolToken(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if trimmed.contains("%") { return true }
        let symbolSet = CharacterSet(charactersIn: "*†‡§+ ")
        return trimmed.unicodeScalars.allSatisfy { symbolSet.contains($0) }
    }

    private static func isPureUnitOrPercentToken(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPercentOrFootnoteSymbolToken(trimmed) { return true }
        let pattern = #"(?i)^(?:<|less\s+than\s+)?[oO0-9]+(?:\.[0-9]+)?\s*(?:g|mg|mcg|µg|ug|iu|%)?[*†‡]?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil
    }

    private static func extractFirstWeightToken(from text: String) -> String? {
        let pattern = #"(?i)((?:<|less\s+than\s+)?[oO0-9]+(?:\.[0-9]+)?\s*(?:mcg\s*dfe|mcg\s*rae|mg\s*ne|g|mg|mcg|µg|ug|iu))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func extractPercentToken(from text: String) -> String? {
        let pattern = #"(?i)((?:<|less\s+than\s+)?[oO0-9]+(?:\.[0-9]+)?\s*%)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func extractInlineCalorieInt(from text: String) -> Int? {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        let pattern = #"(?i)\bcalories\b[^0-9<>]*([0-9]{1,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
              let range = Range(match.range(at: 1), in: cleaned),
              let value = Int(cleaned[range]),
              value <= 5000 else {
            return nil
        }
        return value
    }

    private static func extractPureCalorieInt(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^([0-9]{1,4})$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let range = Range(match.range(at: 1), in: trimmed),
              let value = Int(trimmed[range]),
              value <= 5000 else {
            return nil
        }
        return value
    }

    private static func deduplicateExtractedRows(_ rows: [RawExtractedRow]) -> [RawExtractedRow] {
        var seen = Set<String>()
        var unique: [RawExtractedRow] = []
        for row in rows {
            let key = "\(row.rawCells.joined(separator: "|").lowercased())"
            if seen.insert(key).inserted {
                unique.append(row)
            }
        }
        return unique
    }
}
