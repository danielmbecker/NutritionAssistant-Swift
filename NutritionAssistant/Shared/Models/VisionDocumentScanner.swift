//
//  VisionDocumentScanner.swift
//  NutritionAssistant
//
//  Milestone 4.1: Modern Vision Adapter & Defensive Filter
//
//  Verified Modern Vision API Document Citations (Docs/Vision/Vision_Modern_Documentation.md):
//  - vision/recognizedocumentsrequest (RecognizeDocumentsRequest, iOS 26.0+)
//  - vision/recognizedocumentsrequest/init(_:) (init(_ revision: RecognizeDocumentsRequest.Revision? = nil), iOS 26.0+)
//  - vision/recognizedocumentsrequest/textrecognitionoptions-swift.struct (TextRecognitionOptions, iOS 26.0+)
//  - vision/recognizedocumentsrequest/barcodedetectionoptions-swift.struct (BarcodeDetectionOptions, iOS 26.0+)
//  - vision/imageprocessingrequest (ImageProcessingRequest, iOS 18.0+)
//  - vision/imageprocessingrequest/perform(on:orientation:)-3f3f1 (perform(on data: Data, orientation: CGImagePropertyOrientation?), iOS 18.0+)
//  - vision/imageprocessingrequest/perform(on:orientation:)-qxxx (perform(on image: CGImage, orientation: CGImagePropertyOrientation?), iOS 18.0+)
//  - vision/imagerequesthandler (ImageRequestHandler, iOS 18.0+)
//  - vision/documentobservation (DocumentObservation, iOS 26.0+)
//  - vision/documentobservation/container (DocumentObservation.Container, iOS 26.0+)
//  - vision/documentobservation/container/table (DocumentObservation.Container.Table, iOS 26.0+)
//  - vision/documentobservation/container/table/cell (DocumentObservation.Container.Table.Cell, iOS 26.0+)
//  - vision/documentobservation/container/list (DocumentObservation.Container.List, iOS 26.0+)
//  - vision/documentobservation/container/list/item (DocumentObservation.Container.List.Item, iOS 26.0+)
//  - vision/documentobservation/container/text-swift.struct (DocumentObservation.Container.Text, iOS 26.0+)
//  - vision/recognizedtextobservation (RecognizedTextObservation, iOS 18.0+)
//  - vision/normalizedregion (typealias NormalizedRegion = ContoursObservation.Contour, iOS 26.0+)
//  - vision/contoursobservation/contour (ContoursObservation.Contour, boundingBox: NormalizedRect, boundingQuad: RectangleObservation, iOS 18.0+)
//  - vision/rectangleobservation (RectangleObservation, conformsTo: QuadrilateralProviding, iOS 18.0+)
//  - vision/quadrilateralproviding (QuadrilateralProviding, topLeft/topRight/bottomRight/bottomLeft: NormalizedPoint, iOS 18.0+)
//  - vision/normalizedpoint (NormalizedPoint, cgPoint: CGPoint, verticallyFlipped() -> NormalizedPoint, iOS 18.0+)
//  - vision/normalizedrect (NormalizedRect, cgRect: CGRect, verticallyFlipped() -> NormalizedRect, iOS 18.0+)
//  - vision/boundingregionproviding (BoundingRegionProviding, boundingRegion: NormalizedRegion, iOS 26.0+)
//  - vision/boundingboxproviding (BoundingBoxProviding, boundingBox: NormalizedRect, iOS 18.0+)
//

import CoreGraphics
import Foundation
import ImageIO
import Vision

// MARK: - Scan Errors

enum VisionDocumentScanError: LocalizedError, Sendable, Equatable {
    case invalidImageData
    case noDocumentDetected
    case legitimateExemptionDetected(FDALegitimateExemptionKind)
    case emptyLabelContent

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The captured image data could not be read for document scanning."
        case .noDocumentDetected:
            return "No nutrition or supplement document structure was detected in the image."
        case .legitimateExemptionDetected(let kind):
            switch kind {
            case .multiunitNotLabeledForRetailSale:
                return "This inner package is exempt from FDA nutrition labeling (\"This Unit Not Labeled For Retail Sale\"). Scan the outer retail container."
            case .smallPackageContactString:
                return "This small package is exempt from an on-pack Nutrition Facts panel under 21 CFR § 101.9(j)(13) and provides contact information instead."
            }
        case .emptyLabelContent:
            return "No valid nutrition or supplement facts content remained after filtering boxed warnings and relative claim statements."
        }
    }
}

// MARK: - Normalized Spatial Snapshot Types (Top-Left Origin [0, 1])

/// A single recognized word token within a text line, normalized to an upper-left origin `[0, 1]` coordinate space.
struct ScannedWordToken: Codable, Sendable, Equatable, Hashable {
    let transcript: String
    let boundingBox: CGRect

    var minX: CGFloat { boundingBox.minX }
    var midX: CGFloat { boundingBox.midX }
    var maxX: CGFloat { boundingBox.maxX }
    var minY: CGFloat { boundingBox.minY }
    var midY: CGFloat { boundingBox.midY }
    var maxY: CGFloat { boundingBox.maxY }
    var width: CGFloat { boundingBox.width }
    var height: CGFloat { boundingBox.height }

    init(transcript: String, boundingBox: CGRect) {
        self.transcript = transcript
        self.boundingBox = boundingBox
    }
}

/// A single recognized line of text with its normalized top-left bounding box and constituent word tokens.
struct ScannedTextLine: Codable, Sendable, Equatable, Hashable {
    let transcript: String
    let boundingBox: CGRect
    let isTitle: Bool
    let shouldWrapToNextLine: Bool?
    let words: [ScannedWordToken]

    var minX: CGFloat { boundingBox.minX }
    var midX: CGFloat { boundingBox.midX }
    var maxX: CGFloat { boundingBox.maxX }
    var minY: CGFloat { boundingBox.minY }
    var midY: CGFloat { boundingBox.midY }
    var maxY: CGFloat { boundingBox.maxY }
    var width: CGFloat { boundingBox.width }
    var height: CGFloat { boundingBox.height }

    init(
        transcript: String,
        boundingBox: CGRect,
        isTitle: Bool = false,
        shouldWrapToNextLine: Bool? = nil,
        words: [ScannedWordToken] = []
    ) {
        self.transcript = transcript
        self.boundingBox = boundingBox
        self.isTitle = isTitle
        self.shouldWrapToNextLine = shouldWrapToNextLine
        self.words = words
    }
}

/// A Vision-decoupled paragraph or standalone text block in normalized top-left `[0, 1]` coordinates.
struct ScannedTextBlock: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: UUID
    let transcript: String
    let boundingBox: CGRect
    let isTitle: Bool
    let lines: [ScannedTextLine]

    var minX: CGFloat { boundingBox.minX }
    var midX: CGFloat { boundingBox.midX }
    var maxX: CGFloat { boundingBox.maxX }
    var minY: CGFloat { boundingBox.minY }
    var midY: CGFloat { boundingBox.midY }
    var maxY: CGFloat { boundingBox.maxY }
    var width: CGFloat { boundingBox.width }
    var height: CGFloat { boundingBox.height }

    init(
        id: UUID = UUID(),
        transcript: String,
        boundingBox: CGRect,
        isTitle: Bool = false,
        lines: [ScannedTextLine] = []
    ) {
        self.id = id
        self.transcript = transcript
        self.boundingBox = boundingBox
        self.isTitle = isTitle
        self.lines = lines
    }
}

/// A Vision-decoupled table cell preserving 2D grid spans (`rowRange`, `columnRange`), transcript, and normalized geometry.
struct ScannedTableCell: Codable, Sendable, Equatable, Hashable {
    let rowRange: ClosedRange<Int>
    let columnRange: ClosedRange<Int>
    let transcript: String
    let boundingBox: CGRect
    let paragraphs: [ScannedTextBlock]
    let lines: [ScannedTextLine]

    var minX: CGFloat { boundingBox.minX }
    var midX: CGFloat { boundingBox.midX }
    var maxX: CGFloat { boundingBox.maxX }
    var minY: CGFloat { boundingBox.minY }
    var midY: CGFloat { boundingBox.midY }
    var maxY: CGFloat { boundingBox.maxY }
    var width: CGFloat { boundingBox.width }
    var height: CGFloat { boundingBox.height }

    var rowSpan: Int { rowRange.count }
    var columnSpan: Int { columnRange.count }

    init(
        rowRange: ClosedRange<Int>,
        columnRange: ClosedRange<Int>,
        transcript: String,
        boundingBox: CGRect,
        paragraphs: [ScannedTextBlock] = [],
        lines: [ScannedTextLine] = []
    ) {
        self.rowRange = rowRange
        self.columnRange = columnRange
        self.transcript = transcript
        self.boundingBox = boundingBox
        self.paragraphs = paragraphs
        self.lines = lines
    }
}

/// A Vision-decoupled 2D table grid with normalized geometry and span-aware cell lookup.
struct ScannedTableGrid: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: UUID
    let boundingBox: CGRect
    let rows: [[ScannedTableCell]]
    let columns: [[ScannedTableCell]]
    let rowCount: Int
    let columnCount: Int

    var minX: CGFloat { boundingBox.minX }
    var midX: CGFloat { boundingBox.midX }
    var maxX: CGFloat { boundingBox.maxX }
    var minY: CGFloat { boundingBox.minY }
    var midY: CGFloat { boundingBox.midY }
    var maxY: CGFloat { boundingBox.maxY }
    var width: CGFloat { boundingBox.width }
    var height: CGFloat { boundingBox.height }

    /// Deduplicated cells ordered top-to-bottom by `rowRange.lowerBound`, then left-to-right by `columnRange.lowerBound`.
    var allUniqueCells: [ScannedTableCell] {
        var seenSpans = Set<String>()
        var result: [ScannedTableCell] = []
        for row in rows {
            for cell in row {
                let key = "\(cell.rowRange.lowerBound)-\(cell.rowRange.upperBound):\(cell.columnRange.lowerBound)-\(cell.columnRange.upperBound):\(cell.transcript)"
                if seenSpans.insert(key).inserted {
                    result.append(cell)
                }
            }
        }
        return result.sorted { lhs, rhs in
            if lhs.rowRange.lowerBound != rhs.rowRange.lowerBound {
                return lhs.rowRange.lowerBound < rhs.rowRange.lowerBound
            }
            return lhs.columnRange.lowerBound < rhs.columnRange.lowerBound
        }
    }

    init(
        id: UUID = UUID(),
        boundingBox: CGRect,
        rows: [[ScannedTableCell]],
        columns: [[ScannedTableCell]] = []
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.rows = rows
        self.columns = columns

        let maxRowIndex = rows.flatMap { $0 }.map(\.rowRange.upperBound).max()
        let maxColIndex = rows.flatMap { $0 }.map(\.columnRange.upperBound).max()
        self.rowCount = max(rows.count, (maxRowIndex ?? -1) + 1)
        self.columnCount = max(columns.count, (maxColIndex ?? -1) + 1)
    }

    /// Returns the cell covering the specified `(row, column)` grid coordinate, if present.
    func cell(row: Int, column: Int) -> ScannedTableCell? {
        for tableRow in rows {
            for candidate in tableRow where candidate.rowRange.contains(row) && candidate.columnRange.contains(column) {
                return candidate
            }
        }
        return nil
    }
}

/// Complete Vision-decoupled snapshot of a scanned document after defensive Subpart D decoy and `§ 101.17` warning filtering.
struct ScannedDocumentSnapshot: Codable, Sendable, Equatable, Hashable {
    let uuid: UUID
    let confidence: Float
    let boundingBox: CGRect
    let quadCorners: [CGPoint]
    let title: ScannedTextBlock?
    let tables: [ScannedTableGrid]
    let textBlocks: [ScannedTextBlock]
    let detectedExemptions: [FDALegitimateExemptionKind]
    let discardedWarningCount: Int
    let discardedDecoyCount: Int

    init(
        uuid: UUID = UUID(),
        confidence: Float = 1.0,
        boundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1),
        quadCorners: [CGPoint] = [],
        title: ScannedTextBlock? = nil,
        tables: [ScannedTableGrid] = [],
        textBlocks: [ScannedTextBlock] = [],
        detectedExemptions: [FDALegitimateExemptionKind] = [],
        discardedWarningCount: Int = 0,
        discardedDecoyCount: Int = 0
    ) {
        self.uuid = uuid
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.quadCorners = quadCorners
        self.title = title
        self.tables = tables
        self.textBlocks = textBlocks
        self.detectedExemptions = detectedExemptions
        self.discardedWarningCount = discardedWarningCount
        self.discardedDecoyCount = discardedDecoyCount
    }
}

// MARK: - Modern Vision Document Scanner

enum VisionDocumentScanner {

    /// Domain-specific vocabulary injected into `RecognizeDocumentsRequest.TextRecognitionOptions.customWords`
    /// (`vision/recognizedocumentsrequest/textrecognitionoptions-swift.struct/customwords`).
    static let fdaCustomRecognitionWords: [String] = [
        "Nutrition Facts",
        "Supplement Facts",
        "Servings per container",
        "Serving size",
        "Amount per serving",
        "Amount/serving",
        "% Daily Value",
        "% DV",
        "Calories",
        "Total Fat",
        "Saturated Fat",
        "Sat. Fat",
        "Trans Fat",
        "Polyunsaturated Fat",
        "Monounsaturated Fat",
        "Cholesterol",
        "Cholest.",
        "Sodium",
        "Fluoride",
        "Total Carbohydrate",
        "Total Carb.",
        "Dietary Fiber",
        "Soluble Fiber",
        "Insoluble Fiber",
        "Total Sugars",
        "Added Sugars",
        "Incl. Added Sugars",
        "Sugar Alcohol",
        "Erythritol",
        "Xylitol",
        "Sorbitol",
        "Maltitol",
        "Protein",
        "Vitamin D",
        "Calcium",
        "Iron",
        "Potassium",
        "Potas.",
        "Thiamin",
        "Riboflavin",
        "Niacin",
        "Folate",
        "Folic Acid",
        "Biotin",
        "Pantothenic Acid",
        "Phosphorus",
        "Iodine",
        "Magnesium",
        "Zinc",
        "Selenium",
        "Copper",
        "Manganese",
        "Chromium",
        "Molybdenum",
        "Chloride",
        "Choline",
        "Proprietary Blend",
        "mcg DFE",
        "mcg RAE",
        "mg NE"
    ]

    /// Creates and configures a modern `RecognizeDocumentsRequest` (`vision/recognizedocumentsrequest`)
    /// optimized for FDA Nutrition Facts and Supplement Facts typography.
    static func configuredRequest() -> RecognizeDocumentsRequest {
        var request = RecognizeDocumentsRequest()
        request.barcodeDetectionOptions.enabled = false
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        request.textRecognitionOptions.useLanguageCorrection = true
        request.textRecognitionOptions.customWords = fdaCustomRecognitionWords
        request.textRecognitionOptions.minimumTextHeightFraction = 0.008
        return request
    }

    /// Executes `RecognizeDocumentsRequest` asynchronously on raw image `Data`
    /// (`vision/imageprocessingrequest/perform(on:orientation:)-3f3f1`) and returns a defensibly filtered `ScannedDocumentSnapshot`.
    static func scan(
        imageData: Data,
        orientation: CGImagePropertyOrientation? = nil
    ) async throws -> ScannedDocumentSnapshot {
        guard !imageData.isEmpty else {
            throw VisionDocumentScanError.invalidImageData
        }

        let request = configuredRequest()
        let observations = try await request.perform(on: imageData, orientation: orientation)
        return try mergeAndValidateObservations(observations)
    }

    /// Executes `RecognizeDocumentsRequest` asynchronously on a `CGImage`
    /// (`vision/imageprocessingrequest/perform(on:orientation:)-qxxx`) and returns a defensibly filtered `ScannedDocumentSnapshot`.
    static func scan(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation? = nil
    ) async throws -> ScannedDocumentSnapshot {
        let request = configuredRequest()
        let observations = try await request.perform(on: cgImage, orientation: orientation)
        return try mergeAndValidateObservations(observations)
    }

    // MARK: - Observation Conversion & Defensive Filtering

    /// Converts and merges `[DocumentObservation]` (`vision/documentobservation`) into a single `ScannedDocumentSnapshot`,
    /// enforcing Subpart D decoy filtering (`Part 5.2`) and `§ 101.17` hairline-boxed warning rejection (`Part 6.5`).
    static func mergeAndValidateObservations(
        _ observations: [DocumentObservation]
    ) throws -> ScannedDocumentSnapshot {
        guard !observations.isEmpty else {
            throw VisionDocumentScanError.noDocumentDetected
        }

        var allTables: [ScannedTableGrid] = []
        var allTextBlocks: [ScannedTextBlock] = []
        var detectedExemptions: [FDALegitimateExemptionKind] = []
        var bestTitle: ScannedTextBlock?
        var primaryQuadCorners: [CGPoint] = []
        var totalConfidence: Float = 0
        var unionBox: CGRect?
        var warningCount = 0
        var decoyCount = 0

        for observation in observations {
            let single = convertObservation(observation)
            totalConfidence += single.confidence
            unionBox = unionBox.map { $0.union(single.boundingBox) } ?? single.boundingBox
            if primaryQuadCorners.isEmpty && single.quadCorners.count == 4 {
                primaryQuadCorners = single.quadCorners
            }
            if bestTitle == nil, let title = single.title {
                bestTitle = title
            }
            allTables.append(contentsOf: single.tables)
            allTextBlocks.append(contentsOf: single.textBlocks)
            for exemption in single.detectedExemptions where !detectedExemptions.contains(exemption) {
                detectedExemptions.append(exemption)
            }
            warningCount += single.discardedWarningCount
            decoyCount += single.discardedDecoyCount
        }

        let sortedTextBlocks = sortTextBlocksTopToBottom(deduplicateTextBlocks(allTextBlocks))
        let averageConfidence = totalConfidence / Float(observations.count)

        if allTables.isEmpty && sortedTextBlocks.isEmpty {
            if let firstExemption = detectedExemptions.first {
                throw VisionDocumentScanError.legitimateExemptionDetected(firstExemption)
            }
            throw VisionDocumentScanError.emptyLabelContent
        }

        return ScannedDocumentSnapshot(
            uuid: observations[0].uuid,
            confidence: averageConfidence,
            boundingBox: unionBox ?? CGRect(x: 0, y: 0, width: 1, height: 1),
            quadCorners: primaryQuadCorners,
            title: bestTitle,
            tables: allTables,
            textBlocks: sortedTextBlocks,
            detectedExemptions: detectedExemptions,
            discardedWarningCount: warningCount,
            discardedDecoyCount: decoyCount
        )
    }

    /// Converts a single `DocumentObservation` (`vision/documentobservation`) into a `ScannedDocumentSnapshot`.
    static func convertObservation(_ observation: DocumentObservation) -> ScannedDocumentSnapshot {
        let container = observation.document
        let containerRect = topLeftNormalizedRect(from: container.boundingRegion)
        let primaryRegionForQuad = container.tables.first?.boundingRegion ?? container.boundingRegion
        let quadCorners = topLeftNormalizedQuadCorners(from: primaryRegionForQuad)

        var exemptions: [FDALegitimateExemptionKind] = []
        var discardedWarnings = 0
        var discardedDecoys = 0

        let fullTranscript = container.text.transcript
        if let exemption = FDALexicalNormalizer.detectLegitimateExemption(fullTranscript) {
            exemptions.append(exemption)
        }

        // Convert optional document title if it passes defensive filters.
        var convertedTitle: ScannedTextBlock?
        if let rawTitle = container.title {
            if let filteredTitle = convertAndFilterTextContainer(
                rawTitle,
                forceTitleFlag: true,
                exemptions: &exemptions,
                discardedWarnings: &discardedWarnings,
                discardedDecoys: &discardedDecoys
            ) {
                convertedTitle = filteredTitle
            }
        }

        // Convert and defensively filter tables (rejecting § 101.17 hairline-boxed warnings and Subpart D decoy boxes).
        var survivingTables: [ScannedTableGrid] = []
        for rawTable in container.tables {
            if let filteredTable = convertAndFilterTable(
                rawTable,
                exemptions: &exemptions,
                discardedWarnings: &discardedWarnings,
                discardedDecoys: &discardedDecoys
            ) {
                survivingTables.append(filteredTable)
            }
        }

        // Convert and defensively filter standalone paragraphs.
        var survivingParagraphs: [ScannedTextBlock] = []
        for rawParagraph in container.paragraphs {
            if let block = convertAndFilterTextContainer(
                rawParagraph,
                forceTitleFlag: false,
                exemptions: &exemptions,
                discardedWarnings: &discardedWarnings,
                discardedDecoys: &discardedDecoys
            ) {
                survivingParagraphs.append(block)
            }
        }

        // Also inspect list items if Vision grouped bulleted micronutrients or linear rows into `container.lists`.
        for rawList in container.lists {
            for item in rawList.items {
                if let listBlock = convertAndFilterTextContainer(
                    item.content.text,
                    forceTitleFlag: false,
                    exemptions: &exemptions,
                    discardedWarnings: &discardedWarnings,
                    discardedDecoys: &discardedDecoys
                ) {
                    survivingParagraphs.append(listBlock)
                }
            }
        }

        // Fallback to container.text if paragraphs are empty but container.text has surviving lines.
        if survivingParagraphs.isEmpty {
            if let rootBlock = convertAndFilterTextContainer(
                container.text,
                forceTitleFlag: false,
                exemptions: &exemptions,
                discardedWarnings: &discardedWarnings,
                discardedDecoys: &discardedDecoys
            ) {
                survivingParagraphs.append(rootBlock)
            }
        }

        let uniqueBlocks = sortTextBlocksTopToBottom(deduplicateTextBlocks(survivingParagraphs))

        return ScannedDocumentSnapshot(
            uuid: observation.uuid,
            confidence: observation.confidence,
            boundingBox: containerRect,
            quadCorners: quadCorners,
            title: convertedTitle,
            tables: survivingTables,
            textBlocks: uniqueBlocks,
            detectedExemptions: exemptions,
            discardedWarningCount: discardedWarnings,
            discardedDecoyCount: discardedDecoys
        )
    }

    // MARK: - Table & Paragraph Defensive Filtering Helpers

    private static func convertAndFilterTable(
        _ table: DocumentObservation.Container.Table,
        exemptions: inout [FDALegitimateExemptionKind],
        discardedWarnings: inout Int,
        discardedDecoys: inout Int
    ) -> ScannedTableGrid? {
        let tableRect = topLeftNormalizedRect(from: table.boundingRegion)

        // Aggregate all cell transcripts to check if the entire hairline box is a § 101.17 warning box.
        let allCellTranscripts = table.rows
            .flatMap { $0 }
            .map { $0.content.text.transcript.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let combinedTableText = allCellTranscripts.joined(separator: " ")

        if let exemption = FDALexicalNormalizer.detectLegitimateExemption(combinedTableText),
           !exemptions.contains(exemption) {
            exemptions.append(exemption)
        }

        if FDALexicalNormalizer.isMandatoryBoxedWarning(combinedTableText) {
            discardedWarnings += 1
            return nil
        }

        // If the entire table consists solely of a Subpart D decoy comparison and lacks a Nutrition/Supplement header, discard it.
        let lowerCombined = combinedTableText.lowercased()
        let hasPanelTitle = lowerCombined.contains("nutrition facts")
            || lowerCombined.contains("supplement facts")
            || lowerCombined.contains("amount per serving")
            || lowerCombined.contains("amount/serving")
            || lowerCombined.contains("serving size")
            || lowerCombined.contains("serv. size")
        if !hasPanelTitle && FDALexicalNormalizer.isDecoyComparativeString(combinedTableText) {
            discardedDecoys += 1
            return nil
        }

        var convertedRows: [[ScannedTableCell]] = []
        for rawRow in table.rows {
            var convertedRowCells: [ScannedTableCell] = []
            for rawCell in rawRow {
                if let cell = convertAndFilterCell(
                    rawCell,
                    exemptions: &exemptions,
                    discardedWarnings: &discardedWarnings,
                    discardedDecoys: &discardedDecoys
                ) {
                    convertedRowCells.append(cell)
                }
            }
            if !convertedRowCells.isEmpty {
                convertedRows.append(convertedRowCells)
            }
        }

        guard !convertedRows.isEmpty else {
            return nil
        }

        var convertedColumns: [[ScannedTableCell]] = []
        for rawCol in table.columns {
            var convertedColCells: [ScannedTableCell] = []
            for rawCell in rawCol {
                if let cell = convertAndFilterCell(
                    rawCell,
                    exemptions: &exemptions,
                    discardedWarnings: &discardedWarnings,
                    discardedDecoys: &discardedDecoys
                ) {
                    convertedColCells.append(cell)
                }
            }
            if !convertedColCells.isEmpty {
                convertedColumns.append(convertedColCells)
            }
        }

        return ScannedTableGrid(
            boundingBox: tableRect,
            rows: convertedRows,
            columns: convertedColumns
        )
    }

    private static func convertAndFilterCell(
        _ cell: DocumentObservation.Container.Table.Cell,
        exemptions: inout [FDALegitimateExemptionKind],
        discardedWarnings: inout Int,
        discardedDecoys: inout Int
    ) -> ScannedTableCell? {
        let cellContainer = cell.content
        let cellRect = topLeftNormalizedRect(from: cellContainer.boundingRegion)
        let rawTranscript = cellContainer.text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        if let exemption = FDALexicalNormalizer.detectLegitimateExemption(rawTranscript),
           !exemptions.contains(exemption) {
            exemptions.append(exemption)
        }

        if !rawTranscript.isEmpty {
            if FDALexicalNormalizer.isMandatoryBoxedWarning(rawTranscript) {
                discardedWarnings += 1
                return nil
            }
            if FDALexicalNormalizer.isDecoyComparativeString(rawTranscript) {
                discardedDecoys += 1
                return nil
            }
        }

        var cellParagraphs: [ScannedTextBlock] = []
        for paragraph in cellContainer.paragraphs {
            if let converted = convertAndFilterTextContainer(
                paragraph,
                forceTitleFlag: false,
                exemptions: &exemptions,
                discardedWarnings: &discardedWarnings,
                discardedDecoys: &discardedDecoys
            ) {
                cellParagraphs.append(converted)
            }
        }

        let cellLines = convertAndFilterLines(
            cellContainer.text.lines,
            wordObservations: cellContainer.text.words ?? [],
            exemptions: &exemptions,
            discardedWarnings: &discardedWarnings,
            discardedDecoys: &discardedDecoys
        )

        let cleanedTranscript: String
        if !cellLines.isEmpty {
            cleanedTranscript = cellLines.map(\.transcript).joined(separator: "\n")
        } else if !cellParagraphs.isEmpty {
            cleanedTranscript = cellParagraphs.map(\.transcript).joined(separator: "\n")
        } else {
            cleanedTranscript = rawTranscript
        }

        return ScannedTableCell(
            rowRange: cell.rowRange,
            columnRange: cell.columnRange,
            transcript: cleanedTranscript,
            boundingBox: cellRect,
            paragraphs: cellParagraphs,
            lines: cellLines
        )
    }

    private static func convertAndFilterTextContainer(
        _ textContainer: DocumentObservation.Container.Text,
        forceTitleFlag: Bool,
        exemptions: inout [FDALegitimateExemptionKind],
        discardedWarnings: inout Int,
        discardedDecoys: inout Int
    ) -> ScannedTextBlock? {
        let rawTranscript = textContainer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawTranscript.isEmpty else {
            return nil
        }

        if let exemption = FDALexicalNormalizer.detectLegitimateExemption(rawTranscript),
           !exemptions.contains(exemption) {
            exemptions.append(exemption)
        }

        if FDALexicalNormalizer.isMandatoryBoxedWarning(rawTranscript) {
            discardedWarnings += 1
            return nil
        }

        if FDALexicalNormalizer.isDecoyComparativeString(rawTranscript) {
            discardedDecoys += 1
            return nil
        }

        let convertedLines = convertAndFilterLines(
            textContainer.lines,
            wordObservations: textContainer.words ?? [],
            exemptions: &exemptions,
            discardedWarnings: &discardedWarnings,
            discardedDecoys: &discardedDecoys
        )

        let survivingTranscript: String
        if !convertedLines.isEmpty {
            survivingTranscript = convertedLines.map(\.transcript).joined(separator: "\n")
        } else {
            // Filter line-by-line on plain text if Vision returned no line observations.
            let filteredPlainLines = rawTranscript
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { line in
                    guard !line.isEmpty else { return false }
                    if FDALexicalNormalizer.isMandatoryBoxedWarning(line) {
                        discardedWarnings += 1
                        return false
                    }
                    if FDALexicalNormalizer.isDecoyComparativeString(line) {
                        discardedDecoys += 1
                        return false
                    }
                    return true
                }
            guard !filteredPlainLines.isEmpty else {
                return nil
            }
            survivingTranscript = filteredPlainLines.joined(separator: "\n")
        }

        let blockRect = topLeftNormalizedRect(from: textContainer.boundingRegion)
        let isTitle = forceTitleFlag || convertedLines.contains(where: \.isTitle)

        return ScannedTextBlock(
            transcript: survivingTranscript,
            boundingBox: blockRect,
            isTitle: isTitle,
            lines: convertedLines
        )
    }

    private static func convertAndFilterLines(
        _ lines: [RecognizedTextObservation],
        wordObservations: [RecognizedTextObservation],
        exemptions: inout [FDALegitimateExemptionKind],
        discardedWarnings: inout Int,
        discardedDecoys: inout Int
    ) -> [ScannedTextLine] {
        let allWords: [ScannedWordToken] = wordObservations.compactMap { wordObs in
            let token = wordObs.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { return nil }
            let wordRect = topLeftNormalizedRect(from: wordObs.boundingBox)
            return ScannedWordToken(transcript: token, boundingBox: wordRect)
        }

        var result: [ScannedTextLine] = []
        for lineObs in lines {
            let lineText = lineObs.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !lineText.isEmpty else { continue }

            if let exemption = FDALexicalNormalizer.detectLegitimateExemption(lineText),
               !exemptions.contains(exemption) {
                exemptions.append(exemption)
            }

            if FDALexicalNormalizer.isMandatoryBoxedWarning(lineText) {
                discardedWarnings += 1
                continue
            }

            if FDALexicalNormalizer.isDecoyComparativeString(lineText) {
                discardedDecoys += 1
                continue
            }

            let lineRect = topLeftNormalizedRect(from: lineObs.boundingBox)
            let matchingWords = allWords
                .filter { word in
                    let verticalOverlap = min(lineRect.maxY, word.maxY) - max(lineRect.minY, word.minY)
                    let minHeight = max(0.0001, min(lineRect.height, word.height))
                    let horizontallyInside = word.midX >= (lineRect.minX - 0.01) && word.midX <= (lineRect.maxX + 0.01)
                    return horizontallyInside && (verticalOverlap / minHeight) >= 0.4
                }
                .sorted { $0.minX < $1.minX }

            result.append(
                ScannedTextLine(
                    transcript: lineText,
                    boundingBox: lineRect,
                    isTitle: lineObs.isTitle,
                    shouldWrapToNextLine: lineObs.shouldWrapToNextLine,
                    words: matchingWords
                )
            )
        }

        return result.sorted { lhs, rhs in
            if abs(lhs.midY - rhs.midY) > 0.004 {
                return lhs.midY < rhs.midY
            }
            return lhs.minX < rhs.minX
        }
    }

    // MARK: - Normalized Geometry & Deduplication Helpers

    /// Converts a Vision `NormalizedRegion` (`vision/normalizedregion`) from lower-left normalized coordinates
    /// to upper-left normalized `[0, 1]` coordinates (`vision/normalizedrect/verticallyflipped()`).
    static func topLeftNormalizedRect(from region: NormalizedRegion) -> CGRect {
        topLeftNormalizedRect(from: region.boundingBox)
    }

    /// Extracts the 4 bounding quadrilateral corners (`[topLeft, topRight, bottomRight, bottomLeft]`) from a Vision
    /// `NormalizedRegion` (`vision/contoursobservation/contour/boundingquad` & `vision/quadrilateralproviding`)
    /// in upper-left normalized `[0, 1]` coordinates (`vision/normalizedpoint/verticallyflipped()`).
    static func topLeftNormalizedQuadCorners(from region: NormalizedRegion) -> [CGPoint] {
        let quad = region.boundingQuad
        return [
            quad.topLeft.verticallyFlipped().cgPoint,
            quad.topRight.verticallyFlipped().cgPoint,
            quad.bottomRight.verticallyFlipped().cgPoint,
            quad.bottomLeft.verticallyFlipped().cgPoint
        ]
    }

    /// Converts a Vision `NormalizedRect` (`vision/normalizedrect`) from lower-left normalized coordinates
    /// to upper-left normalized `[0, 1]` coordinates (`y = 0` at top of image, `y = 1` at bottom).
    static func topLeftNormalizedRect(from normalizedRect: NormalizedRect) -> CGRect {
        normalizedRect.verticallyFlipped().cgRect
    }

    private static func deduplicateTextBlocks(_ blocks: [ScannedTextBlock]) -> [ScannedTextBlock] {
        var unique: [ScannedTextBlock] = []
        for candidate in blocks {
            let isDuplicate = unique.contains { existing in
                guard existing.transcript == candidate.transcript else { return false }
                let dx = abs(existing.midX - candidate.midX)
                let dy = abs(existing.midY - candidate.midY)
                return dx < 0.01 && dy < 0.01
            }
            if !isDuplicate {
                unique.append(candidate)
            }
        }
        return unique
    }

    private static func sortTextBlocksTopToBottom(_ blocks: [ScannedTextBlock]) -> [ScannedTextBlock] {
        blocks.sorted { lhs, rhs in
            if abs(lhs.midY - rhs.midY) > 0.008 {
                return lhs.midY < rhs.midY
            }
            return lhs.minX < rhs.minX
        }
    }
}
