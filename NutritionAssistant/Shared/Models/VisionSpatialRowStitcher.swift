//
//  VisionSpatialRowStitcher.swift
//  NutritionAssistant
//
//  Milestone 4.4: Curved-Surface Y-Axis Fallback & Linear Parser
//  Provides skew-compensated Y-axis row stitching for cylindrical/curved packages
//  (cans, bottles, protein tubs, flexible pouches), vertical sub-column de-interleaving
//  for Topology D (Side-by-Side Micronutrients) and Part 3.4 (Right-Hand Supplement
//  Continuation Panels), 1D minX indentation clustering (Level 0, Level 1, Level 2),
//  and continuous paragraph unpacking for Topology L (LinearString).
//

import CoreGraphics
import Foundation

enum VisionSpatialRowStitcher {

    // MARK: - Public API

    /// Stitches `ScannedDocumentSnapshot` text blocks (and any fractured table cells) into an ordered `[RawExtractedRow]`
    /// sequence using skew-compensated Y-axis projection, vertical column split de-interleaving, and `minX` indentation clustering.
    static func stitchRows(
        from snapshot: ScannedDocumentSnapshot,
        classifiedLabel: FDAClassifiedLabel
    ) -> [RawExtractedRow] {
        // 1. If the label is Topology L (Linear Display for Small Packages), unpack continuous comma-delimited text first.
        if classifiedLabel.topology == .linearString {
            let linearInput = classifiedLabel.allLabelLines.joined(separator: " ")
            let linearRows = parseLinearStringRows(
                from: linearInput,
                isSupplement: classifiedLabel.isSupplement
            )
            if !linearRows.isEmpty {
                return ensureCaloriesRow(in: linearRows, inferredCaloriesValue: classifiedLabel.inferredCaloriesValue)
            }
        }

        // 2. Gather candidate blocks from header, sidebar, body, and any fractured table cells.
        var candidateBlocks: [ScannedTextBlock] = []
        candidateBlocks.append(contentsOf: classifiedLabel.attachedHeaderBlocks)
        candidateBlocks.append(contentsOf: classifiedLabel.attachedSidebarBlocks)
        candidateBlocks.append(contentsOf: classifiedLabel.attachedBodyBlocks)

        if candidateBlocks.isEmpty {
            candidateBlocks.append(contentsOf: snapshot.textBlocks)
        }

        // Also include cells from primary/supplementary tables as spatial blocks so fractured curved-surface tables
        // seamlessly participate in Y-axis row stitching.
        let allTables = ([classifiedLabel.primaryTable].compactMap { $0 }) + classifiedLabel.supplementaryTables
        for table in allTables {
            for cell in table.allUniqueCells {
                let text = cell.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                candidateBlocks.append(
                    ScannedTextBlock(
                        transcript: text,
                        boundingBox: cell.boundingBox,
                        isTitle: false,
                        lines: cell.lines
                    )
                )
            }
        }

        let stitched = stitchRows(
            from: candidateBlocks,
            topology: classifiedLabel.topology,
            isSupplement: classifiedLabel.isSupplement,
            inferredCaloriesValue: classifiedLabel.inferredCaloriesValue
        )
        return stitched
    }

    /// Stitches an array of `ScannedTextBlock` items into `[RawExtractedRow]` records.
    static func stitchRows(
        from textBlocks: [ScannedTextBlock],
        topology: FDALabelTopology = .standardVertical,
        isSupplement: Bool = false,
        inferredCaloriesValue: Int? = nil
    ) -> [RawExtractedRow] {
        guard !textBlocks.isEmpty else {
            return ensureCaloriesRow(in: [], inferredCaloriesValue: inferredCaloriesValue)
        }

        // Check if any block is a continuous Topology L linear paragraph.
        if topology == .linearString || containsLinearDisplayParagraph(in: textBlocks) {
            let combinedText = textBlocks.map(\.transcript).joined(separator: " ")
            let linearRows = parseLinearStringRows(from: combinedText, isSupplement: isSupplement)
            if linearRows.count >= 3 {
                return ensureCaloriesRow(in: linearRows, inferredCaloriesValue: inferredCaloriesValue)
            }
        }

        // 1. Decompose blocks into atomic lines/tokens and extract any bullet-delimited (`•`) micronutrient lines.
        let (rawAtoms, bulletRows) = extractSpatialAtomsAndBulletRows(
            from: textBlocks,
            isSupplement: isSupplement
        )

        guard !rawAtoms.isEmpty else {
            return ensureCaloriesRow(in: bulletRows, inferredCaloriesValue: inferredCaloriesValue)
        }

        // 2. Estimate label tilt/skew slope (dy / dx) from word baselines and horizontal header pairs.
        let skewSlope = estimateLabelSkewSlope(from: rawAtoms, textBlocks: textBlocks)
        let referenceX = rawAtoms.map(\.minX).min() ?? 0.0

        let skewAdjustedAtoms: [SpatialAtom] = rawAtoms.map { atom in
            var updated = atom
            let projectedMidY = atom.boundingBox.midY - skewSlope * (atom.boundingBox.midX - referenceX)
            updated.skewCorrectedMidY = projectedMidY
            updated.skewCorrectedMinY = projectedMidY - (atom.boundingBox.height * 0.5)
            updated.skewCorrectedMaxY = projectedMidY + (atom.boundingBox.height * 0.5)
            return updated
        }

        // 3. De-interleave vertical column splits (Part 3.4 Right-Hand Supplement Continuation Panels,
        //    Tabular A/I/K stacks, and Topology D Side-by-Side Micronutrients).
        let columnZones = deinterleaveVerticalColumnZones(
            atoms: skewAdjustedAtoms,
            topology: topology,
            isSupplement: isSupplement
        )

        // 4. Within each vertical column zone, cluster atoms into skew-compensated Y-axis bands,
        //    cluster `minX` coordinates for Level 0/1/2 indentation, and assemble `RawExtractedRow` records.
        var allStitchedRows: [RawExtractedRow] = []
        for zone in columnZones {
            let zoneRows = stitchSingleColumnZone(
                atoms: zone.atoms,
                isSupplement: isSupplement
            )
            allStitchedRows.append(contentsOf: zoneRows)
        }

        allStitchedRows.append(contentsOf: bulletRows)
        let deduplicated = deduplicateRows(allStitchedRows)
        return ensureCaloriesRow(in: deduplicated, inferredCaloriesValue: inferredCaloriesValue)
    }

    // MARK: - Topology L (LinearString) Continuous Paragraph Unpacker

    /// Splits continuous comma/parenthesis-delimited paragraph text (`Topology L` — `21 CFR § 101.9(j)(13)(ii)(A)(2)`)
    /// into ordered `[RawExtractedRow]` records while preserving nested `(Incl. Xg Added Sugars, Y% DV)` clauses.
    static func parseLinearStringRows(
        from text: String,
        isSupplement: Bool = false
    ) -> [RawExtractedRow] {
        let normalizedText = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedText.isEmpty else { return [] }

        var rows: [RawExtractedRow] = []

        // First split into top-level comma/semicolon clauses outside parentheses.
        let clauses = splitTopLevelClauses(normalizedText)

        for (index, rawClause) in clauses.enumerated() {
            var clause = rawClause.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
            guard !clause.isEmpty else { continue }

            // Strip leading "Amount per serving:" or "Per serving:" prefix if attached to the first nutrient clause.
            clause = stripLeadingLinearPrefix(clause)
            guard !clause.isEmpty else { continue }

            // Check if this clause has a nested Added Sugars parenthetical (e.g., "Total Sugars 2g (Incl. 2g Added Sugars, 4% DV)").
            let (primaryClause, nestedAddedSugarsClause) = extractNestedAddedSugarsClause(from: clause)

            if let nutrient = FDALexicalNormalizer.resolveNutrientID(from: primaryClause) {
                let (labelPart, weightPart, dvPart) = decomposeLinearClause(primaryClause, for: nutrient)
                var cellTokens: [String] = [labelPart]
                if !weightPart.isEmpty && !labelPart.lowercased().contains(weightPart.lowercased()) {
                    cellTokens.append(weightPart)
                }
                if !dvPart.isEmpty && !labelPart.lowercased().contains(dvPart.lowercased()) {
                    cellTokens.append(dvPart)
                }

                rows.append(
                    RawExtractedRow(
                        nutrientLabelTranscript: labelPart,
                        weightTranscript: weightPart,
                        percentDVTranscript: dvPart,
                        rawCells: cellTokens,
                        minX: 0.05,
                        midY: CGFloat(index) * 0.03,
                        boundingBox: CGRect(x: 0.05, y: CGFloat(index) * 0.03, width: 0.90, height: 0.025),
                        indentationLevel: nutrient.indentationLevel,
                        columnIndex: 0
                    )
                )
            }

            if let nestedSugars = nestedAddedSugarsClause,
               let addedId = FDALexicalNormalizer.resolveNutrientID(from: nestedSugars) {
                let (labelPart, weightPart, dvPart) = decomposeLinearClause(nestedSugars, for: addedId)
                var cellTokens: [String] = [labelPart]
                if !weightPart.isEmpty && !labelPart.lowercased().contains(weightPart.lowercased()) {
                    cellTokens.append(weightPart)
                }
                if !dvPart.isEmpty && !labelPart.lowercased().contains(dvPart.lowercased()) {
                    cellTokens.append(dvPart)
                }

                rows.append(
                    RawExtractedRow(
                        nutrientLabelTranscript: labelPart,
                        weightTranscript: weightPart,
                        percentDVTranscript: dvPart,
                        rawCells: cellTokens,
                        minX: 0.13,
                        midY: CGFloat(index) * 0.03 + 0.01,
                        boundingBox: CGRect(x: 0.13, y: CGFloat(index) * 0.03 + 0.01, width: 0.82, height: 0.025),
                        indentationLevel: .level2,
                        columnIndex: 0
                    )
                )
            }
        }

        // If clause splitting found nothing, fallback to Phase 1's `parseLinearDisplayPanel` and map back to `RawExtractedRow`.
        if rows.isEmpty {
            let parsed = FDALexicalNormalizer.parseLinearDisplayPanel(normalizedText, isSupplement: isSupplement)
            for (idx, parsedRow) in parsed.rows.enumerated() {
                let weightStr = formatDeclaredAmountForCell(parsedRow.amount, nutrient: parsedRow.nutrient)
                let dvStr = formatDeclaredPercentDVForCell(parsedRow.percentDV)
                rows.append(
                    RawExtractedRow(
                        nutrientLabelTranscript: parsedRow.rawName,
                        weightTranscript: weightStr,
                        percentDVTranscript: dvStr,
                        rawCells: [parsedRow.rawName, weightStr, dvStr].filter { !$0.isEmpty },
                        minX: 0.05,
                        midY: CGFloat(idx) * 0.03,
                        boundingBox: CGRect(x: 0.05, y: CGFloat(idx) * 0.03, width: 0.90, height: 0.025),
                        indentationLevel: parsedRow.indentationLevel,
                        columnIndex: parsedRow.columnIndex
                    )
                )
            }
        }

        return deduplicateRows(rows)
    }

    // MARK: - Internal Spatial Atom Model

    private struct SpatialAtom: Sendable, Equatable {
        let transcript: String
        let boundingBox: CGRect
        let words: [ScannedWordToken]
        var skewCorrectedMidY: CGFloat
        var skewCorrectedMinY: CGFloat
        var skewCorrectedMaxY: CGFloat

        var minX: CGFloat { boundingBox.minX }
        var midX: CGFloat { boundingBox.midX }
        var maxX: CGFloat { boundingBox.maxX }
        var width: CGFloat { boundingBox.width }
        var height: CGFloat { boundingBox.height }

        init(transcript: String, boundingBox: CGRect, words: [ScannedWordToken] = []) {
            self.transcript = transcript
            self.boundingBox = boundingBox
            self.words = words
            self.skewCorrectedMidY = boundingBox.midY
            self.skewCorrectedMinY = boundingBox.minY
            self.skewCorrectedMaxY = boundingBox.maxY
        }
    }

    private struct VerticalColumnZone {
        let minX: CGFloat
        let maxX: CGFloat
        let atoms: [SpatialAtom]
    }

    // MARK: - Step 1: Atomic Decomposition & Bullet Extraction

    private static func extractSpatialAtomsAndBulletRows(
        from blocks: [ScannedTextBlock],
        isSupplement: Bool
    ) -> (atoms: [SpatialAtom], bulletRows: [RawExtractedRow]) {
        var atoms: [SpatialAtom] = []
        var bulletRows: [RawExtractedRow] = []

        for block in blocks {
            if FDALexicalNormalizer.isMandatoryBoxedWarning(block.transcript)
                || FDALexicalNormalizer.isDecoyComparativeString(block.transcript)
                || isFootnoteOrHeaderDiscard(block.transcript) {
                continue
            }

            if !block.lines.isEmpty {
                for line in block.lines {
                    let clean = FDALexicalNormalizer.stripDotLeaders(line.transcript)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty, !isFootnoteOrHeaderDiscard(clean) else { continue }

                    if clean.contains("•") || clean.contains("\u{2022}") || clean.contains("\u{00B7}") {
                        let unpacked = unpackBulletLine(clean, boundingBox: line.boundingBox)
                        if !unpacked.isEmpty {
                            bulletRows.append(contentsOf: unpacked)
                            continue
                        }
                    }

                    atoms.append(SpatialAtom(transcript: clean, boundingBox: line.boundingBox, words: line.words))
                }
            } else {
                let rawLines = block.transcript
                    .components(separatedBy: .newlines)
                    .map { FDALexicalNormalizer.stripDotLeaders($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                guard !rawLines.isEmpty else { continue }
                let sliceHeight = max(0.01, block.height / CGFloat(rawLines.count))

                for (idx, lineText) in rawLines.enumerated() {
                    guard !isFootnoteOrHeaderDiscard(lineText) else { continue }
                    let sliceBox = CGRect(
                        x: block.minX,
                        y: block.minY + CGFloat(idx) * sliceHeight,
                        width: block.width,
                        height: sliceHeight
                    )

                    if lineText.contains("•") || lineText.contains("\u{2022}") || lineText.contains("\u{00B7}") {
                        let unpacked = unpackBulletLine(lineText, boundingBox: sliceBox)
                        if !unpacked.isEmpty {
                            bulletRows.append(contentsOf: unpacked)
                            continue
                        }
                    }

                    atoms.append(SpatialAtom(transcript: lineText, boundingBox: sliceBox))
                }
            }
        }

        // Deduplicate spatially identical atoms (e.g., when both a table cell and a paragraph covered the same text).
        var uniqueAtoms: [SpatialAtom] = []
        for candidate in atoms {
            let exists = uniqueAtoms.contains { existing in
                let sameText = existing.transcript.lowercased() == candidate.transcript.lowercased()
                let closePos = abs(existing.midX - candidate.midX) < 0.015 && abs(existing.skewCorrectedMidY - candidate.skewCorrectedMidY) < 0.012
                return sameText && closePos
            }
            if !exists {
                uniqueAtoms.append(candidate)
            }
        }

        return (uniqueAtoms, bulletRows)
    }

    // MARK: - Step 2: Label Tilt / Skew Slope Estimation

    /// Estimates the camera tilt / label skew slope $m = \Delta y / \Delta x$ from intra-line word sequences
    /// and horizontal header pairs, clamped to $[-0.25, +0.25]$ ($\approx \pm 14^\circ$).
    static func estimateSkewSlope(from textBlocks: [ScannedTextBlock]) -> CGFloat {
        estimateLabelSkewSlope(from: nil, textBlocks: textBlocks)
    }

    private static func estimateLabelSkewSlope(
        from atoms: [SpatialAtom]? = nil,
        textBlocks: [ScannedTextBlock]
    ) -> CGFloat {
        var candidateSlopes: [CGFloat] = []

        // 1. Intra-line word token linear regression (most reliable local baseline estimator).
        for block in textBlocks {
            for line in block.lines where line.words.count >= 2 {
                let sortedWords = line.words.sorted { $0.minX < $1.minX }
                guard let firstWord = sortedWords.first,
                      let lastWord = sortedWords.last else { continue }
                let spanX = lastWord.midX - firstWord.midX
                guard spanX >= 0.08 else { continue }

                let meanX = sortedWords.map(\.midX).reduce(0, +) / CGFloat(sortedWords.count)
                let meanY = sortedWords.map(\.midY).reduce(0, +) / CGFloat(sortedWords.count)
                var num: CGFloat = 0
                var den: CGFloat = 0
                for word in sortedWords {
                    let dx = word.midX - meanX
                    let dy = word.midY - meanY
                    num += dx * dy
                    den += dx * dx
                }
                if den > 0.0005 {
                    let slope = num / den
                    if abs(slope) <= 0.25 {
                        candidateSlopes.append(slope)
                    }
                }
            }
        }

        // 2. If word-level slopes are unavailable, check horizontally paired atoms (e.g. left nutrient label + right % DV).
        if candidateSlopes.isEmpty, let atomList = atoms {
            let leftAnchors = atomList.filter { atom in
                atom.minX < 0.45 && FDALexicalNormalizer.resolveNutrientID(from: atom.transcript) != nil && !containsPercentToken(atom.transcript)
            }
            let rightDVTokens = atomList.filter { atom in
                atom.minX >= 0.45 && isPurePercentOrWeightToken(atom.transcript)
            }

            for left in leftAnchors {
                let closeRight = rightDVTokens.filter { abs($0.boundingBox.midY - left.boundingBox.midY) <= max(0.025, left.height * 1.4) }
                if closeRight.count == 1, let right = closeRight.first {
                    let dx = right.midX - left.midX
                    if dx >= 0.15 {
                        let slope = (right.boundingBox.midY - left.boundingBox.midY) / dx
                        if abs(slope) <= 0.25 {
                            candidateSlopes.append(slope)
                        }
                    }
                }
            }
        }

        guard !candidateSlopes.isEmpty else { return 0.0 }
        let sortedSlopes = candidateSlopes.sorted()
        return sortedSlopes[sortedSlopes.count / 2]
    }

    // MARK: - Step 3: Vertical Column Split Detection & De-Interleaving (Topology D, Tabular A/I/K, & Part 3.4)

    private static func deinterleaveVerticalColumnZones(
        atoms: [SpatialAtom],
        topology: FDALabelTopology,
        isSupplement: Bool
    ) -> [VerticalColumnZone] {
        guard !atoms.isEmpty else { return [] }

        let minRegionX = atoms.map(\.minX).min() ?? 0.0
        let maxRegionX = atoms.map(\.maxX).max() ?? 1.0

        // Identify all atoms that start with a recognized nutrient label (excluding pure numeric/unit/percent tokens).
        let nutrientAnchorAtoms = atoms.filter { atom in
            guard !isPurePercentOrWeightToken(atom.transcript) else { return false }
            let hasLetters = atom.transcript.unicodeScalars.contains { CharacterSet.letters.contains($0) }
            guard hasLetters else { return false }
            return FDALexicalNormalizer.resolveNutrientID(from: atom.transcript) != nil
        }

        // Case 1: Full-height Two-Stack Split (Tabular A, I, K or Part 3.4 Right-Hand Supplement Continuation Panel).
        if let splitX = detectFullHeightColumnSplitX(
            nutrientAnchors: nutrientAnchorAtoms,
            allAtoms: atoms,
            topology: topology
        ) {
            let leftAtoms = atoms.filter { $0.midX < splitX }
            let rightAtoms = atoms.filter { $0.midX >= splitX }
            var zones: [VerticalColumnZone] = []
            if !leftAtoms.isEmpty {
                zones.append(VerticalColumnZone(minX: minRegionX, maxX: splitX, atoms: leftAtoms))
            }
            if !rightAtoms.isEmpty {
                zones.append(VerticalColumnZone(minX: splitX, maxX: maxRegionX, atoms: rightAtoms))
            }
            if zones.count == 2 {
                return zones
            }
        }

        // Case 2: Topology D (Standard Vertical Macronutrients above + Side-by-Side Micronutrients below Protein).
        if let (microStartY, microSplitX) = detectSideBySideMicronutrientSplit(
            nutrientAnchors: nutrientAnchorAtoms,
            allAtoms: atoms,
            topology: topology
        ) {
            let upperMacroAtoms = atoms.filter { $0.skewCorrectedMidY < microStartY }
            let lowerLeftMicroAtoms = atoms.filter { $0.skewCorrectedMidY >= microStartY && $0.midX < microSplitX }
            let lowerRightMicroAtoms = atoms.filter { $0.skewCorrectedMidY >= microStartY && $0.midX >= microSplitX }

            var zones: [VerticalColumnZone] = []
            if !upperMacroAtoms.isEmpty {
                zones.append(VerticalColumnZone(minX: minRegionX, maxX: maxRegionX, atoms: upperMacroAtoms))
            }
            if !lowerLeftMicroAtoms.isEmpty {
                zones.append(VerticalColumnZone(minX: minRegionX, maxX: microSplitX, atoms: lowerLeftMicroAtoms))
            }
            if !lowerRightMicroAtoms.isEmpty {
                zones.append(VerticalColumnZone(minX: microSplitX, maxX: maxRegionX, atoms: lowerRightMicroAtoms))
            }
            if zones.count >= 2 {
                return zones
            }
        }

        // Default: Single vertical column zone.
        return [VerticalColumnZone(minX: minRegionX, maxX: maxRegionX, atoms: atoms)]
    }

    private static func detectFullHeightColumnSplitX(
        nutrientAnchors: [SpatialAtom],
        allAtoms: [SpatialAtom],
        topology: FDALabelTopology
    ) -> CGFloat? {
        guard nutrientAnchors.count >= 4 else { return nil }

        let sortedMinXs = nutrientAnchors.map(\.minX).sorted()
        guard let firstX = sortedMinXs.first, let lastX = sortedMinXs.last else { return nil }
        let totalSpan = lastX - firstX

        // A true two-column split requires the right-hand column's nutrient labels to start at least 0.22 normalized width
        // to the right of the left-hand column's nutrient labels (much wider than Level 1/2 indentation which is <= 0.08).
        guard totalSpan >= 0.22 else { return nil }

        // Find the largest horizontal gap between sorted `minX` values of nutrient anchors.
        var bestGap: CGFloat = 0
        var bestSplitX: CGFloat?

        for i in 0..<(sortedMinXs.count - 1) {
            let gap = sortedMinXs[i + 1] - sortedMinXs[i]
            if gap > bestGap && gap >= 0.14 {
                let candidateSplit = (sortedMinXs[i] + sortedMinXs[i + 1]) * 0.5
                let leftCluster = nutrientAnchors.filter { $0.minX < candidateSplit }
                let rightCluster = nutrientAnchors.filter { $0.minX >= candidateSplit }

                guard leftCluster.count >= 2 && rightCluster.count >= 2 else { continue }

                // Check if the Y-ranges of the left and right clusters overlap significantly (confirming side-by-side stacks).
                let leftMinY = leftCluster.map(\.skewCorrectedMinY).min() ?? 0
                let leftMaxY = leftCluster.map(\.skewCorrectedMaxY).max() ?? 0
                let rightMinY = rightCluster.map(\.skewCorrectedMinY).min() ?? 0
                let rightMaxY = rightCluster.map(\.skewCorrectedMaxY).max() ?? 0

                let overlapY = min(leftMaxY, rightMaxY) - max(leftMinY, rightMinY)
                let minSpanY = max(0.01, min(leftMaxY - leftMinY, rightMaxY - rightMinY))

                if (overlapY / minSpanY) >= 0.35 || topology.isTabularLayout {
                    bestGap = gap
                    bestSplitX = candidateSplit
                }
            }
        }

        return bestSplitX
    }

    private static func detectSideBySideMicronutrientSplit(
        nutrientAnchors: [SpatialAtom],
        allAtoms: [SpatialAtom],
        topology: FDALabelTopology
    ) -> (startY: CGFloat, splitX: CGFloat)? {
        let microAnchors = nutrientAnchors.filter { atom in
            guard let id = FDALexicalNormalizer.resolveNutrientID(from: atom.transcript) else { return false }
            return id.isMicronutrientRDI
        }
        guard microAnchors.count >= 2 else { return nil }

        // Check if pairs of micronutrient anchors share the same skew-corrected Y-band at left and right X positions.
        var sideBySidePairs: [(left: SpatialAtom, right: SpatialAtom)] = []
        for i in 0..<microAnchors.count {
            for j in (i + 1)..<microAnchors.count {
                let a = microAnchors[i]
                let b = microAnchors[j]
                let dy = abs(a.skewCorrectedMidY - b.skewCorrectedMidY)
                let maxH = max(0.015, max(a.height, b.height))
                let dx = abs(a.minX - b.minX)
                if dy <= maxH * 0.65 && dx >= 0.16 {
                    let left = a.minX < b.minX ? a : b
                    let right = a.minX < b.minX ? b : a
                    sideBySidePairs.append((left, right))
                }
            }
        }

        guard !sideBySidePairs.isEmpty else { return nil }

        let minMicroY = sideBySidePairs.map { min($0.left.skewCorrectedMinY, $0.right.skewCorrectedMinY) }.min() ?? 0
        let avgRightMinX = sideBySidePairs.map(\.right.minX).reduce(0, +) / CGFloat(sideBySidePairs.count)
        let avgLeftMinX = sideBySidePairs.map(\.left.minX).reduce(0, +) / CGFloat(sideBySidePairs.count)
        let splitX = avgLeftMinX + (avgRightMinX - avgLeftMinX) * 0.52

        return (startY: minMicroY - 0.008, splitX: splitX)
    }

    // MARK: - Step 4 & 5: Skew-Compensated Y-Band Clustering & 1D minX Indentation Clustering

    private static func stitchSingleColumnZone(
        atoms: [SpatialAtom],
        isSupplement: Bool
    ) -> [RawExtractedRow] {
        let sortedByY = atoms.sorted { lhs, rhs in
            if abs(lhs.skewCorrectedMidY - rhs.skewCorrectedMidY) > 0.004 {
                return lhs.skewCorrectedMidY < rhs.skewCorrectedMidY
            }
            return lhs.minX < rhs.minX
        }

        // 1. Cluster atoms into horizontal Y-bands.
        var rowBands: [[SpatialAtom]] = []

        for atom in sortedByY {
            let atomNutrient = resolveNutrientAnchorIfAlphabetic(atom.transcript)

            if let matchIdx = findMatchingRowBandIndex(
                for: atom,
                atomNutrient: atomNutrient,
                in: rowBands
            ) {
                rowBands[matchIdx].append(atom)
            } else {
                rowBands.append([atom])
            }
        }

        // Sort tokens left-to-right within each band.
        for idx in rowBands.indices {
            rowBands[idx].sort { $0.minX < $1.minX }
        }

        // 2. Compute column baseline `minX` and column width for Level 0 / Level 1 / Level 2 indentation clustering.
        let (baselineMinX, columnWidth) = computeColumnIndentationBaseline(from: rowBands)

        // 3. Assemble `RawExtractedRow` records from each stitched band.
        var extractedRows: [RawExtractedRow] = []

        for band in rowBands {
            // Also check if a single line inside the band actually contains two side-by-side micronutrients merged into one string
            // (e.g., "Vit. D 2mcg 10% Calcium 260mg 20%").
            if band.count == 1,
               let splitMicroRows = trySplitMergedSideBySideMicronutrientLine(band[0]) {
                extractedRows.append(contentsOf: splitMicroRows)
                continue
            }

            if let row = assembleRowFromBand(
                band,
                baselineMinX: baselineMinX,
                columnWidth: columnWidth,
                isSupplement: isSupplement
            ) {
                extractedRows.append(row)
            }
        }

        return extractedRows
    }

    private static func findMatchingRowBandIndex(
        for atom: SpatialAtom,
        atomNutrient: CanonicalNutrientID?,
        in existingBands: [[SpatialAtom]]
    ) -> Int? {
        guard !existingBands.isEmpty else { return nil }

        // Check recent bands from bottom to top.
        var bestBandIndex: Int?
        var bestVerticalDistance: CGFloat = .greatestFiniteMagnitude

        for idx in existingBands.indices.reversed() {
            let band = existingBands[idx]
            let bandMidY = band.map(\.skewCorrectedMidY).reduce(0, +) / CGFloat(band.count)
            let bandMaxHeight = band.map(\.height).max() ?? atom.height
            let refHeight = max(0.012, max(bandMaxHeight, atom.height))

            let dy = abs(atom.skewCorrectedMidY - bandMidY)
            // Allow slightly wider vertical tolerance (0.60 * refHeight) when pairing a right-aligned weight/%DV token
            // with a left-aligned nutrient label on a curved surface, and 0.45 * refHeight otherwise.
            let isWeightOrPercentContinuation = (atomNutrient == nil) && isPurePercentOrWeightToken(atom.transcript)
            let tolerance = isWeightOrPercentContinuation ? (refHeight * 0.62) : (refHeight * 0.45)

            if dy > refHeight * 1.5 {
                // Since bands are ordered by Y, earlier bands are even further above.
                break
            }

            guard dy <= tolerance else { continue }

            // Never merge two distinct nutrient label anchors into the same row band!
            let bandHasNutrientAnchor = band.compactMap { resolveNutrientAnchorIfAlphabetic($0.transcript) }.first
            if let newNut = atomNutrient, let existingNut = bandHasNutrientAnchor, newNut != existingNut {
                continue
            }

            // Never merge two tokens that overlap horizontally at the same X position on different lines.
            let hasHorizontalCollision = band.contains { existing in
                let overlapX = min(existing.maxX, atom.maxX) - max(existing.minX, atom.minX)
                let minW = max(0.005, min(existing.width, atom.width))
                return (overlapX / minW) > 0.50
            }
            if hasHorizontalCollision {
                continue
            }

            if dy < bestVerticalDistance {
                bestVerticalDistance = dy
                bestBandIndex = idx
            }
        }

        return bestBandIndex
    }

    private static func computeColumnIndentationBaseline(
        from rowBands: [[SpatialAtom]]
    ) -> (baselineMinX: CGFloat, columnWidth: CGFloat) {
        let topLevelNutrients: Set<CanonicalNutrientID> = [
            .calories, .totalFat, .cholesterol, .sodium, .totalCarbohydrate, .protein
        ]

        var anchorMinXs: [CGFloat] = []
        var allMinXs: [CGFloat] = []
        var allMaxXs: [CGFloat] = []

        for band in rowBands {
            guard let first = band.first, let last = band.last else { continue }
            let joined = band.map(\.transcript).joined(separator: " ")
            guard let id = FDALexicalNormalizer.resolveNutrientID(from: joined) else { continue }

            allMinXs.append(first.minX)
            allMaxXs.append(last.maxX)
            if topLevelNutrients.contains(id) {
                anchorMinXs.append(first.minX)
            }
        }

        let baseline: CGFloat
        if !anchorMinXs.isEmpty {
            let sorted = anchorMinXs.sorted()
            baseline = sorted[sorted.count / 4]
        } else if !allMinXs.isEmpty {
            let sorted = allMinXs.sorted()
            baseline = sorted[max(0, sorted.count / 5)]
        } else {
            baseline = 0.05
        }

        let maxRight = allMaxXs.max() ?? min(1.0, baseline + 0.45)
        let width = max(0.20, maxRight - baseline)
        return (baseline, width)
    }

    private static func assembleRowFromBand(
        _ band: [SpatialAtom],
        baselineMinX: CGFloat,
        columnWidth: CGFloat,
        isSupplement: Bool
    ) -> RawExtractedRow? {
        let tokenStrings = band
            .map { FDALexicalNormalizer.stripDotLeaders($0.transcript).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !tokenStrings.isEmpty else { return nil }

        let combined = tokenStrings.joined(separator: " ")
        guard !isFootnoteOrHeaderDiscard(combined) else { return nil }

        // Check for Calories row first.
        if combined.lowercased().contains("calories")
            && !combined.lowercased().contains("calories from")
            && !combined.lowercased().contains("2,000 calories")
            && !combined.lowercased().contains("1,000 calories") {
            if let calVal = extractCalorieInt(from: combined) {
                let firstAtom = band[0]
                let unionBox = band.dropFirst().reduce(firstAtom.boundingBox) { $0.union($1.boundingBox) }
                return RawExtractedRow(
                    nutrientLabelTranscript: "Calories",
                    weightTranscript: "\(calVal)",
                    percentDVTranscript: "",
                    rawCells: ["Calories", "\(calVal)"],
                    minX: firstAtom.minX,
                    midY: unionBox.midY,
                    boundingBox: unionBox,
                    indentationLevel: .level0,
                    columnIndex: 0
                )
            }
        }

        guard let nutrient = FDALexicalNormalizer.resolveNutrientID(from: combined) else {
            return nil
        }

        // Isolate primary ("Per Serving") tokens when multiple weight / %DV pairs sit on the same stitched line.
        let primaryTokens = isolatePrimaryTokensInStitchedBand(tokenStrings)
        let (labelPart, weightPart, dvPart) = partitionTokensIntoRoles(primaryTokens, for: nutrient)

        let firstAtom = band[0]
        let unionBox = band.dropFirst().reduce(firstAtom.boundingBox) { $0.union($1.boundingBox) }

        let indentation = classifyMinXIndentation(
            rowMinX: firstAtom.minX,
            rawText: firstAtom.transcript,
            baselineMinX: baselineMinX,
            columnWidth: columnWidth,
            nutrient: nutrient
        )

        return RawExtractedRow(
            nutrientLabelTranscript: labelPart,
            weightTranscript: weightPart,
            percentDVTranscript: dvPart,
            rawCells: primaryTokens,
            minX: firstAtom.minX,
            midY: unionBox.midY,
            boundingBox: unionBox,
            indentationLevel: indentation,
            columnIndex: 0
        )
    }

    private static func classifyMinXIndentation(
        rowMinX: CGFloat,
        rawText: String,
        baselineMinX: CGFloat,
        columnWidth: CGFloat,
        nutrient: CanonicalNutrientID
    ) -> NutrientIndentationLevel {
        // 1. Check leading whitespace if preserved.
        var leadingSpaces = 0
        for ch in rawText {
            if ch == " " || ch == "\u{00A0}" {
                leadingSpaces += 1
            } else {
                break
            }
        }
        if leadingSpaces >= 6 { return .level2 }
        if leadingSpaces >= 2 { return .level1 }

        // 2. Cluster normalized `minX` offset relative to the column baseline margin `baselineMinX`.
        let relativeOffset = (rowMinX - baselineMinX) / max(0.20, columnWidth)
        if relativeOffset >= 0.080 {
            return .level2
        } else if relativeOffset >= 0.032 {
            return .level1
        }

        // 3. Fallback to canonical FDA indentation hierarchy (`Part 1.2`).
        return nutrient.indentationLevel
    }

    /// Isolates the primary `"Per Serving"` tokens when a stitched horizontal band comes from a Dual-Column label.
    private static func isolatePrimaryTokensInStitchedBand(_ tokens: [String]) -> [String] {
        guard tokens.count > 2 else { return tokens }

        var selected: [String] = []
        var foundPrimaryWeight = false
        var foundPrimaryDV = false

        for (idx, token) in tokens.enumerated() {
            if idx == 0 {
                selected.append(token)
                if containsWeightToken(token) {
                    foundPrimaryWeight = true
                }
                if containsPercentToken(token) {
                    foundPrimaryDV = true
                }
                continue
            }

            if foundPrimaryWeight && foundPrimaryDV {
                break
            }

            if !foundPrimaryWeight && containsWeightToken(token) {
                selected.append(token)
                foundPrimaryWeight = true
                if containsPercentToken(token) {
                    foundPrimaryDV = true
                }
                continue
            }

            if foundPrimaryWeight && !foundPrimaryDV {
                if isPercentOrSymbolToken(token) && !containsWeightToken(token) {
                    selected.append(token)
                    foundPrimaryDV = true
                }
                // Stop before ingesting a second weight column (e.g. "Per Container" weight).
                break
            }

            // Token is still part of a multi-word nutrient name (e.g. "Saturated", "Fat").
            selected.append(token)
        }

        return selected
    }

    private static func partitionTokensIntoRoles(
        _ tokens: [String],
        for nutrient: CanonicalNutrientID
    ) -> (label: String, weight: String, percentDV: String) {
        let joined = tokens.joined(separator: " ")
        let weight = extractWeightToken(from: joined) ?? ""
        let dv = extractPercentToken(from: joined) ?? ""

        if tokens.count == 1 {
            return (joined, weight, dv)
        }

        if tokens.count == 2 {
            if isPercentOrSymbolToken(tokens[1]) && !containsWeightToken(tokens[1]) {
                return (tokens[0], weight, tokens[1])
            }
            return (tokens[0], tokens[1], dv)
        }

        let labelTokens = tokens.dropLast(2).joined(separator: " ")
        return (
            labelTokens.isEmpty ? tokens[0] : labelTokens,
            tokens[tokens.count - 2],
            tokens[tokens.count - 1]
        )
    }

    // MARK: - Merged Side-by-Side Micronutrient Line Splitter (Topology D)

    private static func trySplitMergedSideBySideMicronutrientLine(
        _ atom: SpatialAtom
    ) -> [RawExtractedRow]? {
        let text = atom.transcript
        // Pattern matching two side-by-side micronutrients on one line, e.g. "Vit. D 2mcg 10% Calcium 260mg 20%" or "Iron 8mg 45% Potas. 235mg 6%"
        let pattern = #"(?i)^(.*?[0-9]+\s*%)\s+([A-Za-z].*?[0-9]+\s*%)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let leftRange = Range(match.range(at: 1), in: text),
              let rightRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let leftSegment = String(text[leftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let rightSegment = String(text[rightRange]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard let leftId = FDALexicalNormalizer.resolveNutrientID(from: leftSegment),
              let rightId = FDALexicalNormalizer.resolveNutrientID(from: rightSegment),
              leftId.isMicronutrientRDI && rightId.isMicronutrientRDI && leftId != rightId else {
            return nil
        }

        let halfWidth = atom.width * 0.5
        let leftBox = CGRect(x: atom.minX, y: atom.boundingBox.minY, width: halfWidth, height: atom.height)
        let rightBox = CGRect(x: atom.minX + halfWidth, y: atom.boundingBox.minY, width: halfWidth, height: atom.height)

        let (lLabel, lWt, lDV) = partitionTokensIntoRoles([leftSegment], for: leftId)
        let (rLabel, rWt, rDV) = partitionTokensIntoRoles([rightSegment], for: rightId)

        return [
            RawExtractedRow(
                nutrientLabelTranscript: lLabel,
                weightTranscript: lWt,
                percentDVTranscript: lDV,
                rawCells: [leftSegment],
                minX: leftBox.minX,
                midY: leftBox.midY,
                boundingBox: leftBox,
                indentationLevel: .level0,
                columnIndex: 0
            ),
            RawExtractedRow(
                nutrientLabelTranscript: rLabel,
                weightTranscript: rWt,
                percentDVTranscript: rDV,
                rawCells: [rightSegment],
                minX: rightBox.minX,
                midY: rightBox.midY,
                boundingBox: rightBox,
                indentationLevel: .level0,
                columnIndex: 0
            )
        ]
    }

    // MARK: - Linear String Clause Helpers

    private static func containsLinearDisplayParagraph(in blocks: [ScannedTextBlock]) -> Bool {
        for block in blocks {
            let lower = block.transcript.lowercased()
            let commaCount = block.transcript.filter { $0 == "," }.count
            if commaCount >= 5 && (lower.contains("% dv)") || (lower.contains("total fat") && lower.contains("sodium") && lower.contains("protein"))) {
                return true
            }
        }
        return false
    }

    private static func splitTopLevelClauses(_ text: String) -> [String] {
        var clauses: [String] = []
        var current = ""
        var parenDepth = 0

        for ch in text {
            if ch == "(" {
                parenDepth += 1
                current.append(ch)
            } else if ch == ")" {
                parenDepth = max(0, parenDepth - 1)
                current.append(ch)
            } else if (ch == "," || ch == ";") && parenDepth == 0 {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    clauses.append(trimmed)
                }
                current = ""
            } else {
                current.append(ch)
            }
        }

        let finalTrimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalTrimmed.isEmpty {
            clauses.append(finalTrimmed)
        }
        return clauses
    }

    private static func stripLeadingLinearPrefix(_ clause: String) -> String {
        var result = clause.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = [
            "nutrition facts",
            "supplement facts",
            "amount per serving:",
            "amount per serving",
            "amount/serving:",
            "amount/serving",
            "per serving:"
        ]
        for prefix in prefixes {
            if let range = result.range(of: prefix, options: [.caseInsensitive, .anchored]) {
                result = String(result[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if let colonIdx = result.firstIndex(of: ":"),
           result[..<colonIdx].lowercased().contains("serv") {
            let afterColon = String(result[result.index(after: colonIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if FDALexicalNormalizer.resolveNutrientID(from: afterColon) != nil {
                return afterColon
            }
            return ""
        }
        return result
    }

    private static func extractNestedAddedSugarsClause(
        from clause: String
    ) -> (primary: String, nestedAddedSugars: String?) {
        let pattern = #"(?i)\(([^()]*added\s+sugars[^()]*)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: clause, range: NSRange(clause.startIndex..., in: clause)),
              let fullRange = Range(match.range(at: 0), in: clause),
              let innerRange = Range(match.range(at: 1), in: clause) else {
            return (clause, nil)
        }

        let innerText = String(clause[innerRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        var primaryText = clause
        primaryText.removeSubrange(fullRange)
        primaryText = primaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        return (primaryText, innerText)
    }

    private static func decomposeLinearClause(
        _ clause: String,
        for nutrient: CanonicalNutrientID
    ) -> (label: String, weight: String, percentDV: String) {
        if nutrient == .calories {
            let calVal = extractCalorieInt(from: clause).map { "\($0)" } ?? ""
            return ("Calories", calVal, "")
        }
        let weight = extractWeightToken(from: clause) ?? ""
        let dv = extractPercentToken(from: clause) ?? ""
        return (clause, weight, dv)
    }

    private static func formatDeclaredAmountForCell(
        _ amount: DeclaredNutrientAmount,
        nutrient: CanonicalNutrientID
    ) -> String {
        switch amount {
        case .omitted, .insignificantFootnote:
            return ""
        case .explicitZero(let unit):
            return "0\(unit?.rawValue ?? nutrient.primaryUnit.rawValue)"
        case .threshold(let kind, let unit):
            let unitStr = unit?.rawValue ?? nutrient.primaryUnit.rawValue
            switch kind {
            case .lessThanFiveCalories: return "<5"
            case .lessThanHalfGram: return "<0.5\(unitStr)"
            case .lessThanOneGram: return "<1\(unitStr)"
            case .lessThanFiveMilligrams: return "<5\(unitStr)"
            case .lessThanOnePercentDV, .lessThanTwoPercentDV: return ""
            }
        case .exact(let value, let unit, _, _):
            let cleanNum = value.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(value))"
                : "\(value)"
            return unit == .kcal ? cleanNum : "\(cleanNum)\(unit.rawValue)"
        }
    }

    private static func formatDeclaredPercentDVForCell(_ dv: DeclaredPercentDV) -> String {
        switch dv {
        case .omitted:
            return ""
        case .notEstablished(let symbol):
            return symbol ?? "†"
        case .threshold(let kind):
            return kind == .lessThanOnePercentDV ? "<1%" : "<2%"
        case .exact(let pct):
            return "\(pct)%"
        }
    }

    // MARK: - Bullet Unpacking & Lexical Predicates

    private static func unpackBulletLine(
        _ text: String,
        boundingBox: CGRect
    ) -> [RawExtractedRow] {
        let separators = CharacterSet(charactersIn: "•\u{2022}\u{00B7}")
        let parts = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var rows: [RawExtractedRow] = []
        for part in parts {
            guard let id = FDALexicalNormalizer.resolveNutrientID(from: part) else { continue }
            let weight = extractWeightToken(from: part) ?? ""
            let dv = extractPercentToken(from: part) ?? ""
            rows.append(
                RawExtractedRow(
                    nutrientLabelTranscript: part,
                    weightTranscript: weight,
                    percentDVTranscript: dv,
                    rawCells: [part],
                    minX: boundingBox.minX,
                    midY: boundingBox.midY,
                    boundingBox: boundingBox,
                    indentationLevel: id.indentationLevel,
                    columnIndex: 0
                )
            )
        }
        return rows
    }

    private static func resolveNutrientAnchorIfAlphabetic(_ text: String) -> CanonicalNutrientID? {
        guard !isPurePercentOrWeightToken(text) else { return nil }
        let hasLetters = text.unicodeScalars.contains { CharacterSet.letters.contains($0) }
        guard hasLetters else { return nil }
        return FDALexicalNormalizer.resolveNutrientID(from: text)
    }

    private static func isFootnoteOrHeaderDiscard(_ text: String) -> Bool {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.isEmpty { return true }

        if lower == "nutrition facts"
            || lower == "supplement facts"
            || lower == "amount per serving"
            || lower == "amount/serving"
            || lower == "% daily value"
            || lower == "% daily value*"
            || lower == "% dv"
            || lower == "% dv*"
            || lower == "per serving"
            || lower == "per container" {
            return true
        }

        if lower.contains("tells you how much a nutrient")
            || lower.contains("2,000 calories a day is used")
            || lower.contains("1,000 calories a day is used")
            || lower.contains("not a significant source of")
            || lower.contains("% dv = % daily value")
            || lower.contains("daily value not established")
            || lower.contains("percent daily values are based on")
            || lower.hasPrefix("ingredients:")
            || lower.hasPrefix("other ingredients:") {
            return true
        }

        if (lower.contains("serving size") || lower.contains("serv. size") || lower.contains("servings per container"))
            && FDALexicalNormalizer.resolveNutrientID(from: text) == nil {
            return true
        }

        return false
    }

    private static func containsWeightToken(_ text: String) -> Bool {
        extractWeightToken(from: text) != nil
    }

    private static func containsPercentToken(_ text: String) -> Bool {
        extractPercentToken(from: text) != nil
    }

    private static func isPercentOrSymbolToken(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if trimmed.contains("%") { return true }
        let symbols = CharacterSet(charactersIn: "*†‡§+ ")
        return trimmed.unicodeScalars.allSatisfy { symbols.contains($0) }
    }

    private static func isPurePercentOrWeightToken(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPercentOrSymbolToken(trimmed) { return true }
        let pattern = #"(?i)^(?:<|less\s+than\s+)?[0-9]+(?:\.[0-9]+)?\s*(?:mcg\s*dfe|mcg\s*rae|mg\s*ne|g|mg|mcg|µg|ug|iu|%)?[*†‡]?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil
    }

    private static func extractWeightToken(from text: String) -> String? {
        let pattern = #"(?i)((?:<|less\s+than\s+)?[0-9]+(?:\.[0-9]+)?\s*(?:mcg\s*dfe|mcg\s*rae|mg\s*ne|g|mg|mcg|µg|ug|iu))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func extractPercentToken(from text: String) -> String? {
        let pattern = #"(?i)((?:<|less\s+than\s+)?[0-9]+(?:\.[0-9]+)?\s*%)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func extractCalorieInt(from text: String) -> Int? {
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

    private static func ensureCaloriesRow(
        in rows: [RawExtractedRow],
        inferredCaloriesValue: Int?
    ) -> [RawExtractedRow] {
        let hasCalorieRow = rows.contains {
            FDALexicalNormalizer.resolveNutrientID(from: $0.combinedTranscript) == .calories
        }
        guard !hasCalorieRow, let calVal = inferredCaloriesValue else {
            return rows
        }

        let calRow = RawExtractedRow(
            nutrientLabelTranscript: "Calories",
            weightTranscript: "\(calVal)",
            percentDVTranscript: "",
            rawCells: ["Calories", "\(calVal)"],
            minX: 0.05,
            midY: 0.01,
            boundingBox: CGRect(x: 0.05, y: 0.01, width: 0.90, height: 0.025),
            indentationLevel: .level0,
            columnIndex: 0
        )
        return [calRow] + rows
    }

    private static func deduplicateRows(_ rows: [RawExtractedRow]) -> [RawExtractedRow] {
        var seen = Set<String>()
        var result: [RawExtractedRow] = []
        for row in rows {
            let key = row.rawCells.joined(separator: "|").lowercased()
            if seen.insert(key).inserted {
                result.append(row)
            }
        }
        return result
    }
}
