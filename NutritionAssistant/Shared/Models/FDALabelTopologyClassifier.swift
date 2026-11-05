//
//  FDALabelTopologyClassifier.swift
//  NutritionAssistant
//
//  Milestone 4.2: Topology & Sidebar Classifier
//  Inspects ScannedDocumentSnapshot against the 12 HTML archetypes (A–L) in
//  Docs/FDA_Labeling_Guidelines/FDA_Labeling-Guidelines_StructureExamples.md
//  and Part 1.6 / Part 3 of Docs/FDA_Labeling_Guidelines/FDA_Labeling Guidelines_Summary.md.
//

import CoreGraphics
import Foundation

// MARK: - Unified Intermediate Row Structure (Shared by Milestones 4.2, 4.3, 4.4, & 4.5)

/// A single extracted nutrient row produced by either the 2D table grid unpacker (`VisionTableRowExtractor`)
/// or the curved-surface spatial stitcher (`VisionSpatialRowStitcher`), ready for Phase 1 lexical normalization.
struct RawExtractedRow: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: UUID
    let nutrientLabelTranscript: String
    let weightTranscript: String
    let percentDVTranscript: String
    let rawCells: [String]
    let minX: CGFloat
    let midY: CGFloat
    let boundingBox: CGRect
    let indentationLevel: NutrientIndentationLevel
    let columnIndex: Int
    let isHeaderOrFooter: Bool

    var combinedTranscript: String {
        rawCells.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(
        id: UUID = UUID(),
        nutrientLabelTranscript: String,
        weightTranscript: String = "",
        percentDVTranscript: String = "",
        rawCells: [String]? = nil,
        minX: CGFloat = 0,
        midY: CGFloat = 0,
        boundingBox: CGRect = .zero,
        indentationLevel: NutrientIndentationLevel = .level0,
        columnIndex: Int = 0,
        isHeaderOrFooter: Bool = false
    ) {
        self.id = id
        self.nutrientLabelTranscript = nutrientLabelTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        self.weightTranscript = weightTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        self.percentDVTranscript = percentDVTranscript.trimmingCharacters(in: .whitespacesAndNewlines)

        if let explicitCells = rawCells?.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }).filter({ !$0.isEmpty }),
           !explicitCells.isEmpty {
            self.rawCells = explicitCells
        } else {
            var synthesized: [String] = []
            if !self.nutrientLabelTranscript.isEmpty {
                synthesized.append(self.nutrientLabelTranscript)
            }
            if !self.weightTranscript.isEmpty {
                synthesized.append(self.weightTranscript)
            }
            if !self.percentDVTranscript.isEmpty {
                synthesized.append(self.percentDVTranscript)
            }
            self.rawCells = synthesized
        }

        self.minX = minX
        self.midY = midY
        self.boundingBox = boundingBox
        self.indentationLevel = indentationLevel
        self.columnIndex = columnIndex
        self.isHeaderOrFooter = isHeaderOrFooter
    }
}

// MARK: - Classification Result

/// Complete topological classification and recovered header/sidebar metadata for a candidate FDA label region.
struct FDAClassifiedLabel: Codable, Sendable, Equatable, Hashable {
    let topology: FDALabelTopology
    let isSupplement: Bool
    let primaryTable: ScannedTableGrid?
    let supplementaryTables: [ScannedTableGrid]
    let labelRegionBoundingBox: CGRect
    let titleTranscript: String?
    let servingSizeTranscript: String?
    let servingsPerContainerTranscript: String?
    let caloriesTranscript: String?
    let inferredCaloriesValue: Int?
    let footnoteTranscripts: [String]
    let columnHeaderTranscripts: [String]
    let attachedHeaderBlocks: [ScannedTextBlock]
    let attachedSidebarBlocks: [ScannedTextBlock]
    let attachedBodyBlocks: [ScannedTextBlock]
    let allLabelLines: [String]
    let medianBodyLineHeight: CGFloat
    let legitimateExemption: FDALegitimateExemptionKind?

    init(
        topology: FDALabelTopology,
        isSupplement: Bool,
        primaryTable: ScannedTableGrid? = nil,
        supplementaryTables: [ScannedTableGrid] = [],
        labelRegionBoundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1),
        titleTranscript: String? = nil,
        servingSizeTranscript: String? = nil,
        servingsPerContainerTranscript: String? = nil,
        caloriesTranscript: String? = nil,
        inferredCaloriesValue: Int? = nil,
        footnoteTranscripts: [String] = [],
        columnHeaderTranscripts: [String] = [],
        attachedHeaderBlocks: [ScannedTextBlock] = [],
        attachedSidebarBlocks: [ScannedTextBlock] = [],
        attachedBodyBlocks: [ScannedTextBlock] = [],
        allLabelLines: [String] = [],
        medianBodyLineHeight: CGFloat = 0.018,
        legitimateExemption: FDALegitimateExemptionKind? = nil
    ) {
        self.topology = topology
        self.isSupplement = isSupplement
        self.primaryTable = primaryTable
        self.supplementaryTables = supplementaryTables
        self.labelRegionBoundingBox = labelRegionBoundingBox
        self.titleTranscript = titleTranscript
        self.servingSizeTranscript = servingSizeTranscript
        self.servingsPerContainerTranscript = servingsPerContainerTranscript
        self.caloriesTranscript = caloriesTranscript
        self.inferredCaloriesValue = inferredCaloriesValue
        self.footnoteTranscripts = footnoteTranscripts
        self.columnHeaderTranscripts = columnHeaderTranscripts
        self.attachedHeaderBlocks = attachedHeaderBlocks
        self.attachedSidebarBlocks = attachedSidebarBlocks
        self.attachedBodyBlocks = attachedBodyBlocks
        self.allLabelLines = allLabelLines
        self.medianBodyLineHeight = medianBodyLineHeight
        self.legitimateExemption = legitimateExemption
    }
}

// MARK: - FDA Label Topology & Sidebar Classifier

enum FDALabelTopologyClassifier {

    /// Classifies the `ScannedDocumentSnapshot` into one of the 12 canonical `21 CFR § 101.9` topologies (`A`–`L`)
    /// or `21 CFR § 101.36` `Supplement Facts`, and recovers detached headers, serving sizes, calories, and sidebars
    /// using normalized spatial proximity and `Part 1.6` bounding-box height hierarchy.
    static func classify(snapshot: ScannedDocumentSnapshot) -> FDAClassifiedLabel {
        // 1. Score and select primary & supplementary tables.
        let scoredTables = snapshot.tables
            .map { (table: $0, score: scoreCandidateTable($0)) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }

        let primaryTable = scoredTables.first?.table
        let supplementaryTables: [ScannedTableGrid] = scoredTables.dropFirst().compactMap { candidate in
            guard let primary = primaryTable else { return nil }
            let verticalOverlap = min(primary.maxY, candidate.table.maxY) - max(primary.minY, candidate.table.minY)
            let minHeight = max(0.001, min(primary.height, candidate.table.height))
            let horizontalGap = max(0, max(primary.minX, candidate.table.minX) - min(primary.maxX, candidate.table.maxX))
            if (verticalOverlap / minHeight) >= 0.25 && horizontalGap <= 0.25 {
                return candidate.table
            }
            return nil
        }

        // 2. Establish the normalized spatial anchor box for the candidate label region.
        let anchorBox = computeAnchorBoundingBox(
            primaryTable: primaryTable,
            supplementaryTables: supplementaryTables,
            textBlocks: snapshot.textBlocks,
            fallbackBox: snapshot.boundingBox
        )

        // Expand search region around the anchor box to recover detached headers, left sidebars (Topologies A, I, K),
        // right-hand continuation panels/footnotes (Part 1.1 & Part 3.4), and bottom footers.
        let expandedSearchBox = CGRect(
            x: max(0.0, anchorBox.minX - 0.38),
            y: max(0.0, anchorBox.minY - 0.28),
            width: min(1.0, anchorBox.width + 0.72),
            height: min(1.0, anchorBox.height + 0.46)
        )

        // 3. Partition spatially adjacent textBlocks into header, sidebar, and body blocks (excluding inside-table duplicates).
        let (headerBlocks, sidebarBlocks, bodyBlocks) = partitionAdjacentTextBlocks(
            textBlocks: snapshot.textBlocks,
            primaryTable: primaryTable,
            supplementaryTables: supplementaryTables,
            anchorBox: anchorBox,
            expandedSearchBox: expandedSearchBox
        )

        // 4. Collect all line observations in the label region to compute the Part 1.6 typographic height hierarchy.
        let allLinesWithGeometry = collectAllRegionalLines(
            primaryTable: primaryTable,
            supplementaryTables: supplementaryTables,
            headerBlocks: headerBlocks,
            sidebarBlocks: sidebarBlocks,
            bodyBlocks: bodyBlocks,
            titleBlock: snapshot.title
        )

        let medianBodyHeight = computeMedianNutrientBodyHeight(from: allLinesWithGeometry)

        // 5. Recover title, serving size, servings per container, calories (using Part 1.6 height hierarchy), and footnotes.
        let headerRecovery = recoverHeaderAndSidebarMetadata(
            primaryTable: primaryTable,
            supplementaryTables: supplementaryTables,
            regionalLines: allLinesWithGeometry,
            medianBodyHeight: medianBodyHeight
        )

        let allPlainLines = buildOrderedLabelLines(
            primaryTable: primaryTable,
            supplementaryTables: supplementaryTables,
            headerBlocks: headerBlocks,
            sidebarBlocks: sidebarBlocks,
            bodyBlocks: bodyBlocks,
            headerRecovery: headerRecovery
        )

        // 6. Resolve FDALabelTopology against Archetypes A–L and Part 3 Supplement Facts.
        let resolvedTopology = resolveTopology(
            primaryTable: primaryTable,
            supplementaryTables: supplementaryTables,
            allLines: allPlainLines,
            headerRecovery: headerRecovery,
            bodyBlocks: bodyBlocks
        )

        let isSupplement = resolvedTopology.isSupplementFacts || headerRecovery.isSupplementHeader

        let unionLabelBox = computeUnionBoundingBox(
            anchorBox: anchorBox,
            headerBlocks: headerBlocks,
            sidebarBlocks: sidebarBlocks,
            bodyBlocks: bodyBlocks
        )

        return FDAClassifiedLabel(
            topology: resolvedTopology,
            isSupplement: isSupplement,
            primaryTable: primaryTable,
            supplementaryTables: supplementaryTables,
            labelRegionBoundingBox: unionLabelBox,
            titleTranscript: headerRecovery.titleTranscript,
            servingSizeTranscript: headerRecovery.servingSizeTranscript,
            servingsPerContainerTranscript: headerRecovery.servingsPerContainerTranscript,
            caloriesTranscript: headerRecovery.caloriesTranscript,
            inferredCaloriesValue: headerRecovery.inferredCaloriesValue,
            footnoteTranscripts: headerRecovery.footnoteTranscripts,
            columnHeaderTranscripts: headerRecovery.columnHeaderTranscripts,
            attachedHeaderBlocks: headerBlocks,
            attachedSidebarBlocks: sidebarBlocks,
            attachedBodyBlocks: bodyBlocks,
            allLabelLines: allPlainLines,
            medianBodyLineHeight: medianBodyHeight,
            legitimateExemption: snapshot.detectedExemptions.first
        )
    }

    // MARK: - Step 1: Candidate Table Scoring

    private static func scoreCandidateTable(_ table: ScannedTableGrid) -> Int {
        var score = 0
        let cells = table.allUniqueCells
        guard !cells.isEmpty else { return 0 }

        let fullText = cells.map(\.transcript).joined(separator: " ")
        if FDALexicalNormalizer.isMandatoryBoxedWarning(fullText) {
            return 0
        }

        let lowerFull = fullText.lowercased()
        if lowerFull.contains("nutrition facts") || lowerFull.contains("supplement facts") {
            score += 35
        }
        if lowerFull.contains("serving size") || lowerFull.contains("serv. size") {
            score += 20
        }
        if lowerFull.contains("amount per serving") || lowerFull.contains("amount/serving") {
            score += 20
        }
        if lowerFull.contains("daily value") || lowerFull.contains("% dv") {
            score += 20
        }

        var distinctNutrients = Set<CanonicalNutrientID>()
        for cell in cells {
            for line in cell.transcript.components(separatedBy: .newlines) {
                if let nutrient = FDALexicalNormalizer.resolveNutrientID(from: line) {
                    distinctNutrients.insert(nutrient)
                }
            }
        }
        score += distinctNutrients.count * 12

        // Reject tiny non-nutrition tables with neither a label header nor at least 2 recognized nutrients.
        if score < 24 && distinctNutrients.count < 2 {
            return 0
        }
        return score
    }

    // MARK: - Step 2 & 3: Spatial Region & Adjacent Block Partitioning

    private static func computeAnchorBoundingBox(
        primaryTable: ScannedTableGrid?,
        supplementaryTables: [ScannedTableGrid],
        textBlocks: [ScannedTextBlock],
        fallbackBox: CGRect
    ) -> CGRect {
        if let primary = primaryTable {
            return supplementaryTables.reduce(primary.boundingBox) { $0.union($1.boundingBox) }
        }

        // If no table was detected, anchor around textBlocks containing nutrition headers or canonical nutrients.
        let relevantBlocks = textBlocks.filter { block in
            let lower = block.transcript.lowercased()
            if lower.contains("nutrition facts")
                || lower.contains("supplement facts")
                || lower.contains("serving size")
                || lower.contains("serv. size")
                || lower.contains("calories")
                || lower.contains("daily value")
                || lower.contains("% dv") {
                return true
            }
            for line in block.transcript.components(separatedBy: .newlines) {
                if FDALexicalNormalizer.resolveNutrientID(from: line) != nil {
                    return true
                }
            }
            return false
        }

        guard let first = relevantBlocks.first else {
            return fallbackBox
        }
        return relevantBlocks.dropFirst().reduce(first.boundingBox) { $0.union($1.boundingBox) }
    }

    private static func partitionAdjacentTextBlocks(
        textBlocks: [ScannedTextBlock],
        primaryTable: ScannedTableGrid?,
        supplementaryTables: [ScannedTableGrid],
        anchorBox: CGRect,
        expandedSearchBox: CGRect
    ) -> (headers: [ScannedTextBlock], sidebars: [ScannedTextBlock], body: [ScannedTextBlock]) {
        let allTables = ([primaryTable].compactMap { $0 }) + supplementaryTables

        var headers: [ScannedTextBlock] = []
        var sidebars: [ScannedTextBlock] = []
        var body: [ScannedTextBlock] = []

        for block in textBlocks {
            // Skip blocks that are marketing decoys or warnings or external ingredient lists (v1 scope boundary).
            if FDALexicalNormalizer.isMandatoryBoxedWarning(block.transcript)
                || FDALexicalNormalizer.isDecoyComparativeString(block.transcript)
                || isExternalIngredientBlock(block.transcript) {
                continue
            }

            // Check if this block is already geometrically inside one of the tables with matching text.
            let isDuplicateInsideTable = allTables.contains { table in
                guard table.boundingBox.insetBy(dx: -0.015, dy: -0.015).intersects(block.boundingBox) else {
                    return false
                }
                return table.allUniqueCells.contains { cell in
                    let overlapX = min(cell.maxX, block.maxX) - max(cell.minX, block.minX)
                    let overlapY = min(cell.maxY, block.maxY) - max(cell.minY, block.minY)
                    if overlapX > 0 && overlapY > 0 {
                        let normCell = normalizeWhitespace(cell.transcript)
                        let normBlock = normalizeWhitespace(block.transcript)
                        return normCell.contains(normBlock) || normBlock.contains(normCell)
                    }
                    return false
                }
            }

            if isDuplicateInsideTable {
                continue
            }

            let isNutritionRelated = isNutritionRelevantBlock(block.transcript)
            guard expandedSearchBox.intersects(block.boundingBox) || isNutritionRelated else {
                continue
            }

            if primaryTable == nil {
                // When no table exists, classify blocks above the first nutrient line as header, others as body.
                if isHeaderOrServingOnlyBlock(block.transcript) {
                    headers.append(block)
                } else {
                    body.append(block)
                }
                continue
            }

            // Relative to primaryTable:
            // 1. Above the top of the table (or overlapping top edge) -> Header block
            if block.midY <= (anchorBox.minY + 0.06) {
                headers.append(block)
            }
            // 2. To the left or right of the table with vertical overlap -> Sidebar block (Tabular A, I, K left sidebar or right footnote)
            else if (block.maxX <= anchorBox.minX + 0.08 || block.minX >= anchorBox.maxX - 0.08)
                        && block.maxY >= anchorBox.minY - 0.04
                        && block.minY <= anchorBox.maxY + 0.04 {
                sidebars.append(block)
            }
            // 3. Otherwise (fractured curved-surface rows or bottom footnotes) -> Body block
            else {
                body.append(block)
            }
        }

        return (headers, sidebars, body)
    }

    // MARK: - Step 4 & 5: Part 1.6 Typography Hierarchy & Header/Sidebar Recovery

    private struct HeaderRecoverySummary {
        var titleTranscript: String?
        var isSupplementHeader: Bool = false
        var servingSizeTranscript: String?
        var servingsPerContainerTranscript: String?
        var caloriesTranscript: String?
        var inferredCaloriesValue: Int?
        var footnoteTranscripts: [String] = []
        var columnHeaderTranscripts: [String] = []
    }

    private static func collectAllRegionalLines(
        primaryTable: ScannedTableGrid?,
        supplementaryTables: [ScannedTableGrid],
        headerBlocks: [ScannedTextBlock],
        sidebarBlocks: [ScannedTextBlock],
        bodyBlocks: [ScannedTextBlock],
        titleBlock: ScannedTextBlock?
    ) -> [ScannedTextLine] {
        var lines: [ScannedTextLine] = []

        if let title = titleBlock {
            lines.append(contentsOf: effectiveLines(for: title))
        }
        for block in headerBlocks + sidebarBlocks + bodyBlocks {
            lines.append(contentsOf: effectiveLines(for: block))
        }
        for table in ([primaryTable].compactMap { $0 }) + supplementaryTables {
            for cell in table.allUniqueCells {
                if !cell.lines.isEmpty {
                    lines.append(contentsOf: cell.lines)
                } else {
                    let sublines = cell.transcript
                        .components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    guard !sublines.isEmpty else { continue }
                    let sliceHeight = cell.height / CGFloat(sublines.count)
                    for (idx, text) in sublines.enumerated() {
                        let subRect = CGRect(
                            x: cell.minX,
                            y: cell.minY + CGFloat(idx) * sliceHeight,
                            width: cell.width,
                            height: sliceHeight
                        )
                        lines.append(ScannedTextLine(transcript: text, boundingBox: subRect))
                    }
                }
            }
        }

        return lines.sorted { lhs, rhs in
            if abs(lhs.midY - rhs.midY) > 0.006 {
                return lhs.midY < rhs.midY
            }
            return lhs.minX < rhs.minX
        }
    }

    private static func effectiveLines(for block: ScannedTextBlock) -> [ScannedTextLine] {
        if !block.lines.isEmpty {
            return block.lines
        }
        let rawLines = block.transcript
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !rawLines.isEmpty else { return [] }
        let lineHeight = block.height / CGFloat(rawLines.count)
        return rawLines.enumerated().map { idx, text in
            ScannedTextLine(
                transcript: text,
                boundingBox: CGRect(
                    x: block.minX,
                    y: block.minY + CGFloat(idx) * lineHeight,
                    width: block.width,
                    height: lineHeight
                ),
                isTitle: block.isTitle
            )
        }
    }

    /// Computes the median normalized bounding-box height of standard nutrient body lines (`Part 1.6`: `8 pt` / `6 pt` baseline).
    private static func computeMedianNutrientBodyHeight(from lines: [ScannedTextLine]) -> CGFloat {
        let bodyHeights: [CGFloat] = lines.compactMap { line in
            guard line.height > 0.002 && line.height < 0.12 else { return nil }
            guard let nutrient = FDALexicalNormalizer.resolveNutrientID(from: line.transcript),
                  nutrient != .calories,
                  nutrient != .caloriesFromFat,
                  nutrient != .caloriesFromSaturatedFat else {
                return nil
            }
            return line.height
        }.sorted()

        guard !bodyHeights.isEmpty else {
            let allValid = lines.map(\.height).filter { $0 > 0.002 && $0 < 0.10 }.sorted()
            guard !allValid.isEmpty else { return 0.018 }
            return allValid[allValid.count / 2]
        }

        return bodyHeights[bodyHeights.count / 2]
    }

    private static func recoverHeaderAndSidebarMetadata(
        primaryTable: ScannedTableGrid?,
        supplementaryTables: [ScannedTableGrid],
        regionalLines: [ScannedTextLine],
        medianBodyHeight: CGFloat
    ) -> HeaderRecoverySummary {
        var summary = HeaderRecoverySummary()

        // 1. Inspect regional lines for title, supplement header, footnotes, and column headers.
        for (index, line) in regionalLines.enumerated() {
            let text = line.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            let expanded = FDALexicalNormalizer.expandAuthorizedAbbreviations(text)
            let lower = expanded.lowercased()

            // Title detection (Part 1.6 second largest height >= 16pt or explicit lexical match)
            if lower.contains("supplement facts") {
                summary.isSupplementHeader = true
                if summary.titleTranscript == nil {
                    summary.titleTranscript = text
                }
            } else if lower.contains("nutrition facts") {
                if summary.titleTranscript == nil {
                    summary.titleTranscript = text
                }
            }

            // Footnote detection
            if lower.contains("daily value") && (lower.contains("tells you how much") || lower.contains("2,000 calories") || lower.contains("1,000 calories") || lower.contains("based on a"))
                || lower.contains("not a significant source of")
                || lower.contains("daily value not established")
                || lower.contains("% dv = % daily value") {
                if !summary.footnoteTranscripts.contains(text) {
                    summary.footnoteTranscripts.append(text)
                }
            }

            // Column headers (Dual-column, Aggregate, Tabular, Supplement)
            if lower.contains("amount per serving")
                || lower.contains("amount/serving")
                || lower.contains("% daily value")
                || lower.contains("% dv")
                || lower.contains("per serving")
                || lower.contains("per container")
                || lower.contains("per unit")
                || lower.contains("per day")
                || lower.contains("each tablet")
                || lower.contains("each capsule")
                || lower.contains("each packet")
                || lower.contains("dry mix")
                || lower.contains("baked")
                || lower.contains("prepared") {
                if !summary.columnHeaderTranscripts.contains(text) {
                    summary.columnHeaderTranscripts.append(text)
                }
            }

            // Servings per container recovery (including multi-line "about 3 servings" + "per container" in Topology K)
            if lower.contains("servings per container")
                || lower.contains("serving per container")
                || lower.contains("servings:")
                || lower.contains("servings ") {
                if summary.servingsPerContainerTranscript == nil {
                    if lower.contains("servings") && !lower.contains("container") && !lower.contains("servings:") {
                        // Look ahead one line for "per container" (e.g., Topology K)
                        if index + 1 < regionalLines.count {
                            let nextText = regionalLines[index + 1].transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                            if nextText.lowercased().contains("per container") {
                                summary.servingsPerContainerTranscript = "\(text) \(nextText)"
                            }
                        }
                    } else {
                        summary.servingsPerContainerTranscript = text
                    }
                }
            }

            // Serving size recovery (including split cell or two-line "Serving size" -> "2/3 cup (55g)")
            if lower.contains("serving size") || lower.contains("serv. size") {
                let candidateServing = assembleServingSizeTranscript(
                    anchorIndex: index,
                    regionalLines: regionalLines,
                    primaryTable: primaryTable
                )
                if summary.servingSizeTranscript == nil || candidateServing.count > (summary.servingSizeTranscript?.count ?? 0) {
                    summary.servingSizeTranscript = candidateServing
                }
            }
        }

        // 2. Calorie Recovery using Part 1.6 Bounding-Box Height Hierarchy and Spatial Adjacency.
        recoverCalories(
            into: &summary,
            regionalLines: regionalLines,
            primaryTable: primaryTable,
            medianBodyHeight: medianBodyHeight
        )

        return summary
    }

    private static func assembleServingSizeTranscript(
        anchorIndex: Int,
        regionalLines: [ScannedTextLine],
        primaryTable: ScannedTableGrid?
    ) -> String {
        let anchorLine = regionalLines[anchorIndex]
        let anchorText = anchorLine.transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        // First check if a table row contains "Serving size" in one cell and the value in the adjacent cell(s)
        // (e.g. Topology B: `<td>Serving size</td><td>2/3 cup (55g)</td>` or Topology E: `<td>Serving size</td>` + `<td>1 box</td><td>(35g)</td>`).
        if let table = primaryTable {
            for row in table.rows {
                let rowTexts = row.map { $0.transcript.trimmingCharacters(in: .whitespacesAndNewlines) }
                let joinedRow = rowTexts.joined(separator: " ")
                let expandedRow = FDALexicalNormalizer.expandAuthorizedAbbreviations(joinedRow).lowercased()
                if expandedRow.contains("serving size") {
                    // Check if the serving size cell itself has multiple lines (e.g., Topology A: "10 servings per container\nServing size\n2 slices (56g)")
                    for cell in row {
                        let cellLines = cell.transcript
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        if let ssIdx = cellLines.firstIndex(where: {
                            FDALexicalNormalizer.expandAuthorizedAbbreviations($0).lowercased().contains("serving size")
                        }) {
                            var parts = [cellLines[ssIdx]]
                            if ssIdx + 1 < cellLines.count {
                                parts.append(cellLines[ssIdx + 1])
                            }
                            let combinedCell = parts.joined(separator: " ")
                            if containsNumericDigit(combinedCell) {
                                return combinedCell
                            }
                        }
                    }

                    // If the row cells together have digits (e.g. ["Serving size", "2/3 cup (55g)"]), combine non-nutrient cells on that row.
                    let nonNutrientRowParts = row.compactMap { cell -> String? in
                        let clean = cell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else { return nil }
                        if let nutrient = FDALexicalNormalizer.resolveNutrientID(from: clean), nutrient != .calories {
                            return nil
                        }
                        return clean
                    }
                    let combinedRow = nonNutrientRowParts.joined(separator: " ")
                    if containsNumericDigit(combinedRow) {
                        return combinedRow
                    }

                    // Otherwise check if the immediately following row in the same left sidebar columns holds the serving quantity (e.g., Topology I & K: row N = "Serving size", row N+1 = "1 cup (255g)" or "1/3 cup (56g)").
                    if let servingCell = row.first(where: {
                        FDALexicalNormalizer.expandAuthorizedAbbreviations($0.transcript).lowercased().contains("serving size")
                    }) {
                        let nextRowIndex = servingCell.rowRange.upperBound + 1
                        if let nextCell = table.cell(row: nextRowIndex, column: servingCell.columnRange.lowerBound) {
                            let nextClean = nextCell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                            if containsNumericDigit(nextClean) && FDALexicalNormalizer.resolveNutrientID(from: nextClean) == nil {
                                return "\(anchorText) \(nextClean)"
                            }
                        }
                        // Also check if a rowspan cell above/beside holds household + metric (e.g. Topology E: row 0 has "1 box" and "(35g)" with rowspan=2 while row 1 has "Serving size").
                        let prevRowIndex = servingCell.rowRange.lowerBound - 1
                        if prevRowIndex >= 0 {
                            let spannedNeighbors = table.allUniqueCells.filter {
                                $0.rowRange.contains(servingCell.rowRange.lowerBound)
                                    && $0.columnRange.lowerBound > servingCell.columnRange.upperBound
                            }
                            if !spannedNeighbors.isEmpty {
                                // Take household measure cell + first product metric weight cell
                                let neighborTexts = spannedNeighbors.prefix(2).map {
                                    $0.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                let combinedSpanned = ([anchorText] + neighborTexts).joined(separator: " ")
                                if containsNumericDigit(combinedSpanned) {
                                    return combinedSpanned
                                }
                            }
                        }
                    }
                }
            }
        }

        // If the anchor line already contains numbers (e.g., "Serving size 2/3 cup (55g)" or "Serv. size: 1 mint (2g)"), return it.
        if containsNumericDigit(anchorText) {
            return anchorText
        }

        // Otherwise check horizontally aligned or immediately following regional lines.
        var parts: [String] = [anchorText]
        for candidate in regionalLines.dropFirst(anchorIndex + 1).prefix(3) {
            let text = candidate.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = text.lowercased()
            if lower.contains("amount per serving")
                || lower.contains("amount/serving")
                || lower.contains("calories")
                || lower.contains("servings per container")
                || FDALexicalNormalizer.resolveNutrientID(from: text) != nil {
                break
            }
            let sameHorizontalBand = abs(candidate.midY - anchorLine.midY) <= max(0.025, anchorLine.height * 1.2)
            let immediatelyBelowInSameColumn = (candidate.minY >= anchorLine.minY)
                && (candidate.minY - anchorLine.maxY) <= max(0.035, anchorLine.height * 1.8)
                && abs(candidate.minX - anchorLine.minX) <= 0.28
            if sameHorizontalBand || immediatelyBelowInSameColumn {
                parts.append(text)
                if containsNumericDigit(text) && (text.contains("g)") || text.contains("ml)") || text.contains("g") || text.contains("ml")) {
                    break
                }
            }
        }

        return parts.joined(separator: " ")
    }

    /// Recovers the `"Calories"` declaration and numeric calorie value using:
    /// 1. Table cell span relationships (e.g. `rowspan="2"` numeric cell beside `"Amount per serving"` and `"Calories"` in `Topologies B, C, D, E, J`, or `"Calories"` above `"per serving"` beside `rowspan="2"` `170` in `Topologies A, I, K`).
    /// 2. Inline `"Calories 230"` / `"Calories 5"` text.
    /// 3. `Part 1.6` bounding-box height hierarchy (`height >= 1.35 * medianBodyHeight`) for detached large-font numeric calorie blocks.
    private static func recoverCalories(
        into summary: inout HeaderRecoverySummary,
        regionalLines: [ScannedTextLine],
        primaryTable: ScannedTableGrid?,
        medianBodyHeight: CGFloat
    ) {
        // 1. Check table cells first for explicit "Calories" row or spanned numeric cell.
        if let table = primaryTable {
            for cell in table.allUniqueCells {
                let clean = cell.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                let lower = clean.lowercased()
                guard lower.contains("calories") && !lower.contains("calories from") && !lower.contains("2,000 calories") && !lower.contains("1,000 calories") && !lower.contains("calories per gram") else {
                    continue
                }

                // Case 1A: Inline "Calories 170" in the same cell.
                if let inlineVal = extractStandaloneCalorieInt(from: clean) {
                    summary.caloriesTranscript = "Calories \(inlineVal)"
                    summary.inferredCaloriesValue = inlineVal
                    return
                }

                // Case 1B: Look for cells whose `rowRange` overlaps `cell.rowRange` (or `cell.rowRange.lowerBound + 1` in Topology I where "220" is directly below "Calories").
                let candidateNeighborCells = table.allUniqueCells.filter { neighbor in
                    let overlapsRow = neighbor.rowRange.overlaps(cell.rowRange)
                        || neighbor.rowRange.lowerBound == cell.rowRange.upperBound + 1
                    return overlapsRow && neighbor != cell
                }
                .sorted { lhs, rhs in
                    if lhs.rowRange.overlaps(cell.rowRange) != rhs.rowRange.overlaps(cell.rowRange) {
                        return lhs.rowRange.overlaps(cell.rowRange)
                    }
                    return lhs.columnRange.lowerBound < rhs.columnRange.lowerBound
                }

                for neighbor in candidateNeighborCells {
                    let neighborClean = neighbor.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    if let calVal = extractPureCalorieInt(from: neighborClean) {
                        summary.caloriesTranscript = "Calories \(calVal)"
                        summary.inferredCaloriesValue = calVal
                        return
                    }
                }
            }
        }

        // 2. Inspect regional lines for inline "Calories X" or spatially adjacent large-font numeric blocks (Part 1.6).
        for (idx, line) in regionalLines.enumerated() {
            let text = line.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = text.lowercased()
            guard lower.contains("calories")
                    && !lower.contains("calories from")
                    && !lower.contains("2,000 calories")
                    && !lower.contains("1,000 calories")
                    && !lower.contains("calories per gram") else {
                continue
            }

            if let inlineVal = extractStandaloneCalorieInt(from: text) {
                summary.caloriesTranscript = "Calories \(inlineVal)"
                summary.inferredCaloriesValue = inlineVal
                return
            }

            // Look for a pure integer token nearby (same Y-band or immediately below/above), prioritizing Part 1.6 largest bounding-box height.
            let nearbyNumericCandidates = regionalLines.enumerated().compactMap { (candIdx, candLine) -> (value: Int, score: CGFloat)? in
                guard candIdx != idx else { return nil }
                guard let val = extractPureCalorieInt(from: candLine.transcript) else { return nil }
                let dy = abs(candLine.midY - line.midY)
                let dx = abs(candLine.midX - line.midX)
                guard dy <= 0.12 && dx <= 0.65 else { return nil }

                // Part 1.6: numeric Calories value has the largest bounding-box height (>= 22pt vs 8pt body).
                let heightRatio = candLine.height / max(0.005, medianBodyHeight)
                let proximityScore = max(0.01, 1.0 - (dy * 4.0 + dx * 0.5))
                let totalScore = proximityScore * max(1.0, heightRatio)
                return (val, totalScore)
            }
            .sorted { $0.score > $1.score }

            if let best = nearbyNumericCandidates.first {
                summary.caloriesTranscript = "Calories \(best.value)"
                summary.inferredCaloriesValue = best.value
                return
            }
        }
    }

    // MARK: - Step 6: 12-Archetype (A–L) & Supplement Topology Resolution

    private static func resolveTopology(
        primaryTable: ScannedTableGrid?,
        supplementaryTables: [ScannedTableGrid],
        allLines: [String],
        headerRecovery: HeaderRecoverySummary,
        bodyBlocks: [ScannedTextBlock]
    ) -> FDALabelTopology {
        let joinedLower = allLines.joined(separator: "\n").lowercased()

        // 1. Supplement Facts (21 CFR § 101.36 — Part 3)
        if headerRecovery.isSupplementHeader
            || joinedLower.contains("supplement facts")
            || joinedLower.contains("proprietary blend")
            || joinedLower.contains("daily value not established")
            || joinedLower.contains("other dietary ingredients") {
            return .supplementFacts
        }

        // 2. Linear Display for Small Packages (Topology L — § 101.9(j)(13)(ii)(A)(2))
        if isLinearStringDisplay(primaryTable: primaryTable, allLines: allLines, bodyBlocks: bodyBlocks) {
            return .linearString
        }

        // 3. Inspect 2D Table Grid structure when `primaryTable` is available.
        if let table = primaryTable {
            let effectiveColCount = table.columnCount + supplementaryTables.reduce(0) { $0 + $1.columnCount }

            // Check if the table places two macronutrient stacks side-by-side horizontally (Topologies A, I, K).
            let hasParallelMacroStacks = detectsParallelHorizontalMacroStacks(in: table, supplementaryTables: supplementaryTables)
            let hasRepeatedAmountHeaders = detectsRepeatedColumnHeaders(in: table)
            let hasDualPerServingAndContainerHeaders = joinedLower.contains("per serving")
                && (joinedLower.contains("per container") || joinedLower.contains("per package"))

            if hasParallelMacroStacks || hasRepeatedAmountHeaders {
                // Topology I: Tabular Dual-Column Display (§ 101.9(e)(6)(ii))
                if hasDualPerServingAndContainerHeaders || effectiveColCount >= 8 {
                    return .tabularDualColumn
                }

                // Disambiguate Topology K (Small-Package Tabular) vs Topology A (Standard Tabular):
                if usesSmallPackageTabularConventions(allLines: allLines, table: table) {
                    return .smallPackageTabular
                }
                return .tabularHorizontal
            }

            // Multi-Column Vertical Topologies (Topologies E, F, G, H)
            if table.columnCount >= 4 {
                if joinedLower.contains("per container") || joinedLower.contains("per package") {
                    return .dualColumnPerContainer
                }
                if joinedLower.contains("per unit")
                    || joinedLower.contains("per bar")
                    || joinedLower.contains("per bottle")
                    || joinedLower.contains("per cookie")
                    || joinedLower.contains("per slice")
                    || joinedLower.contains("per piece") {
                    return .dualColumnPerUnit
                }
                if joinedLower.contains("dry mix")
                    || joinedLower.contains("baked")
                    || joinedLower.contains("prepared")
                    || joinedLower.contains("as packaged")
                    || joinedLower.contains("with milk")
                    || joinedLower.contains("unpopped")
                    || joinedLower.contains("popped") {
                    return .dualColumnSameFood
                }
                if detectsAggregateVarietyHeader(in: table) || table.columnCount >= 6 {
                    return .aggregateVariety
                }
            }

            // Topology J: Simplified Display (§ 101.9(f)(4))
            if joinedLower.contains("not a significant source of") && isMissingSimplifiedCoreNutrients(in: allLines) {
                return .simplified
            }

            // Topology D: Standard Vertical with Side-by-Side Micronutrients (§ 101.9(d)(8))
            if detectsSideBySideMicronutrients(in: table, allLines: allLines) {
                return .sideBySideMicronutrients
            }
        }

        // 4. Delegate to Phase 1's lexical topology classifier as final check.
        let lexicalTopology = FDALexicalNormalizer.classifyTopology(
            fromLines: allLines,
            tableColumnCount: primaryTable?.columnCount ?? 2
        )
        return lexicalTopology
    }

    private static func isLinearStringDisplay(
        primaryTable: ScannedTableGrid?,
        allLines: [String],
        bodyBlocks: [ScannedTextBlock]
    ) -> Bool {
        let combined = allLines.joined(separator: " ")
        let lower = combined.lowercased()

        // Count how many `(X% dv)` or `, total fat` / `, sat. fat` / `, cholest.` / `, sodium` clauses appear in a single continuous paragraph.
        let commaDelimitedNutrientCount = [
            "calories", "total fat", "sat. fat", "saturated fat", "trans fat",
            "cholest", "sodium", "total carb", "fiber", "total sugars", "protein"
        ].filter { lower.contains($0) }.count

        let hasInlineDVParentheses = lower.contains("% dv)") || lower.contains("% daily value)")
        if primaryTable == nil && commaDelimitedNutrientCount >= 4 && (hasInlineDVParentheses || combined.filter({ $0 == "," }).count >= 5) {
            return true
        }

        // Also handle the case where Vision wrapped a Linear Display box into a 1-row or 2-row table (as in Archetype L).
        if let table = primaryTable, table.rowCount <= 3 {
            for cell in table.allUniqueCells {
                let cellLower = cell.transcript.lowercased()
                let commaCount = cell.transcript.filter { $0 == "," }.count
                if commaCount >= 5 && (cellLower.contains("% dv)") || (cellLower.contains("total fat") && cellLower.contains("sodium") && cellLower.contains("protein"))) {
                    return true
                }
            }
        }

        return false
    }

    private static func detectsParallelHorizontalMacroStacks(
        in table: ScannedTableGrid,
        supplementaryTables: [ScannedTableGrid]
    ) -> Bool {
        // In Topologies A, I, K, a single horizontal row contains a Fat/Cholesterol/Sodium family nutrient on the left
        // AND a Carbohydrate/Fiber/Sugars/Protein family nutrient on the right.
        let leftStackMacros: Set<CanonicalNutrientID> = [.totalFat, .saturatedFat, .transFat, .cholesterol, .sodium]
        let rightStackMacros: Set<CanonicalNutrientID> = [.totalCarbohydrate, .dietaryFiber, .totalSugars, .addedSugars, .protein]

        for row in table.rows {
            var hasLeftMacro = false
            var hasRightMacro = false
            for cell in row {
                let firstLine = cell.transcript.components(separatedBy: .newlines).first ?? cell.transcript
                if let nutrient = FDALexicalNormalizer.resolveNutrientID(from: firstLine) {
                    if leftStackMacros.contains(nutrient) {
                        hasLeftMacro = true
                    } else if rightStackMacros.contains(nutrient) {
                        hasRightMacro = true
                    }
                }
            }
            if hasLeftMacro && hasRightMacro {
                return true
            }
        }

        // Also check if supplementaryTable holds the right macro stack alongside primaryTable's left macro stack.
        if !supplementaryTables.isEmpty {
            let primaryNutrients = Set(table.allUniqueCells.compactMap { FDALexicalNormalizer.resolveNutrientID(from: $0.transcript) })
            let suppNutrients = Set(supplementaryTables.flatMap(\.allUniqueCells).compactMap { FDALexicalNormalizer.resolveNutrientID(from: $0.transcript) })
            if !primaryNutrients.isDisjoint(with: leftStackMacros) && !suppNutrients.isDisjoint(with: rightStackMacros) {
                return true
            }
        }

        return false
    }

    private static func detectsRepeatedColumnHeaders(in table: ScannedTableGrid) -> Bool {
        for row in table.rows.prefix(3) {
            var amountHeaderCount = 0
            var dvHeaderCount = 0
            for cell in row {
                let lower = cell.transcript.lowercased()
                if lower.contains("amount/serving") || lower.contains("amount per serving") {
                    amountHeaderCount += 1
                }
                if lower.contains("% daily value") || lower.contains("% dv") {
                    dvHeaderCount += 1
                }
            }
            if amountHeaderCount >= 2 || (amountHeaderCount >= 1 && dvHeaderCount >= 2 && row.count >= 4) {
                return true
            }
        }
        return false
    }

    private static func usesSmallPackageTabularConventions(
        allLines: [String],
        table: ScannedTableGrid
    ) -> Bool {
        let joined = allLines.joined(separator: " ")
        let lower = joined.lowercased()

        // Archetype K indicators:
        // 1. Uses "% DV" column header without "*The % Daily Value (DV) tells you..." footnote.
        let hasAbbreviatedDVHeader = table.rows.prefix(2).flatMap { $0 }.contains {
            let cellLower = $0.transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return cellLower == "% dv" || cellLower == "% dv*"
        }
        let hasAbbreviatedMacroNames = lower.contains("sat. fat")
            || lower.contains("cholest.")
            || lower.contains("total carb.")
            || lower.contains("incl.")
        let hasLongFootnote = lower.contains("tells you how much a nutrient")

        if hasAbbreviatedDVHeader && (hasAbbreviatedMacroNames || !hasLongFootnote) {
            return true
        }
        return false
    }

    private static func detectsAggregateVarietyHeader(in table: ScannedTableGrid) -> Bool {
        guard let firstRow = table.rows.first else { return false }
        let nonTitleHeaders = firstRow.filter { cell in
            let lower = cell.transcript.lowercased()
            return !lower.contains("nutrition facts") && !lower.isEmpty
        }
        return nonTitleHeaders.count >= 2 && table.columnCount >= 6
    }

    private static func isMissingSimplifiedCoreNutrients(in allLines: [String]) -> Bool {
        var presentNutrients = Set<CanonicalNutrientID>()
        for line in allLines {
            if let id = FDALexicalNormalizer.resolveNutrientID(from: line) {
                presentNutrients.insert(id)
            }
        }
        let standardNonSimplified: [CanonicalNutrientID] = [
            .cholesterol, .dietaryFiber, .totalSugars, .addedSugars,
            .vitaminD, .calcium, .iron, .potassium
        ]
        let missingCount = standardNonSimplified.filter { !presentNutrients.contains($0) }.count
        return missingCount >= 4
    }

    private static func detectsSideBySideMicronutrients(
        in table: ScannedTableGrid,
        allLines: [String]
    ) -> Bool {
        // Archetype D: A row below Protein has 2 cells, and BOTH cells resolve to distinct RDI micronutrients (e.g. Cell 0 = "Vit. D 2mcg 10%", Cell 1 = "Calcium 260mg 20%").
        for row in table.rows where row.count >= 2 {
            let resolvedMicronutrients = row.compactMap { cell -> CanonicalNutrientID? in
                guard !cell.transcript.contains("•") else { return nil }
                guard let id = FDALexicalNormalizer.resolveNutrientID(from: cell.transcript),
                      id.isMicronutrientRDI else {
                    return nil
                }
                return id
            }
            if Set(resolvedMicronutrients).count >= 2 {
                return true
            }
        }
        return false
    }

    // MARK: - Line Ordering & Lexical Helpers

    private static func buildOrderedLabelLines(
        primaryTable: ScannedTableGrid?,
        supplementaryTables: [ScannedTableGrid],
        headerBlocks: [ScannedTextBlock],
        sidebarBlocks: [ScannedTextBlock],
        bodyBlocks: [ScannedTextBlock],
        headerRecovery: HeaderRecoverySummary
    ) -> [String] {
        var lines: [String] = []

        if let title = headerRecovery.titleTranscript {
            lines.append(title)
        }
        if let container = headerRecovery.servingsPerContainerTranscript {
            lines.append(container)
        }
        if let serving = headerRecovery.servingSizeTranscript {
            lines.append(serving)
        }
        if let calories = headerRecovery.caloriesTranscript {
            lines.append(calories)
        }

        for block in headerBlocks + sidebarBlocks {
            for subline in block.transcript.components(separatedBy: .newlines) {
                let clean = subline.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty && !lines.contains(clean) {
                    lines.append(clean)
                }
            }
        }

        for table in ([primaryTable].compactMap { $0 }) + supplementaryTables {
            for row in table.rows {
                let rowString = row
                    .map { $0.transcript.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                if !rowString.isEmpty && !lines.contains(rowString) {
                    lines.append(rowString)
                }
            }
        }

        for block in bodyBlocks {
            for subline in block.transcript.components(separatedBy: .newlines) {
                let clean = subline.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty && !lines.contains(clean) {
                    lines.append(clean)
                }
            }
        }

        return lines
    }

    private static func computeUnionBoundingBox(
        anchorBox: CGRect,
        headerBlocks: [ScannedTextBlock],
        sidebarBlocks: [ScannedTextBlock],
        bodyBlocks: [ScannedTextBlock]
    ) -> CGRect {
        let allBoxes = [anchorBox]
            + headerBlocks.map(\.boundingBox)
            + sidebarBlocks.map(\.boundingBox)
            + bodyBlocks.map(\.boundingBox)
        guard let first = allBoxes.first else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        return allBoxes.dropFirst().reduce(first) { $0.union($1) }
    }

    private static func isExternalIngredientBlock(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("ingredients:")
            || trimmed.hasPrefix("ingredients :")
            || trimmed.hasPrefix("other ingredients:")
            || trimmed.hasPrefix("other ingredients :")
            || trimmed.hasPrefix("contains:")
    }

    private static func isNutritionRelevantBlock(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("nutrition facts")
            || lower.contains("supplement facts")
            || lower.contains("serving size")
            || lower.contains("serv. size")
            || lower.contains("servings per container")
            || lower.contains("calories")
            || lower.contains("daily value")
            || lower.contains("% dv")
            || lower.contains("not a significant source") {
            return true
        }
        for line in text.components(separatedBy: .newlines) {
            if FDALexicalNormalizer.resolveNutrientID(from: line) != nil {
                return true
            }
        }
        return false
    }

    private static func isHeaderOrServingOnlyBlock(_ text: String) -> Bool {
        let lower = text.lowercased()
        let hasHeaderToken = lower.contains("nutrition facts")
            || lower.contains("supplement facts")
            || lower.contains("serving size")
            || lower.contains("serv. size")
            || lower.contains("servings per container")
        guard hasHeaderToken else { return false }

        // If it also contains multiple nutrient rows (like a Linear Display paragraph), it's a body block.
        let nutrientHits = text.components(separatedBy: .newlines).compactMap {
            FDALexicalNormalizer.resolveNutrientID(from: $0)
        }.filter { $0 != .calories }
        return nutrientHits.isEmpty && !lower.contains("total fat")
    }

    private static func normalizeWhitespace(_ text: String) -> String {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }

    private static func containsNumericDigit(_ text: String) -> Bool {
        text.contains { $0.isNumber || FDALexicalNormalizer.unicodeFractionMap[$0] != nil }
    }

    private static func extractStandaloneCalorieInt(from text: String) -> Int? {
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
        guard !trimmed.isEmpty else { return nil }
        // Must be a pure integer (e.g., "170", "230", "90", "0") without unit suffixes like "g", "mg", "mcg", "%".
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
}
