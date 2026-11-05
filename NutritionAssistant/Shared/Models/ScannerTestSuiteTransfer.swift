//
//  ScannerTestSuiteTransfer.swift
//  NutritionAssistant
//
//  Milestone 5.4: Round-Trip Test Suite Export & Import Engine
//  Provides Codable serialization (ScannerTestSuiteArchive), SwiftUI FileDocument conformance
//  (ScannerTestSuiteDocument), and idempotent SwiftData merge import so test fixtures,
//  lossless PNG images, manual ground-truth corrections, and multi-run histories can be
//  exported and re-imported across devices and simulator sessions.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Portable Codable Archive Models

/// Root archive container for exporting and importing a complete `LabelScanningTests` corpus.
struct ScannerTestSuiteArchive: Codable, Sendable, Equatable {
    static let currentSchemaVersion: Int = 2

    let schemaVersion: Int
    let exportedAt: Date
    let items: [ExportedScannerTestItem]

    init(
        schemaVersion: Int = ScannerTestSuiteArchive.currentSchemaVersion,
        exportedAt: Date = Date(),
        items: [ExportedScannerTestItem]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.items = items
    }
}

/// Serializable representation of a parent `ScannerTestItem` fixture including its lossless image and run history.
struct ExportedScannerTestItem: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let labelTitle: String
    let notes: String?
    let originalImageData: Data
    let thumbnailData: Data?
    let runs: [ExportedScannerTestRun]
}

/// Serializable representation of a single `ScannerTestRun` execution, preserving all 14 parameter triplets
/// (`scanned*`, `status*Raw`, `corrected*`) and its full `ScanDiagnosticsSnapshot`.
struct ExportedScannerTestRun: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let runNumber: Int
    let timestamp: Date
    let runNotes: String?

    let scannedIsSupplement: Bool
    let statusIsSupplementRaw: String
    let correctedIsSupplement: Bool?

    let scannedServingSize: Double
    let statusServingSizeRaw: String
    let correctedServingSize: Double?

    let scannedServingUnit: String
    let statusServingUnitRaw: String
    let correctedServingUnit: String?

    let scannedHouseholdAmount: Double?
    let statusHouseholdAmountRaw: String
    let correctedHouseholdAmount: Double?
    let correctedHouseholdAmountIsNil: Bool

    let scannedHouseholdMeasurement: String?
    let statusHouseholdMeasurementRaw: String
    let correctedHouseholdMeasurement: String?
    let correctedHouseholdMeasurementIsNil: Bool

    let scannedCalories: Int
    let statusCaloriesRaw: String
    let correctedCalories: Int?

    let scannedFat: Double
    let statusFatRaw: String
    let correctedFat: Double?

    let scannedSaturatedFat: Double
    let statusSaturatedFatRaw: String
    let correctedSaturatedFat: Double?

    let scannedTransFat: Double
    let statusTransFatRaw: String
    let correctedTransFat: Double?

    let scannedCarb: Double
    let statusCarbRaw: String
    let correctedCarb: Double?

    let scannedDietaryFiber: Double
    let statusDietaryFiberRaw: String
    let correctedDietaryFiber: Double?

    let scannedAddedSugar: Double
    let statusAddedSugarRaw: String
    let correctedAddedSugar: Double?

    let scannedProtein: Double
    let statusProteinRaw: String
    let correctedProtein: Double?

    let scannedTopologyRaw: String
    let statusTopologyRaw: String
    let correctedTopologyRaw: String?

    let diagnostics: ScanDiagnosticsSnapshot
    var fullSpectrumVerification: FullSpectrumRunVerificationSnapshot? = nil
}

// MARK: - Import Summary & Errors

struct ScannerTestImportSummary: Sendable, Equatable {
    let importedItemsCount: Int
    let mergedExistingItemsCount: Int
    let importedRunsCount: Int
    let updatedExistingRunsCount: Int

    var summaryMessage: String {
        "Imported \(importedItemsCount) new test image(s), merged \(mergedExistingItemsCount) existing image(s), added \(importedRunsCount) test run(s), and updated \(updatedExistingRunsCount) run(s)."
    }
}

enum ScannerTestTransferError: LocalizedError, Sendable {
    case emptyArchiveData
    case unreadableSecurityScopedFile

    var errorDescription: String? {
        switch self {
        case .emptyArchiveData:
            return "The selected test suite archive file is empty."
        case .unreadableSecurityScopedFile:
            return "Could not access the selected file for import."
        }
    }
}

// MARK: - SwiftUI FileDocument Wrapper

/// Conforms to `SwiftUI.FileDocument` using raw `Data` storage so `nonisolated` `FileDocument`
/// protocol methods remain free of actor-isolation conflicts under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
struct ScannerTestSuiteDocument: FileDocument, Sendable {
    nonisolated static var readableContentTypes: [UTType] { [.json] }

    let jsonData: Data

    nonisolated init(jsonData: Data = Data()) {
        self.jsonData = jsonData
    }

    nonisolated init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.jsonData = data
    }

    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: jsonData)
    }
}

// MARK: - Export & Idempotent Merge Import Manager

enum ScannerTestSuiteTransferManager {

    /// Default filename incorporating the current date for `.fileExporter`.
    static func defaultExportFilename(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return "NutritionScannerTestSuite_\(formatter.string(from: date)).json"
    }

    /// Serializes an array of `ScannerTestItem` models (including lossless images, ground-truth corrections,
    /// and multi-run histories) into pretty-printed JSON `Data`.
    static func exportArchiveData(from items: [ScannerTestItem]) throws -> Data {
        let sortedItems = items.sorted { $0.createdAt < $1.createdAt }
        let exportedItems = sortedItems.map { makeExportedItem(from: $0) }
        let archive = ScannerTestSuiteArchive(items: exportedItems)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    /// Creates a `ScannerTestSuiteDocument` ready for SwiftUI's `.fileExporter`.
    static func makeExportDocument(from items: [ScannerTestItem]) throws -> ScannerTestSuiteDocument {
        let data = try exportArchiveData(from: items)
        return ScannerTestSuiteDocument(jsonData: data)
    }

    /// Reads a `.json` archive from a security-scoped `URL` returned by `.fileImporter` and merges it into `modelContext`.
    static func importArchive(
        from url: URL,
        into modelContext: ModelContext,
        existingItems: [ScannerTestItem]
    ) throws -> ScannerTestImportSummary {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        return try importArchive(
            from: data,
            into: modelContext,
            existingItems: existingItems
        )
    }

    /// Decodes a `ScannerTestSuiteArchive` from JSON `Data` and performs an idempotent merge into `modelContext`:
    /// - New `ScannerTestItem` fixtures are inserted along with all of their `ScannerTestRun` records.
    /// - Existing `ScannerTestItem` fixtures (matched by `id`) retain their lossless image without duplication,
    ///   have any missing `ScannerTestRun` records appended, and have any unverified local runs upgraded if verified in the archive.
    static func importArchive(
        from data: Data,
        into modelContext: ModelContext,
        existingItems: [ScannerTestItem]
    ) throws -> ScannerTestImportSummary {
        guard !data.isEmpty else {
            throw ScannerTestTransferError.emptyArchiveData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(ScannerTestSuiteArchive.self, from: data)

        var existingByID: [UUID: ScannerTestItem] = [:]
        for item in existingItems {
            existingByID[item.id] = item
        }

        var importedItemsCount = 0
        var mergedExistingItemsCount = 0
        var importedRunsCount = 0
        var updatedExistingRunsCount = 0

        for exportedItem in archive.items {
            if let existingItem = existingByID[exportedItem.id] {
                mergedExistingItemsCount += 1
                if existingItem.labelTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty,
                   !exportedItem.labelTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                    existingItem.labelTitle = exportedItem.labelTitle
                }
                if (existingItem.notes ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty,
                   let importedNotes = exportedItem.notes,
                   !importedNotes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                    existingItem.notes = importedNotes
                }
                if existingItem.thumbnailData == nil {
                    existingItem.thumbnailData = exportedItem.thumbnailData
                        ?? ScannerTestItem.makeThumbnailData(from: existingItem.originalImageData)
                }

                var existingRunsByID: [UUID: ScannerTestRun] = [:]
                for run in existingItem.runs {
                    existingRunsByID[run.id] = run
                }

                for exportedRun in exportedItem.runs {
                    if let localRun = existingRunsByID[exportedRun.id] {
                        if mergeVerificationStateIfNewer(from: exportedRun, into: localRun) {
                            updatedExistingRunsCount += 1
                        }
                    } else {
                        let newRun = makeModelRun(from: exportedRun)
                        newRun.testItem = existingItem
                        existingItem.runs.append(newRun)
                        modelContext.insert(newRun)
                        importedRunsCount += 1
                    }
                }
            } else {
                let newItem = ScannerTestItem(
                    id: exportedItem.id,
                    createdAt: exportedItem.createdAt,
                    labelTitle: exportedItem.labelTitle,
                    notes: exportedItem.notes,
                    originalImageData: exportedItem.originalImageData,
                    thumbnailData: exportedItem.thumbnailData
                )
                modelContext.insert(newItem)
                existingByID[newItem.id] = newItem
                importedItemsCount += 1

                for exportedRun in exportedItem.runs {
                    let newRun = makeModelRun(from: exportedRun)
                    newRun.testItem = newItem
                    newItem.runs.append(newRun)
                    modelContext.insert(newRun)
                    importedRunsCount += 1
                }
            }
        }

        try modelContext.save()

        return ScannerTestImportSummary(
            importedItemsCount: importedItemsCount,
            mergedExistingItemsCount: mergedExistingItemsCount,
            importedRunsCount: importedRunsCount,
            updatedExistingRunsCount: updatedExistingRunsCount
        )
    }

    // MARK: - Conversion Helpers

    private static func makeExportedItem(from item: ScannerTestItem) -> ExportedScannerTestItem {
        let exportedRuns = item.sortedRuns.map { makeExportedRun(from: $0) }
        return ExportedScannerTestItem(
            id: item.id,
            createdAt: item.createdAt,
            labelTitle: item.labelTitle,
            notes: item.notes,
            originalImageData: item.originalImageData,
            thumbnailData: item.thumbnailData,
            runs: exportedRuns
        )
    }

    private static func makeExportedRun(from run: ScannerTestRun) -> ExportedScannerTestRun {
        ExportedScannerTestRun(
            id: run.id,
            runNumber: run.runNumber,
            timestamp: run.timestamp,
            runNotes: run.runNotes,
            scannedIsSupplement: run.scannedIsSupplement,
            statusIsSupplementRaw: run.statusIsSupplementRaw,
            correctedIsSupplement: run.correctedIsSupplement,
            scannedServingSize: run.scannedServingSize,
            statusServingSizeRaw: run.statusServingSizeRaw,
            correctedServingSize: run.correctedServingSize,
            scannedServingUnit: run.scannedServingUnit,
            statusServingUnitRaw: run.statusServingUnitRaw,
            correctedServingUnit: run.correctedServingUnit,
            scannedHouseholdAmount: run.scannedHouseholdAmount,
            statusHouseholdAmountRaw: run.statusHouseholdAmountRaw,
            correctedHouseholdAmount: run.correctedHouseholdAmount,
            correctedHouseholdAmountIsNil: run.correctedHouseholdAmountIsNil,
            scannedHouseholdMeasurement: run.scannedHouseholdMeasurement,
            statusHouseholdMeasurementRaw: run.statusHouseholdMeasurementRaw,
            correctedHouseholdMeasurement: run.correctedHouseholdMeasurement,
            correctedHouseholdMeasurementIsNil: run.correctedHouseholdMeasurementIsNil,
            scannedCalories: run.scannedCalories,
            statusCaloriesRaw: run.statusCaloriesRaw,
            correctedCalories: run.correctedCalories,
            scannedFat: run.scannedFat,
            statusFatRaw: run.statusFatRaw,
            correctedFat: run.correctedFat,
            scannedSaturatedFat: run.scannedSaturatedFat,
            statusSaturatedFatRaw: run.statusSaturatedFatRaw,
            correctedSaturatedFat: run.correctedSaturatedFat,
            scannedTransFat: run.scannedTransFat,
            statusTransFatRaw: run.statusTransFatRaw,
            correctedTransFat: run.correctedTransFat,
            scannedCarb: run.scannedCarb,
            statusCarbRaw: run.statusCarbRaw,
            correctedCarb: run.correctedCarb,
            scannedDietaryFiber: run.scannedDietaryFiber,
            statusDietaryFiberRaw: run.statusDietaryFiberRaw,
            correctedDietaryFiber: run.correctedDietaryFiber,
            scannedAddedSugar: run.scannedAddedSugar,
            statusAddedSugarRaw: run.statusAddedSugarRaw,
            correctedAddedSugar: run.correctedAddedSugar,
            scannedProtein: run.scannedProtein,
            statusProteinRaw: run.statusProteinRaw,
            correctedProtein: run.correctedProtein,
            scannedTopologyRaw: run.scannedTopologyRaw,
            statusTopologyRaw: run.statusTopologyRaw,
            correctedTopologyRaw: run.correctedTopologyRaw,
            diagnostics: run.diagnosticsSnapshot,
            fullSpectrumVerification: run.fullSpectrumSnapshot
        )
    }

    private static func makeModelRun(from exported: ExportedScannerTestRun) -> ScannerTestRun {
        let topology = FDALabelTopology(rawValue: exported.scannedTopologyRaw) ?? .standardVertical
        let syntheticPayload = ScannedNutritionPayload(
            isSupplement: exported.scannedIsSupplement,
            servingSize: exported.scannedServingSize,
            servingUnit: exported.scannedServingUnit,
            commonHouseholdMeasurement: exported.scannedHouseholdMeasurement,
            commonHouseholdMeasurementAmount: exported.scannedHouseholdAmount,
            calories: exported.scannedCalories,
            fat: exported.scannedFat,
            saturatedFat: exported.scannedSaturatedFat,
            transFat: exported.scannedTransFat,
            carb: exported.scannedCarb,
            dietaryFiber: exported.scannedDietaryFiber,
            addedSugar: exported.scannedAddedSugar,
            protein: exported.scannedProtein,
            topology: topology,
            demographicGroup: .adultsAndChildren4OrMoreYears,
            confidenceScore: exported.diagnostics.validatorConfidence,
            atwaterCalorieCheckPassed: exported.diagnostics.atwaterCalorieCheckPassed,
            expectedAtwaterCalorieRange: exported.diagnostics.expectedAtwaterMinCalories...max(
                exported.diagnostics.expectedAtwaterMinCalories,
                exported.diagnostics.expectedAtwaterMaxCalories
            ),
            healedNutrients: Set(exported.diagnostics.healedNutrients),
            diagnostics: exported.diagnostics.diagnostics,
            allParsedNutrients: [:]
        )

        let run = ScannerTestRun(
            id: exported.id,
            runNumber: exported.runNumber,
            timestamp: exported.timestamp,
            runNotes: exported.runNotes,
            payload: syntheticPayload,
            diagnostics: exported.diagnostics
        )

        applyExportedVerificationState(from: exported, into: run)
        if let fullSpec = exported.fullSpectrumVerification {
            run.updateFullSpectrumSnapshot(fullSpec)
        } else {
            run.fullSpectrumVerificationJSONData = nil
            run.updateFullSpectrumSnapshot(run.fullSpectrumSnapshot)
        }
        return run
    }

    private static func applyExportedVerificationState(
        from exported: ExportedScannerTestRun,
        into run: ScannerTestRun
    ) {
        run.statusIsSupplementRaw = exported.statusIsSupplementRaw
        run.correctedIsSupplement = exported.correctedIsSupplement

        run.statusServingSizeRaw = exported.statusServingSizeRaw
        run.correctedServingSize = exported.correctedServingSize

        run.statusServingUnitRaw = exported.statusServingUnitRaw
        run.correctedServingUnit = exported.correctedServingUnit

        run.statusHouseholdAmountRaw = exported.statusHouseholdAmountRaw
        run.correctedHouseholdAmount = exported.correctedHouseholdAmount
        run.correctedHouseholdAmountIsNil = exported.correctedHouseholdAmountIsNil

        run.statusHouseholdMeasurementRaw = exported.statusHouseholdMeasurementRaw
        run.correctedHouseholdMeasurement = exported.correctedHouseholdMeasurement
        run.correctedHouseholdMeasurementIsNil = exported.correctedHouseholdMeasurementIsNil

        run.statusCaloriesRaw = exported.statusCaloriesRaw
        run.correctedCalories = exported.correctedCalories

        run.statusFatRaw = exported.statusFatRaw
        run.correctedFat = exported.correctedFat

        run.statusSaturatedFatRaw = exported.statusSaturatedFatRaw
        run.correctedSaturatedFat = exported.correctedSaturatedFat

        run.statusTransFatRaw = exported.statusTransFatRaw
        run.correctedTransFat = exported.correctedTransFat

        run.statusCarbRaw = exported.statusCarbRaw
        run.correctedCarb = exported.correctedCarb

        run.statusDietaryFiberRaw = exported.statusDietaryFiberRaw
        run.correctedDietaryFiber = exported.correctedDietaryFiber

        run.statusAddedSugarRaw = exported.statusAddedSugarRaw
        run.correctedAddedSugar = exported.correctedAddedSugar

        run.statusProteinRaw = exported.statusProteinRaw
        run.correctedProtein = exported.correctedProtein

        run.statusTopologyRaw = exported.statusTopologyRaw
        run.correctedTopologyRaw = exported.correctedTopologyRaw
    }

    private static func mergeVerificationStateIfNewer(
        from exported: ExportedScannerTestRun,
        into localRun: ScannerTestRun
    ) -> Bool {
        let beforeCount = localRun.verifiedFieldsCount
        if exported.statusIsSupplementRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusIsSupplementRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusIsSupplementRaw = exported.statusIsSupplementRaw
            localRun.correctedIsSupplement = exported.correctedIsSupplement
        }
        if exported.statusServingSizeRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusServingSizeRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusServingSizeRaw = exported.statusServingSizeRaw
            localRun.correctedServingSize = exported.correctedServingSize
        }
        if exported.statusServingUnitRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusServingUnitRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusServingUnitRaw = exported.statusServingUnitRaw
            localRun.correctedServingUnit = exported.correctedServingUnit
        }
        if exported.statusHouseholdAmountRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusHouseholdAmountRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusHouseholdAmountRaw = exported.statusHouseholdAmountRaw
            localRun.correctedHouseholdAmount = exported.correctedHouseholdAmount
            localRun.correctedHouseholdAmountIsNil = exported.correctedHouseholdAmountIsNil
        }
        if exported.statusHouseholdMeasurementRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusHouseholdMeasurementRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusHouseholdMeasurementRaw = exported.statusHouseholdMeasurementRaw
            localRun.correctedHouseholdMeasurement = exported.correctedHouseholdMeasurement
            localRun.correctedHouseholdMeasurementIsNil = exported.correctedHouseholdMeasurementIsNil
        }
        if exported.statusCaloriesRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusCaloriesRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusCaloriesRaw = exported.statusCaloriesRaw
            localRun.correctedCalories = exported.correctedCalories
        }
        if exported.statusFatRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusFatRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusFatRaw = exported.statusFatRaw
            localRun.correctedFat = exported.correctedFat
        }
        if exported.statusSaturatedFatRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusSaturatedFatRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusSaturatedFatRaw = exported.statusSaturatedFatRaw
            localRun.correctedSaturatedFat = exported.correctedSaturatedFat
        }
        if exported.statusTransFatRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusTransFatRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusTransFatRaw = exported.statusTransFatRaw
            localRun.correctedTransFat = exported.correctedTransFat
        }
        if exported.statusCarbRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusCarbRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusCarbRaw = exported.statusCarbRaw
            localRun.correctedCarb = exported.correctedCarb
        }
        if exported.statusDietaryFiberRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusDietaryFiberRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusDietaryFiberRaw = exported.statusDietaryFiberRaw
            localRun.correctedDietaryFiber = exported.correctedDietaryFiber
        }
        if exported.statusAddedSugarRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusAddedSugarRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusAddedSugarRaw = exported.statusAddedSugarRaw
            localRun.correctedAddedSugar = exported.correctedAddedSugar
        }
        if exported.statusProteinRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusProteinRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusProteinRaw = exported.statusProteinRaw
            localRun.correctedProtein = exported.correctedProtein
        }
        if exported.statusTopologyRaw != ParameterVerificationStatus.unverified.rawValue
            && localRun.statusTopologyRaw == ParameterVerificationStatus.unverified.rawValue {
            localRun.statusTopologyRaw = exported.statusTopologyRaw
            localRun.correctedTopologyRaw = exported.correctedTopologyRaw
        }
        if let exportedFullSpec = exported.fullSpectrumVerification {
            let localFullSpec = localRun.fullSpectrumSnapshot
            if (exportedFullSpec.isVerifiedComplete && !localFullSpec.isVerifiedComplete)
                || (exportedFullSpec.computeFieldDiffs().filter { $0.verificationStatus.isVerified }.count
                    > localFullSpec.computeFieldDiffs().filter { $0.verificationStatus.isVerified }.count) {
                localRun.updateFullSpectrumSnapshot(exportedFullSpec)
            }
        }
        return localRun.verifiedFieldsCount > beforeCount
    }
}
