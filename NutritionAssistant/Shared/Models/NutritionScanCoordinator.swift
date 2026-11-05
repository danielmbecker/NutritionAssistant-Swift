//
//  NutritionScanCoordinator.swift
//  NutritionAssistant
//
//  Milestone 4.5: End-to-End Vision Pipeline Coordinator & Phase 1 Integration Bridge
//  Orchestrates Milestones 4.1 (VisionDocumentScanner), 4.2 (FDALabelTopologyClassifier),
//  4.3 (VisionTableRowExtractor), and 4.4 (VisionSpatialRowStitcher), and executes the
//  Phase 2 Integration Recipe from Phase1_API_Contract.md to return a validated
//  ScannedNutritionPayload for AddFoodView.
//

import CoreGraphics
import Foundation
import ImageIO

// MARK: - Combined Payload & Diagnostics Evaluation Result

/// Pairs the validated `ScannedNutritionPayload` with the full `ScanDiagnosticsSnapshot`
/// (including internal pipeline state and all 5 optical/physical telemetry metrics)
/// and per-column candidates (`columnCandidates`) for Dual-Column / Aggregate Variety Pack labels.
struct NutritionScanEvaluation: Codable, Sendable, Equatable {
    let payload: ScannedNutritionPayload
    let diagnostics: ScanDiagnosticsSnapshot
    let columnCandidates: [ScannedColumnCandidate]

    init(
        payload: ScannedNutritionPayload,
        diagnostics: ScanDiagnosticsSnapshot,
        columnCandidates: [ScannedColumnCandidate] = []
    ) {
        self.payload = payload
        self.diagnostics = diagnostics
        self.columnCandidates = columnCandidates
    }
}

enum NutritionScanCoordinator {

    // MARK: - Public Scan Entry Points

    /// Runs the complete Phase 2 Vision & spatial pipeline on raw image `Data` and returns a validated `ScannedNutritionPayload`.
    static func scan(
        imageData: Data,
        orientation: CGImagePropertyOrientation? = nil
    ) async throws -> ScannedNutritionPayload {
        let evaluation = try await scanWithDiagnostics(
            imageData: imageData,
            orientation: orientation
        )
        return evaluation.payload
    }

    /// Runs the complete Phase 2 Vision & spatial pipeline on a `CGImage` and returns a validated `ScannedNutritionPayload`.
    static func scan(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation? = nil
    ) async throws -> ScannedNutritionPayload {
        let evaluation = try await scanWithDiagnostics(
            cgImage: cgImage,
            orientation: orientation
        )
        return evaluation.payload
    }

    /// Runs the complete Vision, spatial, validation, and 5-metric optical telemetry pipeline on raw image `Data`,
    /// returning both the `ScannedNutritionPayload` and `ScanDiagnosticsSnapshot`.
    static func scanWithDiagnostics(
        imageData: Data,
        orientation: CGImagePropertyOrientation? = nil
    ) async throws -> NutritionScanEvaluation {
        let snapshot = try await VisionDocumentScanner.scan(
            imageData: imageData,
            orientation: orientation
        )
        return try evaluateSnapshot(
            snapshot,
            imageData: imageData,
            orientation: orientation
        )
    }

    /// Runs the complete Vision, spatial, validation, and 5-metric optical telemetry pipeline on a `CGImage`,
    /// returning both the `ScannedNutritionPayload` and `ScanDiagnosticsSnapshot`.
    static func scanWithDiagnostics(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation? = nil
    ) async throws -> NutritionScanEvaluation {
        let snapshot = try await VisionDocumentScanner.scan(
            cgImage: cgImage,
            orientation: orientation
        )
        return try evaluateSnapshot(
            snapshot,
            cgImage: cgImage,
            orientation: orientation
        )
    }

    // MARK: - Snapshot Orchestration & Phase 2 Integration Recipe

    /// Orchestrates topology classification (Milestone 4.2), 2D grid unpacking (Milestone 4.3),
    /// skew-compensated spatial row stitching (Milestone 4.4), and Phase 1 lexical normalization
    /// and mathematical self-healing (`FDALexicalNormalizer` + `FDANutritionValidator`).
    static func processSnapshot(_ snapshot: ScannedDocumentSnapshot) throws -> ScannedNutritionPayload {
        try evaluateSnapshot(snapshot).payload
    }

    /// Orchestrates the full Phase 2 + Phase 3 diagnostic pipeline on a `ScannedDocumentSnapshot`,
    /// returning both the validated `ScannedNutritionPayload` and `ScanDiagnosticsSnapshot`.
    static func evaluateSnapshot(
        _ snapshot: ScannedDocumentSnapshot,
        cgImage: CGImage? = nil,
        imageData: Data? = nil,
        orientation: CGImagePropertyOrientation? = nil
    ) throws -> NutritionScanEvaluation {
        // 1. Classify topology and recover detached sidebar/header blocks (Milestone 4.2).
        let classified = FDALabelTopologyClassifier.classify(snapshot: snapshot)

        // 2. Extract [RawExtractedRow] via 2D Table Unpacker (Milestone 4.3) and/or Spatial Stitcher (Milestone 4.4).
        let (extractedRows, extractionPath) = extractAndMergeRows(from: snapshot, classified: classified)

        // 3. Execute the Phase 2 Integration Recipe (Phase1_API_Contract.md Section 5):
        //    Step 3a: Reject mandatory § 101.17 warning boxes and Subpart D decoy comparison strings.
        let validRows = extractedRows.filter { row in
            let line = row.rawCells.joined(separator: " ")
            return !FDALexicalNormalizer.isMandatoryBoxedWarning(line)
                && !FDALexicalNormalizer.isDecoyComparativeString(line)
        }

        let rawRowLines = validRows.map { $0.rawCells.joined(separator: " ") }
        var allLines: [String] = []
        for line in classified.allLabelLines + rawRowLines + classified.footnoteTranscripts {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !FDALexicalNormalizer.isMandatoryBoxedWarning(trimmed)
                && !FDALexicalNormalizer.isDecoyComparativeString(trimmed)
                && !allLines.contains(trimmed) {
                allLines.append(trimmed)
            }
        }

        // Reconcile structural topology from Milestone 4.2 with lexical topology from Phase 1.
        let lexicalTopology = FDALexicalNormalizer.classifyTopology(
            fromLines: allLines,
            tableColumnCount: classified.primaryTable?.columnCount ?? ( validRows.first?.rawCells.count ?? 2 )
        )
        var resolvedTopology = reconcileTopology(
            structural: classified.topology,
            lexical: lexicalTopology,
            isSupplementFlag: classified.isSupplement
        )
        let isSupplement = resolvedTopology.isSupplementFacts || classified.isSupplement

        // Multi-column metadata & full-row extraction (including Example M milk-column filtering).
        let multiColumnInfo: (
            columns: [ExtractedTableColumnMetadata],
            allColumnRows: [RawExtractedRow],
            hadDiscardedMilkColumn: Bool
        )? = classified.primaryTable.map {
            VisionTableRowExtractor.extractMultiColumnData(from: $0, classifiedLabel: classified)
        }

        if let info = multiColumnInfo,
           info.hadDiscardedMilkColumn,
           info.columns.count == 1,
           resolvedTopology == .dualColumnSameFood {
            // Example M: Secondary "Cereal With Milk" column was discarded, leaving a single dry-cereal column.
            resolvedTopology = .standardVertical
        }

        //    Step 3b: Parse serving size and servings per container.
        let (servingLineText, containerLineText) = resolveServingAndContainerLines(
            classified: classified,
            allLines: allLines
        )

        var parsedServing = FDALexicalNormalizer.parseServingSize(
            from: servingLineText,
            servingsPerContainerText: containerLineText,
            isSupplement: isSupplement
        )

        // Linear Display (`Topology L`) fallback for serving size and rows if continuous paragraph was used.
        let linearResult: (servingSize: ParsedServingSize?, rows: [ParsedNutrientRow])? =
            (resolvedTopology == .linearString)
            ? FDALexicalNormalizer.parseLinearDisplayPanel(allLines.joined(separator: " "), isSupplement: isSupplement)
            : nil

        if parsedServing == nil, let linearServing = linearResult?.servingSize {
            parsedServing = linearServing
        }

        //    Step 3c: Parse insignificant-source footers ("Not a significant source of...").
        let insignificant = allLines.reduce(into: Set<CanonicalNutrientID>()) { acc, line in
            acc.formUnion(FDALexicalNormalizer.parseInsignificantSourceFooter(line))
        }

        //    Step 3d: Parse canonical nutrient rows via `FDALexicalNormalizer.parseNutrientRow`.
        var nutrientRows: [ParsedNutrientRow] = validRows.flatMap { rawRow -> [ParsedNutrientRow] in
            let parsed = FDALexicalNormalizer.parseNutrientRow(
                cells: rawRow.rawCells,
                isSupplement: isSupplement,
                defaultColumnIndex: rawRow.columnIndex
            )
            if !parsed.isEmpty {
                return parsed
            }
            // Fallback: try parsing the combined transcript as a single cell if multi-cell split failed.
            return FDALexicalNormalizer.parseNutrientRow(
                cells: [rawRow.combinedTranscript],
                isSupplement: isSupplement,
                defaultColumnIndex: rawRow.columnIndex
            )
        }

        if let linearRows = linearResult?.rows, !linearRows.isEmpty {
            let existingIDs = Set(nutrientRows.map(\.nutrient))
            for lRow in linearRows where !existingIDs.contains(lRow.nutrient) {
                nutrientRows.append(lRow)
            }
        }

        // Ensure recovered header/sidebar Calories value is included in `nutrientRows` if not already parsed from a table row.
        if !nutrientRows.contains(where: { $0.nutrient == .calories }),
           let calVal = classified.inferredCaloriesValue {
            let calRow = ParsedNutrientRow(
                nutrient: .calories,
                rawName: "Calories",
                amount: .exact(value: Double(calVal), unit: .kcal, secondaryValue: nil, secondaryUnit: nil),
                percentDV: .omitted,
                indentationLevel: .level0,
                sourceCompoundDescription: nil,
                columnIndex: 0
            )
            nutrientRows.insert(calRow, at: 0)
        }

        // If no nutrients and no serving size were found, check if a legitimate FDA exemption was detected.
        if nutrientRows.isEmpty && parsedServing == nil {
            if let exemption = classified.legitimateExemption ?? snapshot.detectedExemptions.first {
                throw VisionDocumentScanError.legitimateExemptionDetected(exemption)
            }
            throw VisionDocumentScanError.emptyLabelContent
        }

        //    Step 3e: Build per-column `ScannedColumnCandidate`s for all kept (non-milk) columns, plus the primary payload.
        let columnCandidates = buildColumnCandidates(
            multiColumnInfo: multiColumnInfo,
            fallbackValidRows: validRows,
            primaryNutrientRows: nutrientRows,
            resolvedTopology: resolvedTopology,
            isSupplement: isSupplement,
            defaultServing: parsedServing,
            servingLineText: servingLineText,
            containerLineText: containerLineText,
            insignificant: insignificant,
            allLines: allLines,
            fallbackCaloriesValue: classified.inferredCaloriesValue
        )

        let payload: ScannedNutritionPayload
        if let firstCandidate = columnCandidates.first {
            payload = firstCandidate.payload
        } else {
            payload = FDANutritionValidator.buildPayload(
                topology: resolvedTopology,
                servingSize: parsedServing,
                rows: nutrientRows,
                insignificantNutrients: insignificant,
                rawPanelTexts: allLines,
                selectedColumnIndex: 0
            )
        }

        //    Step 4: Compute 5-metric optical telemetry and assemble ScanDiagnosticsSnapshot.
        let skewSlope = Double(VisionSpatialRowStitcher.estimateSkewSlope(from: snapshot.textBlocks))
        let skewDegrees = atan(skewSlope) * 180.0 / .pi
        let quadCorners = snapshot.quadCorners.count == 4 ? snapshot.quadCorners : nil

        let opticalTelemetry: LabelOpticalTelemetry
        if let imageData, !imageData.isEmpty {
            opticalTelemetry = LabelOpticalTelemetryAnalyzer.analyze(
                imageData: imageData,
                snapshot: snapshot,
                classified: classified,
                quadCorners: quadCorners
            )
        } else {
            opticalTelemetry = LabelOpticalTelemetryAnalyzer.analyze(
                cgImage: cgImage,
                orientation: orientation,
                snapshot: snapshot,
                classified: classified,
                quadCorners: quadCorners
            )
        }

        let sortedHealed = payload.healedNutrients.sorted { $0.rawValue < $1.rawValue }
        let origins = buildFieldOrigins(parsedServing: parsedServing, payload: payload)
        let diagnosticsSnapshot = ScanDiagnosticsSnapshot(
            visionConfidence: Double(snapshot.confidence),
            validatorConfidence: payload.confidenceScore,
            structuralTopology: classified.topology,
            lexicalTopology: lexicalTopology,
            resolvedTopology: payload.topology,
            extractionPath: extractionPath,
            labelSkewSlope: skewSlope,
            labelSkewDegrees: skewDegrees,
            atwaterCalorieCheckPassed: payload.atwaterCalorieCheckPassed,
            expectedAtwaterMinCalories: payload.expectedAtwaterCalorieRange.lowerBound,
            expectedAtwaterMaxCalories: payload.expectedAtwaterCalorieRange.upperBound,
            healedNutrients: sortedHealed,
            diagnostics: payload.diagnostics,
            discardedWarningCount: snapshot.discardedWarningCount,
            discardedDecoyCount: snapshot.discardedDecoyCount,
            extractedRowLines: rawRowLines,
            rawLabelLines: allLines,
            nutrientOrigins: origins,
            opticalTelemetry: opticalTelemetry
        )

        return NutritionScanEvaluation(
            payload: payload,
            diagnostics: diagnosticsSnapshot,
            columnCandidates: columnCandidates
        )
    }

    private static func buildColumnCandidates(
        multiColumnInfo: (
            columns: [ExtractedTableColumnMetadata],
            allColumnRows: [RawExtractedRow],
            hadDiscardedMilkColumn: Bool
        )?,
        fallbackValidRows: [RawExtractedRow],
        primaryNutrientRows: [ParsedNutrientRow],
        resolvedTopology: FDALabelTopology,
        isSupplement: Bool,
        defaultServing: ParsedServingSize?,
        servingLineText: String,
        containerLineText: String?,
        insignificant: Set<CanonicalNutrientID>,
        allLines: [String],
        fallbackCaloriesValue: Int?
    ) -> [ScannedColumnCandidate] {
        guard let info = multiColumnInfo, info.columns.count >= 2 else {
            let singleHeader = multiColumnInfo?.columns.first?.headerTitle ?? "Per Serving"
            let singleServing: ParsedServingSize?
            if let overrideLine = multiColumnInfo?.columns.first?.servingSizeTranscript,
               overrideLine != servingLineText,
               let parsedOverride = FDALexicalNormalizer.parseServingSize(
                   from: overrideLine,
                   servingsPerContainerText: containerLineText,
                   isSupplement: isSupplement
               ) {
                singleServing = parsedOverride
            } else {
                singleServing = defaultServing
            }
            let singlePayload = FDANutritionValidator.buildPayload(
                topology: resolvedTopology,
                servingSize: singleServing,
                rows: primaryNutrientRows,
                insignificantNutrients: insignificant,
                rawPanelTexts: allLines,
                selectedColumnIndex: 0
            )
            return [
                ScannedColumnCandidate(
                    columnIndex: 0,
                    headerTitle: singleHeader,
                    servingSizeText: multiColumnInfo?.columns.first?.servingSizeTranscript,
                    isIncludedByDefault: true,
                    payload: singlePayload
                )
            ]
        }

        let validMultiRows = info.allColumnRows.filter { row in
            let line = row.rawCells.joined(separator: " ")
            return !FDALexicalNormalizer.isMandatoryBoxedWarning(line)
                && !FDALexicalNormalizer.isDecoyComparativeString(line)
        }

        var allColumnNutrientRows: [ParsedNutrientRow] = validMultiRows.flatMap { rawRow -> [ParsedNutrientRow] in
            let parsed = FDALexicalNormalizer.parseNutrientRow(
                cells: rawRow.rawCells,
                isSupplement: isSupplement,
                defaultColumnIndex: rawRow.columnIndex
            )
            if !parsed.isEmpty {
                return parsed
            }
            return FDALexicalNormalizer.parseNutrientRow(
                cells: [rawRow.combinedTranscript],
                isSupplement: isSupplement,
                defaultColumnIndex: rawRow.columnIndex
            )
        }

        // Merge any spatial-only rows from `primaryNutrientRows` into column 0 if missing.
        let col0Nutrients = Set(allColumnNutrientRows.filter { $0.columnIndex == 0 }.map(\.nutrient))
        for pRow in primaryNutrientRows where pRow.columnIndex == 0 && !col0Nutrients.contains(pRow.nutrient) {
            allColumnNutrientRows.append(pRow)
        }

        return info.columns.map { colMeta in
            let rawIdx = colMeta.rawPairIndex
            var rowsForBuild = allColumnNutrientRows

            let hasColCalories = rowsForBuild.contains {
                $0.nutrient == .calories && $0.columnIndex == rawIdx
            }
            if !hasColCalories, let calVal = colMeta.caloriesValue ?? fallbackCaloriesValue {
                rowsForBuild.insert(
                    ParsedNutrientRow(
                        nutrient: .calories,
                        rawName: "Calories",
                        amount: .exact(value: Double(calVal), unit: .kcal, secondaryValue: nil, secondaryUnit: nil),
                        percentDV: .omitted,
                        indentationLevel: .level0,
                        sourceCompoundDescription: nil,
                        columnIndex: rawIdx
                    ),
                    at: 0
                )
            }

            let colServing: ParsedServingSize?
            if let overrideServingLine = colMeta.servingSizeTranscript,
               !overrideServingLine.isEmpty,
               let parsedOverride = FDALexicalNormalizer.parseServingSize(
                   from: overrideServingLine,
                   servingsPerContainerText: containerLineText,
                   isSupplement: isSupplement
               ) {
                colServing = parsedOverride
            } else {
                colServing = defaultServing
            }

            let colPayload = FDANutritionValidator.buildPayload(
                topology: resolvedTopology,
                servingSize: colServing,
                rows: rowsForBuild,
                insignificantNutrients: insignificant,
                rawPanelTexts: allLines,
                selectedColumnIndex: rawIdx
            )

            return ScannedColumnCandidate(
                columnIndex: colMeta.columnIndex,
                headerTitle: colMeta.headerTitle,
                servingSizeText: colMeta.servingSizeTranscript,
                isIncludedByDefault: true,
                payload: colPayload
            )
        }
    }

    private static func buildFieldOrigins(
        parsedServing: ParsedServingSize?,
        payload: ScannedNutritionPayload
    ) -> [String: ScannedValueOrigin] {
        var origins: [String: ScannedValueOrigin] = [:]

        if let serving = parsedServing {
            origins[ScannerVerifiableField.servingSize.rawValue] = serving.usedMetricFallbackConversion
                ? .metricFallbackConversion
                : .scannedExact
            origins[ScannerVerifiableField.servingUnit.rawValue] = .scannedExact
        } else {
            origins[ScannerVerifiableField.servingSize.rawValue] = .fallbackDefaultServing
        }

        let fieldNutrientPairs: [(ScannerVerifiableField, CanonicalNutrientID)] = [
            (.calories, .calories),
            (.fat, .totalFat),
            (.saturatedFat, .saturatedFat),
            (.transFat, .transFat),
            (.carb, .totalCarbohydrate),
            (.dietaryFiber, .dietaryFiber),
            (.addedSugar, .addedSugars),
            (.protein, .protein)
        ]

        for (field, nutrientID) in fieldNutrientPairs {
            if payload.healedNutrients.contains(nutrientID) {
                origins[field.rawValue] = .healedFromPercentDV
                continue
            }
            guard let declared = payload.allParsedNutrients[nutrientID] else {
                origins[field.rawValue] = .notDetectedInjectedZero
                continue
            }
            switch declared {
            case .omitted:
                origins[field.rawValue] = .notDetectedInjectedZero
            case .explicitZero:
                origins[field.rawValue] = .scannedExplicitZero
            case .threshold:
                origins[field.rawValue] = .thresholdDeclaration
            case .insignificantFootnote:
                origins[field.rawValue] = .insignificantFootnote
            case .exact(let val, _, _, _):
                origins[field.rawValue] = (val == 0.0) ? .scannedExplicitZero : .scannedExact
            }
        }

        return origins
    }

    // MARK: - Hybrid Table + Spatial Row Extraction

    private static func extractAndMergeRows(
        from snapshot: ScannedDocumentSnapshot,
        classified: FDAClassifiedLabel
    ) -> (rows: [RawExtractedRow], extractionPath: ScanExtractionPath) {
        // Case 1: Linear Display (`Topology L`) -> use spatial / linear stitcher directly.
        if classified.topology == .linearString {
            let rows = VisionSpatialRowStitcher.stitchRows(from: snapshot, classifiedLabel: classified)
            return (rows, .linearDisplayStitcher)
        }

        // Case 2: Primary 2D Table Grid exists -> unpack via Milestone 4.3 `VisionTableRowExtractor`.
        if let primaryTable = classified.primaryTable {
            let tableRows = VisionTableRowExtractor.extractRows(
                from: primaryTable,
                classifiedLabel: classified
            )

            // Supplement 2D table rows with spatial row stitching whenever non-table text blocks exist on single-column panels,
            // recovering any rows split across thick bars or right-edge `% DV` tokens that fell outside a curved table cell.
            let isMultiColumnPanel = classified.topology.isMultiColumn || classified.topology == .tabularDualColumn || primaryTable.columnCount >= 4
            let hasExtraBlocks = !classified.attachedBodyBlocks.isEmpty || !classified.attachedSidebarBlocks.isEmpty || !snapshot.textBlocks.isEmpty

            if hasExtraBlocks && !isMultiColumnPanel {
                let spatialRows = VisionSpatialRowStitcher.stitchRows(
                    from: snapshot,
                    classifiedLabel: classified
                )
                let merged = mergeTableAndSpatialRows(tableRows: tableRows, spatialRows: spatialRows)
                let usedHybrid = merged.count > tableRows.count
                return (merged, usedHybrid ? .hybridTableAndSpatialMerge : .tableGrid2D)
            }

            return (tableRows, .tableGrid2D)
        }

        // Case 3: No 2D Table Grid detected -> fallback to Milestone 4.4 `VisionSpatialRowStitcher`.
        let rows = VisionSpatialRowStitcher.stitchRows(from: snapshot, classifiedLabel: classified)
        return (rows, .spatialStitcher)
    }

    private static func mergeTableAndSpatialRows(
        tableRows: [RawExtractedRow],
        spatialRows: [RawExtractedRow]
    ) -> [RawExtractedRow] {
        var merged = tableRows
        var indexByNutrient: [CanonicalNutrientID: Int] = [:]
        for (idx, row) in merged.enumerated() {
            if let nutrient = FDALexicalNormalizer.resolveNutrientID(from: row.nutrientLabelTranscript)
                ?? FDALexicalNormalizer.resolveNutrientID(from: row.combinedTranscript),
               indexByNutrient[nutrient] == nil {
                indexByNutrient[nutrient] = idx
            }
        }

        for spatialRow in spatialRows {
            guard let nutrient = FDALexicalNormalizer.resolveNutrientID(from: spatialRow.nutrientLabelTranscript)
                ?? FDALexicalNormalizer.resolveNutrientID(from: spatialRow.combinedTranscript) else {
                continue
            }
            if let existingIdx = indexByNutrient[nutrient] {
                // If the table row missed a right-edge `% DV` token on a curved package (e.g., "Potassium 140mg" missing "2%"),
                // backfill the `% DV` cell from the spatially stitched row.
                let existing = merged[existingIdx]
                if existing.percentDVTranscript.isEmpty && !spatialRow.percentDVTranscript.isEmpty {
                    var updatedCells = existing.rawCells
                    if !updatedCells.contains(spatialRow.percentDVTranscript) {
                        updatedCells.append(spatialRow.percentDVTranscript)
                    }
                    merged[existingIdx] = RawExtractedRow(
                        nutrientLabelTranscript: existing.nutrientLabelTranscript,
                        weightTranscript: existing.weightTranscript.isEmpty ? spatialRow.weightTranscript : existing.weightTranscript,
                        percentDVTranscript: spatialRow.percentDVTranscript,
                        rawCells: updatedCells,
                        minX: existing.minX,
                        midY: existing.midY,
                        boundingBox: existing.boundingBox.union(spatialRow.boundingBox),
                        indentationLevel: existing.indentationLevel,
                        columnIndex: existing.columnIndex,
                        isHeaderOrFooter: existing.isHeaderOrFooter
                    )
                }
            } else {
                indexByNutrient[nutrient] = merged.count
                merged.append(spatialRow)
            }
        }
        return merged
    }

    // MARK: - Topology & Serving Line Resolution Helpers

    private static func reconcileTopology(
        structural: FDALabelTopology,
        lexical: FDALabelTopology,
        isSupplementFlag: Bool
    ) -> FDALabelTopology {
        if isSupplementFlag || structural == .supplementFacts || lexical == .supplementFacts {
            return .supplementFacts
        }
        if structural != .standardVertical {
            return structural
        }
        return lexical
    }

    private static func resolveServingAndContainerLines(
        classified: FDAClassifiedLabel,
        allLines: [String]
    ) -> (servingLine: String, containerLine: String?) {
        var servingLine = classified.servingSizeTranscript ?? ""
        var containerLine = classified.servingsPerContainerTranscript

        if servingLine.isEmpty {
            for line in allLines {
                let expanded = FDALexicalNormalizer.expandAuthorizedAbbreviations(line).lowercased()
                if expanded.contains("serving size") {
                    servingLine = line
                    break
                }
            }
        }

        if containerLine == nil {
            for line in allLines {
                let expanded = FDALexicalNormalizer.expandAuthorizedAbbreviations(line).lowercased()
                if expanded.contains("servings per container")
                    || expanded.contains("serving per container")
                    || expanded.contains("servings:") {
                    containerLine = line
                    break
                }
            }
        }

        // If servingLine is still empty, pass the combined header lines so `FDALexicalNormalizer.parseServingSize` can inspect them.
        if servingLine.isEmpty {
            servingLine = allLines.prefix(5).joined(separator: " ")
        }

        return (servingLine, containerLine)
    }
}
