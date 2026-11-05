//
//  ScannerTestModels.swift
//  NutritionAssistant
//
//  Milestone 5.3: SwiftData Ground-Truth & Multi-Run Testing Models
//  Defines ScannerTestItem (parent fixture with @Attribute(.externalStorage) lossless PNG image)
//  and ScannerTestRun (child execution record with paired scannedValue / verificationStatus / correctedValue
//  triplets across all 13 core nutrition fields + optional FDALabelTopology, plus ScanDiagnosticsSnapshot).
//

import CoreGraphics
import Foundation
import SwiftData
import UIKit

// MARK: - Verification Status & Verifiable Field Catalog

/// Explicit 3-state manual verification status for each parameter on a `ScannerTestRun`.
enum ParameterVerificationStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case unverified = "unverified"
    case verifiedCorrect = "verifiedCorrect"
    case verifiedIncorrect = "verifiedIncorrect"

    var isVerified: Bool {
        self != .unverified
    }

    var displayTitle: String {
        switch self {
        case .unverified:
            return "Unverified"
        case .verifiedCorrect:
            return "Correct"
        case .verifiedIncorrect:
            return "Incorrect"
        }
    }
}

/// Exhaustive catalog of parameters evaluated on each `ScannerTestRun` (13 required core fields + 1 optional topology field).
enum ScannerVerifiableField: String, Codable, CaseIterable, Sendable, Hashable, Identifiable {
    case isSupplement
    case servingSize
    case servingUnit
    case householdAmount
    case householdMeasurement
    case calories
    case fat
    case saturatedFat
    case transFat
    case carb
    case dietaryFiber
    case addedSugar
    case protein
    case topology

    var id: String { rawValue }

    /// The 13 mandatory `AddFoodView` parameters required to mark a `ScannerTestRun` as fully verified.
    static let requiredFields: [ScannerVerifiableField] = [
        .isSupplement,
        .servingSize,
        .servingUnit,
        .householdAmount,
        .householdMeasurement,
        .calories,
        .fat,
        .saturatedFat,
        .transFat,
        .carb,
        .dietaryFiber,
        .addedSugar,
        .protein
    ]

    /// `true` for the 13 core nutrition/serving fields; `false` for `.topology` (which is optional to verify).
    var isRequiredForCompletion: Bool {
        self != .topology
    }

    var displayName: String {
        switch self {
        case .isSupplement:
            return "Panel Classification"
        case .servingSize:
            return "Serving Size (Metric)"
        case .servingUnit:
            return "Serving Unit"
        case .householdAmount:
            return "Household Amount"
        case .householdMeasurement:
            return "Household Unit"
        case .calories:
            return "Calories"
        case .fat:
            return "Total Fat (g)"
        case .saturatedFat:
            return "Saturated Fat (g)"
        case .transFat:
            return "Trans Fat (g)"
        case .carb:
            return "Total Carbs (g)"
        case .dietaryFiber:
            return "Dietary Fiber (g)"
        case .addedSugar:
            return "Added Sugar (g)"
        case .protein:
            return "Protein (g)"
        case .topology:
            return "Detected Topology (Optional)"
        }
    }
}

// MARK: - FDALabelTopology Display Extension

extension FDALabelTopology {
    var displayTitle: String {
        switch self {
        case .standardVertical:
            return "Standard Vertical (B/C)"
        case .sideBySideMicronutrients:
            return "Side-by-Side Micros (D)"
        case .tabularHorizontal:
            return "Tabular Horizontal (A)"
        case .dualColumnSameFood:
            return "Dual-Column Same Food (F)"
        case .dualColumnPerContainer:
            return "Dual-Column Per Container (G)"
        case .dualColumnPerUnit:
            return "Dual-Column Per Unit (H)"
        case .tabularDualColumn:
            return "Tabular Dual-Column (I)"
        case .aggregateVariety:
            return "Aggregate Variety Pack (E)"
        case .simplified:
            return "Simplified Display (J)"
        case .smallPackageTabular:
            return "Small-Package Tabular (K)"
        case .linearString:
            return "Linear Display String (L)"
        case .supplementFacts:
            return "Supplement Facts (§ 101.36)"
        }
    }
}

// MARK: - Parent Test Fixture Model (ScannerTestItem)

/// Persists a single test label image fixture in SwiftData using `@Attribute(.externalStorage)` for 100% lossless
/// image fidelity and maintains a 1-to-many cascade relationship with sequential `ScannerTestRun` records.
@Model
final class ScannerTestItem {
    var id: UUID
    var createdAt: Date
    var labelTitle: String
    var notes: String?

    /// Lossless image bytes (e.g., upright PNG) stored externally by SwiftData so Run #1 and all future re-runs
    /// execute on identical pixel data without bloating SQLite table rows.
    @Attribute(.externalStorage)
    var originalImageData: Data

    /// Compact JPEG thumbnail (~10–15 KB) for smooth scrolling in `LabelScanningTestsView` and "Re-Run Previous Test" sheets.
    var thumbnailData: Data?

    @Relationship(deleteRule: .cascade, inverse: \ScannerTestRun.testItem)
    var runs: [ScannerTestRun]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        labelTitle: String = "",
        notes: String? = nil,
        originalImageData: Data,
        thumbnailData: Data? = nil,
        runs: [ScannerTestRun] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.labelTitle = labelTitle
        self.notes = notes
        self.originalImageData = originalImageData
        self.thumbnailData = thumbnailData ?? Self.makeThumbnailData(from: originalImageData)
        self.runs = runs
    }

    /// All test runs for this image fixture ordered sequentially from Run #1 to the latest run.
    var sortedRuns: [ScannerTestRun] {
        runs.sorted { lhs, rhs in
            if lhs.runNumber != rhs.runNumber {
                return lhs.runNumber < rhs.runNumber
            }
            return lhs.timestamp < rhs.timestamp
        }
    }

    /// The most recently executed `ScannerTestRun` for this image fixture.
    var latestRun: ScannerTestRun? {
        sortedRuns.last
    }

    /// The next sequential `runNumber` (`1` if no runs exist yet, otherwise `maxRunNumber + 1`).
    var nextRunNumber: Int {
        (sortedRuns.last?.runNumber ?? 0) + 1
    }

    /// Display title fallback when the user has not assigned a custom `labelTitle`.
    var effectiveTitle: String {
        let trimmed = labelTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if let latest = latestRun {
            return latest.scannedIsSupplement ? "Supplement Label Test" : "Nutrition Label Test"
        }
        return "Label Scan Test"
    }

    /// Finds the most recent prior `ScannerTestRun` (with `runNumber < beforeRunNumber`) in which `field`
    /// was manually verified (either `.verifiedCorrect` or `.verifiedIncorrect`), enabling a one-tap ground-truth
    /// suggestion chip on subsequent re-runs while keeping manual verification mandatory on every run.
    func previousVerifiedRun(
        for field: ScannerVerifiableField,
        beforeRunNumber: Int
    ) -> ScannerTestRun? {
        for run in sortedRuns.reversed() where run.runNumber < beforeRunNumber {
            if run.verificationStatus(for: field).isVerified,
               run.effectiveGroundTruthDisplayString(for: field) != nil {
                return run
            }
        }
        return nil
    }

    /// Finds the most recent prior `ScannerTestRun` (with `runNumber < beforeRunNumber`) whose digital label
    /// was verified (`isFullyVerified == true` or has manual corrections), allowing one-tap ground-truth grading on re-runs.
    @MainActor
    func previousVerifiedFullSpectrumRun(beforeRunNumber: Int) -> ScannerTestRun? {
        for run in sortedRuns.reversed() where run.runNumber < beforeRunNumber {
            if run.isFullyVerified || run.verifiedFieldsCount > 0 {
                return run
            }
        }
        return nil
    }

    /// Generates a lightweight JPEG thumbnail from lossless `imageData` for fast list rendering.
    static func makeThumbnailData(from imageData: Data, maxDimension: CGFloat = 180.0) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(1.0, maxDimension / max(size.width, size.height))
        let targetSize = CGSize(
            width: max(1.0, (size.width * scale).rounded()),
            height: max(1.0, (size.height * scale).rounded())
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let thumb = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return thumb.jpegData(compressionQuality: 0.72)
    }
}

// MARK: - Child Test Execution Model (ScannerTestRun)

/// Persists a single execution of `NutritionScanCoordinator` on a parent `ScannerTestItem`.
/// Every verifiable parameter stores its `scanned*` value, its manual verification status (`status*Raw`),
/// and its optional user-supplied `corrected*` ground-truth value.
@Model
final class ScannerTestRun {
    var id: UUID
    var runNumber: Int
    var timestamp: Date
    var runNotes: String?
    var testItem: ScannerTestItem?

    // 1. Panel Classification (isSupplement)
    var scannedIsSupplement: Bool
    var statusIsSupplementRaw: String
    var correctedIsSupplement: Bool?

    // 2. Serving Size (Metric)
    var scannedServingSize: Double
    var statusServingSizeRaw: String
    var correctedServingSize: Double?

    // 3. Serving Unit ("g", "ml", "oz", "unit")
    var scannedServingUnit: String
    var statusServingUnitRaw: String
    var correctedServingUnit: String?

    // 4. Household Measurement Amount
    var scannedHouseholdAmount: Double?
    var statusHouseholdAmountRaw: String
    var correctedHouseholdAmount: Double?
    var correctedHouseholdAmountIsNil: Bool

    // 5. Household Measurement Unit
    var scannedHouseholdMeasurement: String?
    var statusHouseholdMeasurementRaw: String
    var correctedHouseholdMeasurement: String?
    var correctedHouseholdMeasurementIsNil: Bool

    // 6. Calories
    var scannedCalories: Int
    var statusCaloriesRaw: String
    var correctedCalories: Int?

    // 7. Total Fat (g)
    var scannedFat: Double
    var statusFatRaw: String
    var correctedFat: Double?

    // 8. Saturated Fat (g)
    var scannedSaturatedFat: Double
    var statusSaturatedFatRaw: String
    var correctedSaturatedFat: Double?

    // 9. Trans Fat (g)
    var scannedTransFat: Double
    var statusTransFatRaw: String
    var correctedTransFat: Double?

    // 10. Total Carbohydrate (g)
    var scannedCarb: Double
    var statusCarbRaw: String
    var correctedCarb: Double?

    // 11. Dietary Fiber (g)
    var scannedDietaryFiber: Double
    var statusDietaryFiberRaw: String
    var correctedDietaryFiber: Double?

    // 12. Added Sugar (g)
    var scannedAddedSugar: Double
    var statusAddedSugarRaw: String
    var correctedAddedSugar: Double?

    // 13. Protein (g)
    var scannedProtein: Double
    var statusProteinRaw: String
    var correctedProtein: Double?

    // 14. Optional Label Topology (FDALabelTopology.rawValue)
    var scannedTopologyRaw: String
    var statusTopologyRaw: String
    var correctedTopologyRaw: String?

    /// JSON-encoded `ScanDiagnosticsSnapshot` containing all internal pipeline state and the 5 optical telemetry metrics.
    var diagnosticsJSONData: Data

    /// Milestone 6.7: Optional JSON-encoded `FullSpectrumRunVerificationSnapshot` storing the full-spectrum
    /// `scannedColumns` and user-verified `editedColumns` across all 58 FDA nutrients and multi-column candidates.
    /// Marked optional (`Data? = nil`) so SwiftData performs an automatic lightweight migration without requiring app deletion.
    var fullSpectrumVerificationJSONData: Data? = nil

    @MainActor
    init(
        id: UUID = UUID(),
        runNumber: Int = 1,
        timestamp: Date = Date(),
        runNotes: String? = nil,
        payload: ScannedNutritionPayload,
        columnCandidates: [ScannedColumnCandidate] = [],
        diagnostics: ScanDiagnosticsSnapshot
    ) {
        self.id = id
        self.runNumber = runNumber
        self.timestamp = timestamp
        self.runNotes = runNotes

        let unverifiedRaw = ParameterVerificationStatus.unverified.rawValue

        self.scannedIsSupplement = payload.isSupplement
        self.statusIsSupplementRaw = unverifiedRaw
        self.correctedIsSupplement = nil

        self.scannedServingSize = payload.servingSize
        self.statusServingSizeRaw = unverifiedRaw
        self.correctedServingSize = nil

        let normalizedUnit = FDALexicalNormalizer.normalizeServingMetricUnit(payload.servingUnit)
            ?? payload.servingUnit.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        self.scannedServingUnit = normalizedUnit.isEmpty ? "g" : normalizedUnit
        self.statusServingUnitRaw = unverifiedRaw
        self.correctedServingUnit = nil

        self.scannedHouseholdAmount = payload.commonHouseholdMeasurementAmount
        self.statusHouseholdAmountRaw = unverifiedRaw
        self.correctedHouseholdAmount = nil
        self.correctedHouseholdAmountIsNil = false

        self.scannedHouseholdMeasurement = payload.commonHouseholdMeasurement
        self.statusHouseholdMeasurementRaw = unverifiedRaw
        self.correctedHouseholdMeasurement = nil
        self.correctedHouseholdMeasurementIsNil = false

        self.scannedCalories = payload.calories
        self.statusCaloriesRaw = unverifiedRaw
        self.correctedCalories = nil

        self.scannedFat = payload.fat
        self.statusFatRaw = unverifiedRaw
        self.correctedFat = nil

        self.scannedSaturatedFat = payload.saturatedFat
        self.statusSaturatedFatRaw = unverifiedRaw
        self.correctedSaturatedFat = nil

        self.scannedTransFat = payload.transFat
        self.statusTransFatRaw = unverifiedRaw
        self.correctedTransFat = nil

        self.scannedCarb = payload.carb
        self.statusCarbRaw = unverifiedRaw
        self.correctedCarb = nil

        self.scannedDietaryFiber = payload.dietaryFiber
        self.statusDietaryFiberRaw = unverifiedRaw
        self.correctedDietaryFiber = nil

        self.scannedAddedSugar = payload.addedSugar
        self.statusAddedSugarRaw = unverifiedRaw
        self.correctedAddedSugar = nil

        self.scannedProtein = payload.protein
        self.statusProteinRaw = unverifiedRaw
        self.correctedProtein = nil

        self.scannedTopologyRaw = payload.topology.rawValue
        self.statusTopologyRaw = unverifiedRaw
        self.correctedTopologyRaw = nil

        self.diagnosticsJSONData = (try? JSONEncoder().encode(diagnostics)) ?? Data()

        let snapshot = FullSpectrumRunVerificationSnapshot(
            from: payload,
            columnCandidates: columnCandidates
        )
        self.fullSpectrumVerificationJSONData = try? JSONEncoder().encode(snapshot)
    }

    // MARK: - Decoded Diagnostics & Topology Accessors

    @MainActor
    var diagnosticsSnapshot: ScanDiagnosticsSnapshot {
        get {
            if !diagnosticsJSONData.isEmpty,
               let decoded = try? JSONDecoder().decode(ScanDiagnosticsSnapshot.self, from: diagnosticsJSONData) {
                return decoded
            }
            return ScanDiagnosticsSnapshot()
        }
        set {
            diagnosticsJSONData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var scannedTopology: FDALabelTopology {
        FDALabelTopology(rawValue: scannedTopologyRaw) ?? .standardVertical
    }

    var correctedTopology: FDALabelTopology? {
        get {
            guard let raw = correctedTopologyRaw else { return nil }
            return FDALabelTopology(rawValue: raw)
        }
        set {
            correctedTopologyRaw = newValue?.rawValue
        }
    }

    // MARK: - Verification Status Getters & Setters

    func verificationStatus(for field: ScannerVerifiableField) -> ParameterVerificationStatus {
        let raw: String
        switch field {
        case .isSupplement: raw = statusIsSupplementRaw
        case .servingSize: raw = statusServingSizeRaw
        case .servingUnit: raw = statusServingUnitRaw
        case .householdAmount: raw = statusHouseholdAmountRaw
        case .householdMeasurement: raw = statusHouseholdMeasurementRaw
        case .calories: raw = statusCaloriesRaw
        case .fat: raw = statusFatRaw
        case .saturatedFat: raw = statusSaturatedFatRaw
        case .transFat: raw = statusTransFatRaw
        case .carb: raw = statusCarbRaw
        case .dietaryFiber: raw = statusDietaryFiberRaw
        case .addedSugar: raw = statusAddedSugarRaw
        case .protein: raw = statusProteinRaw
        case .topology: raw = statusTopologyRaw
        }
        return ParameterVerificationStatus(rawValue: raw) ?? .unverified
    }

    func setVerificationStatus(_ status: ParameterVerificationStatus, for field: ScannerVerifiableField) {
        let raw = status.rawValue
        switch field {
        case .isSupplement:
            statusIsSupplementRaw = raw
            if status == .verifiedIncorrect && correctedIsSupplement == nil {
                correctedIsSupplement = !scannedIsSupplement
            } else if status != .verifiedIncorrect {
                correctedIsSupplement = nil
            }
        case .servingSize:
            statusServingSizeRaw = raw
            if status == .verifiedIncorrect && correctedServingSize == nil {
                correctedServingSize = scannedServingSize
            } else if status != .verifiedIncorrect {
                correctedServingSize = nil
            }
        case .servingUnit:
            statusServingUnitRaw = raw
            if status == .verifiedIncorrect && correctedServingUnit == nil {
                correctedServingUnit = scannedServingUnit
            } else if status != .verifiedIncorrect {
                correctedServingUnit = nil
            }
        case .householdAmount:
            statusHouseholdAmountRaw = raw
            if status != .verifiedIncorrect {
                correctedHouseholdAmount = nil
                correctedHouseholdAmountIsNil = false
            }
        case .householdMeasurement:
            statusHouseholdMeasurementRaw = raw
            if status != .verifiedIncorrect {
                correctedHouseholdMeasurement = nil
                correctedHouseholdMeasurementIsNil = false
            }
        case .calories:
            statusCaloriesRaw = raw
            if status == .verifiedIncorrect && correctedCalories == nil {
                correctedCalories = scannedCalories
            } else if status != .verifiedIncorrect {
                correctedCalories = nil
            }
        case .fat:
            statusFatRaw = raw
            if status == .verifiedIncorrect && correctedFat == nil {
                correctedFat = scannedFat
            } else if status != .verifiedIncorrect {
                correctedFat = nil
            }
        case .saturatedFat:
            statusSaturatedFatRaw = raw
            if status == .verifiedIncorrect && correctedSaturatedFat == nil {
                correctedSaturatedFat = scannedSaturatedFat
            } else if status != .verifiedIncorrect {
                correctedSaturatedFat = nil
            }
        case .transFat:
            statusTransFatRaw = raw
            if status == .verifiedIncorrect && correctedTransFat == nil {
                correctedTransFat = scannedTransFat
            } else if status != .verifiedIncorrect {
                correctedTransFat = nil
            }
        case .carb:
            statusCarbRaw = raw
            if status == .verifiedIncorrect && correctedCarb == nil {
                correctedCarb = scannedCarb
            } else if status != .verifiedIncorrect {
                correctedCarb = nil
            }
        case .dietaryFiber:
            statusDietaryFiberRaw = raw
            if status == .verifiedIncorrect && correctedDietaryFiber == nil {
                correctedDietaryFiber = scannedDietaryFiber
            } else if status != .verifiedIncorrect {
                correctedDietaryFiber = nil
            }
        case .addedSugar:
            statusAddedSugarRaw = raw
            if status == .verifiedIncorrect && correctedAddedSugar == nil {
                correctedAddedSugar = scannedAddedSugar
            } else if status != .verifiedIncorrect {
                correctedAddedSugar = nil
            }
        case .protein:
            statusProteinRaw = raw
            if status == .verifiedIncorrect && correctedProtein == nil {
                correctedProtein = scannedProtein
            } else if status != .verifiedIncorrect {
                correctedProtein = nil
            }
        case .topology:
            statusTopologyRaw = raw
            if status == .verifiedIncorrect && correctedTopologyRaw == nil {
                correctedTopologyRaw = scannedTopologyRaw
            } else if status != .verifiedIncorrect {
                correctedTopologyRaw = nil
            }
        }
    }

    // MARK: - Formatted Display Strings & Ground Truth Helpers

    @MainActor
    func scannedValueOrigin(for field: ScannerVerifiableField) -> ScannedValueOrigin? {
        diagnosticsSnapshot.nutrientOrigins[field.rawValue]
    }

    func scannedDisplayString(for field: ScannerVerifiableField) -> String {
        switch field {
        case .isSupplement:
            return scannedIsSupplement ? "Supplement Label" : "Food Label"
        case .servingSize:
            return Self.formatDouble(scannedServingSize)
        case .servingUnit:
            return scannedServingUnit
        case .householdAmount:
            if let amt = scannedHouseholdAmount {
                return Self.formatDouble(amt)
            }
            return "None (nil)"
        case .householdMeasurement:
            if let unit = scannedHouseholdMeasurement, !unit.isEmpty {
                return unit
            }
            return "None (nil)"
        case .calories:
            return "\(scannedCalories) kcal"
        case .fat:
            return "\(Self.formatDouble(scannedFat)) g"
        case .saturatedFat:
            return "\(Self.formatDouble(scannedSaturatedFat)) g"
        case .transFat:
            return "\(Self.formatDouble(scannedTransFat)) g"
        case .carb:
            return "\(Self.formatDouble(scannedCarb)) g"
        case .dietaryFiber:
            return "\(Self.formatDouble(scannedDietaryFiber)) g"
        case .addedSugar:
            return "\(Self.formatDouble(scannedAddedSugar)) g"
        case .protein:
            return "\(Self.formatDouble(scannedProtein)) g"
        case .topology:
            return scannedTopology.displayTitle
        }
    }

    func correctedDisplayString(for field: ScannerVerifiableField) -> String? {
        guard verificationStatus(for: field) == .verifiedIncorrect else { return nil }
        switch field {
        case .isSupplement:
            guard let val = correctedIsSupplement else { return nil }
            return val ? "Supplement Label" : "Food Label"
        case .servingSize:
            guard let val = correctedServingSize else { return nil }
            return Self.formatDouble(val)
        case .servingUnit:
            return correctedServingUnit
        case .householdAmount:
            if correctedHouseholdAmountIsNil {
                return "None (nil)"
            }
            guard let val = correctedHouseholdAmount else { return nil }
            return Self.formatDouble(val)
        case .householdMeasurement:
            if correctedHouseholdMeasurementIsNil {
                return "None (nil)"
            }
            guard let val = correctedHouseholdMeasurement, !val.isEmpty else { return nil }
            return val
        case .calories:
            guard let val = correctedCalories else { return nil }
            return "\(val) kcal"
        case .fat:
            guard let val = correctedFat else { return nil }
            return "\(Self.formatDouble(val)) g"
        case .saturatedFat:
            guard let val = correctedSaturatedFat else { return nil }
            return "\(Self.formatDouble(val)) g"
        case .transFat:
            guard let val = correctedTransFat else { return nil }
            return "\(Self.formatDouble(val)) g"
        case .carb:
            guard let val = correctedCarb else { return nil }
            return "\(Self.formatDouble(val)) g"
        case .dietaryFiber:
            guard let val = correctedDietaryFiber else { return nil }
            return "\(Self.formatDouble(val)) g"
        case .addedSugar:
            guard let val = correctedAddedSugar else { return nil }
            return "\(Self.formatDouble(val)) g"
        case .protein:
            guard let val = correctedProtein else { return nil }
            return "\(Self.formatDouble(val)) g"
        case .topology:
            return correctedTopology?.displayTitle
        }
    }

    /// Returns the human-verified ground-truth string for `field` on this run:
    /// - If marked `.verifiedCorrect`, returns `scannedDisplayString(for: field)`.
    /// - If marked `.verifiedIncorrect`, returns `correctedDisplayString(for: field)`.
    /// - If `.unverified`, returns `nil`.
    func effectiveGroundTruthDisplayString(for field: ScannerVerifiableField) -> String? {
        switch verificationStatus(for: field) {
        case .unverified:
            return nil
        case .verifiedCorrect:
            return scannedDisplayString(for: field)
        case .verifiedIncorrect:
            return correctedDisplayString(for: field)
        }
    }

    /// Copies the verified ground-truth value from an earlier `priorRun` into `self`'s `corrected*` property
    /// when the user taps the one-tap QoL suggestion chip during manual review of Run #2+.
    func applyCorrectedValueSuggestion(from priorRun: ScannerTestRun, for field: ScannerVerifiableField) {
        let priorStatus = priorRun.verificationStatus(for: field)
        guard priorStatus.isVerified else { return }

        setVerificationStatus(.verifiedIncorrect, for: field)

        switch field {
        case .isSupplement:
            correctedIsSupplement = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedIsSupplement
                : (priorRun.correctedIsSupplement ?? priorRun.scannedIsSupplement)
        case .servingSize:
            correctedServingSize = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedServingSize
                : (priorRun.correctedServingSize ?? priorRun.scannedServingSize)
        case .servingUnit:
            correctedServingUnit = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedServingUnit
                : (priorRun.correctedServingUnit ?? priorRun.scannedServingUnit)
        case .householdAmount:
            if priorStatus == .verifiedCorrect {
                correctedHouseholdAmount = priorRun.scannedHouseholdAmount
                correctedHouseholdAmountIsNil = (priorRun.scannedHouseholdAmount == nil)
            } else {
                correctedHouseholdAmount = priorRun.correctedHouseholdAmount
                correctedHouseholdAmountIsNil = priorRun.correctedHouseholdAmountIsNil
            }
        case .householdMeasurement:
            if priorStatus == .verifiedCorrect {
                correctedHouseholdMeasurement = priorRun.scannedHouseholdMeasurement
                correctedHouseholdMeasurementIsNil = (priorRun.scannedHouseholdMeasurement == nil)
            } else {
                correctedHouseholdMeasurement = priorRun.correctedHouseholdMeasurement
                correctedHouseholdMeasurementIsNil = priorRun.correctedHouseholdMeasurementIsNil
            }
        case .calories:
            correctedCalories = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedCalories
                : (priorRun.correctedCalories ?? priorRun.scannedCalories)
        case .fat:
            correctedFat = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedFat
                : (priorRun.correctedFat ?? priorRun.scannedFat)
        case .saturatedFat:
            correctedSaturatedFat = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedSaturatedFat
                : (priorRun.correctedSaturatedFat ?? priorRun.scannedSaturatedFat)
        case .transFat:
            correctedTransFat = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedTransFat
                : (priorRun.correctedTransFat ?? priorRun.scannedTransFat)
        case .carb:
            correctedCarb = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedCarb
                : (priorRun.correctedCarb ?? priorRun.scannedCarb)
        case .dietaryFiber:
            correctedDietaryFiber = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedDietaryFiber
                : (priorRun.correctedDietaryFiber ?? priorRun.scannedDietaryFiber)
        case .addedSugar:
            correctedAddedSugar = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedAddedSugar
                : (priorRun.correctedAddedSugar ?? priorRun.scannedAddedSugar)
        case .protein:
            correctedProtein = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedProtein
                : (priorRun.correctedProtein ?? priorRun.scannedProtein)
        case .topology:
            correctedTopologyRaw = (priorStatus == .verifiedCorrect)
                ? priorRun.scannedTopologyRaw
                : (priorRun.correctedTopologyRaw ?? priorRun.scannedTopologyRaw)
        }
    }

    // MARK: - Full-Spectrum Verification Snapshot Accessors & Sync (Milestone 6.7)

    @MainActor
    var fullSpectrumSnapshot: FullSpectrumRunVerificationSnapshot {
        get {
            if let data = fullSpectrumVerificationJSONData,
               !data.isEmpty,
               let decoded = try? JSONDecoder().decode(FullSpectrumRunVerificationSnapshot.self, from: data) {
                return decoded
            }
            return synthesizeLegacyFullSpectrumSnapshot()
        }
        set {
            updateFullSpectrumSnapshot(newValue)
        }
    }

    @MainActor
    func updateFullSpectrumSnapshot(_ snapshot: FullSpectrumRunVerificationSnapshot) {
        fullSpectrumVerificationJSONData = try? JSONEncoder().encode(snapshot)
        synchronizeLegacyFields(from: snapshot)
    }

    /// Synthesizes a 1-column `FullSpectrumRunVerificationSnapshot` for legacy `ScannerTestRun` records created
    /// prior to Milestone 6.7 so all existing fixtures render and grade seamlessly inside `FDADigitalLabelView`.
    @MainActor
    private func synthesizeLegacyFullSpectrumSnapshot() -> FullSpectrumRunVerificationSnapshot {
        var scannedProfile = NutritionProfile()
        scannedProfile.setExactValue(Double(scannedCalories), unit: .kcal, for: .calories)
        scannedProfile.setExactValue(scannedFat, unit: .g, for: .totalFat)
        scannedProfile.setExactValue(scannedSaturatedFat, unit: .g, for: .saturatedFat)
        scannedProfile.setExactValue(scannedTransFat, unit: .g, for: .transFat)
        scannedProfile.setExactValue(scannedCarb, unit: .g, for: .totalCarbohydrate)
        scannedProfile.setExactValue(scannedDietaryFiber, unit: .g, for: .dietaryFiber)
        scannedProfile.setExactValue(scannedAddedSugar, unit: .g, for: .addedSugars)
        scannedProfile.setExactValue(scannedProtein, unit: .g, for: .protein)

        var editedProfile = scannedProfile
        if verificationStatus(for: .calories) == .verifiedIncorrect, let val = correctedCalories {
            editedProfile.setExactValue(Double(val), unit: .kcal, for: .calories)
        }
        if verificationStatus(for: .fat) == .verifiedIncorrect, let val = correctedFat {
            editedProfile.setExactValue(val, unit: .g, for: .totalFat)
        }
        if verificationStatus(for: .saturatedFat) == .verifiedIncorrect, let val = correctedSaturatedFat {
            editedProfile.setExactValue(val, unit: .g, for: .saturatedFat)
        }
        if verificationStatus(for: .transFat) == .verifiedIncorrect, let val = correctedTransFat {
            editedProfile.setExactValue(val, unit: .g, for: .transFat)
        }
        if verificationStatus(for: .carb) == .verifiedIncorrect, let val = correctedCarb {
            editedProfile.setExactValue(val, unit: .g, for: .totalCarbohydrate)
        }
        if verificationStatus(for: .dietaryFiber) == .verifiedIncorrect, let val = correctedDietaryFiber {
            editedProfile.setExactValue(val, unit: .g, for: .dietaryFiber)
        }
        if verificationStatus(for: .addedSugar) == .verifiedIncorrect, let val = correctedAddedSugar {
            editedProfile.setExactValue(val, unit: .g, for: .addedSugars)
        }
        if verificationStatus(for: .protein) == .verifiedIncorrect, let val = correctedProtein {
            editedProfile.setExactValue(val, unit: .g, for: .protein)
        }

        let colID = id
        let scannedCol = FDADigitalLabelColumnDraft(
            id: colID,
            columnIndex: 0,
            headerTitle: "Per Serving",
            isIncluded: true,
            servingSize: scannedServingSize,
            servingUnit: scannedServingUnit,
            commonHouseholdMeasurementAmount: scannedHouseholdAmount,
            commonHouseholdMeasurement: scannedHouseholdMeasurement,
            nutrition: scannedProfile
        )

        let editedServingSize = (verificationStatus(for: .servingSize) == .verifiedIncorrect)
            ? (correctedServingSize ?? scannedServingSize)
            : scannedServingSize
        let editedServingUnit = (verificationStatus(for: .servingUnit) == .verifiedIncorrect)
            ? (correctedServingUnit ?? scannedServingUnit)
            : scannedServingUnit
        let editedHHAmount: Double? = {
            if verificationStatus(for: .householdAmount) == .verifiedIncorrect {
                return correctedHouseholdAmountIsNil ? nil : correctedHouseholdAmount
            }
            return scannedHouseholdAmount
        }()
        let editedHHUnit: String? = {
            if verificationStatus(for: .householdMeasurement) == .verifiedIncorrect {
                return correctedHouseholdMeasurementIsNil ? nil : correctedHouseholdMeasurement
            }
            return scannedHouseholdMeasurement
        }()

        let editedCol = FDADigitalLabelColumnDraft(
            id: colID,
            columnIndex: 0,
            headerTitle: "Per Serving",
            isIncluded: true,
            servingSize: editedServingSize,
            servingUnit: editedServingUnit,
            commonHouseholdMeasurementAmount: editedHHAmount,
            commonHouseholdMeasurement: editedHHUnit,
            nutrition: editedProfile
        )

        let legacyAllVerified = ScannerVerifiableField.requiredFields.allSatisfy {
            verificationStatus(for: $0).isVerified
        }

        var manualIDs: Set<String> = []
        if verificationStatus(for: .topology) == .verifiedCorrect {
            manualIDs.insert("meta.topology")
        }
        if verificationStatus(for: .servingSize) == .verifiedCorrect
            && verificationStatus(for: .servingUnit) == .verifiedCorrect {
            manualIDs.insert("col0.servingSize")
        }
        if verificationStatus(for: .householdAmount) == .verifiedCorrect
            && verificationStatus(for: .householdMeasurement) == .verifiedCorrect {
            manualIDs.insert("col0.householdMeasure")
        }
        let nutrientMap: [(ScannerVerifiableField, CanonicalNutrientID)] = [
            (.calories, .calories),
            (.fat, .totalFat),
            (.saturatedFat, .saturatedFat),
            (.transFat, .transFat),
            (.carb, .totalCarbohydrate),
            (.dietaryFiber, .dietaryFiber),
            (.addedSugar, .addedSugars),
            (.protein, .protein)
        ]
        for (field, nid) in nutrientMap where verificationStatus(for: field) == .verifiedCorrect {
            manualIDs.insert("col0.nutrient.\(nid.rawValue)")
        }

        return FullSpectrumRunVerificationSnapshot(
            scannedColumns: [scannedCol],
            editedColumns: [editedCol],
            scannedTopology: scannedTopology,
            correctedTopology: (verificationStatus(for: .topology) == .verifiedIncorrect) ? correctedTopology : nil,
            scannedDemographic: .adultsAndChildren4OrMoreYears,
            correctedDemographic: nil,
            isVerifiedComplete: legacyAllVerified,
            manuallyVerifiedFieldIDs: manualIDs
        )
    }

    /// Synchronizes edits made on Column 0 of `FullSpectrumRunVerificationSnapshot` back into the 14 legacy
    /// properties on `ScannerTestRun` so legacy readers and telemetry remain 100% consistent.
    @MainActor
    private func synchronizeLegacyFields(from snapshot: FullSpectrumRunVerificationSnapshot) {
        let verifiedDone = snapshot.isVerifiedComplete
        let effectiveTopo = snapshot.effectiveTopology

        if effectiveTopo != scannedTopology {
            statusTopologyRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedTopologyRaw = effectiveTopo.rawValue
        } else if verifiedDone || snapshot.manuallyVerifiedFieldIDs.contains("meta.topology") {
            statusTopologyRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedTopologyRaw = nil
        } else {
            statusTopologyRaw = ParameterVerificationStatus.unverified.rawValue
            correctedTopologyRaw = nil
        }

        let effectiveIsSupplement = (effectiveTopo == .supplementFacts)
        if effectiveIsSupplement != scannedIsSupplement {
            statusIsSupplementRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedIsSupplement = effectiveIsSupplement
        } else if verifiedDone {
            statusIsSupplementRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedIsSupplement = nil
        }

        guard let editedCol = snapshot.editedColumns.first else { return }

        if abs(editedCol.servingSize - scannedServingSize) > 0.015 {
            statusServingSizeRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedServingSize = editedCol.servingSize
        } else if verifiedDone || snapshot.manuallyVerifiedFieldIDs.contains("col0.servingSize") {
            statusServingSizeRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedServingSize = nil
        }

        if editedCol.servingUnit.lowercased() != scannedServingUnit.lowercased() {
            statusServingUnitRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedServingUnit = editedCol.servingUnit
        } else if verifiedDone || snapshot.manuallyVerifiedFieldIDs.contains("col0.servingSize") {
            statusServingUnitRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedServingUnit = nil
        }

        let hhAmtMatches: Bool = {
            switch (scannedHouseholdAmount, editedCol.commonHouseholdMeasurementAmount) {
            case (nil, nil): return true
            case let (a?, b?): return abs(a - b) <= 0.015
            default: return false
            }
        }()
        if !hhAmtMatches {
            statusHouseholdAmountRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedHouseholdAmount = editedCol.commonHouseholdMeasurementAmount
            correctedHouseholdAmountIsNil = (editedCol.commonHouseholdMeasurementAmount == nil)
        } else if verifiedDone || snapshot.manuallyVerifiedFieldIDs.contains("col0.householdMeasure") {
            statusHouseholdAmountRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedHouseholdAmount = nil
            correctedHouseholdAmountIsNil = false
        }

        let scannedHHStr = (scannedHouseholdMeasurement ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let editedHHStr = (editedCol.commonHouseholdMeasurement ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if scannedHHStr != editedHHStr {
            statusHouseholdMeasurementRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedHouseholdMeasurement = editedCol.commonHouseholdMeasurement
            correctedHouseholdMeasurementIsNil = editedHHStr.isEmpty
        } else if verifiedDone || snapshot.manuallyVerifiedFieldIDs.contains("col0.householdMeasure") {
            statusHouseholdMeasurementRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedHouseholdMeasurement = nil
            correctedHouseholdMeasurementIsNil = false
        }

        let editedCalories = editedCol.nutrition.calories
        if editedCalories != scannedCalories {
            statusCaloriesRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedCalories = editedCalories
        } else if verifiedDone || snapshot.manuallyVerifiedFieldIDs.contains("col0.nutrient.calories") {
            statusCaloriesRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedCalories = nil
        }

        syncMacroField(
            editedValue: editedCol.nutrition.resolvedOrZero(for: .totalFat),
            scannedValue: scannedFat,
            nutrientKey: "col0.nutrient.totalFat",
            verifiedDone: verifiedDone,
            manualIDs: snapshot.manuallyVerifiedFieldIDs,
            statusRaw: &statusFatRaw,
            correctedValue: &correctedFat
        )
        syncMacroField(
            editedValue: editedCol.nutrition.resolvedOrZero(for: .saturatedFat),
            scannedValue: scannedSaturatedFat,
            nutrientKey: "col0.nutrient.saturatedFat",
            verifiedDone: verifiedDone,
            manualIDs: snapshot.manuallyVerifiedFieldIDs,
            statusRaw: &statusSaturatedFatRaw,
            correctedValue: &correctedSaturatedFat
        )
        syncMacroField(
            editedValue: editedCol.nutrition.resolvedOrZero(for: .transFat),
            scannedValue: scannedTransFat,
            nutrientKey: "col0.nutrient.transFat",
            verifiedDone: verifiedDone,
            manualIDs: snapshot.manuallyVerifiedFieldIDs,
            statusRaw: &statusTransFatRaw,
            correctedValue: &correctedTransFat
        )
        syncMacroField(
            editedValue: editedCol.nutrition.resolvedOrZero(for: .totalCarbohydrate),
            scannedValue: scannedCarb,
            nutrientKey: "col0.nutrient.totalCarbohydrate",
            verifiedDone: verifiedDone,
            manualIDs: snapshot.manuallyVerifiedFieldIDs,
            statusRaw: &statusCarbRaw,
            correctedValue: &correctedCarb
        )
        syncMacroField(
            editedValue: editedCol.nutrition.resolvedOrZero(for: .dietaryFiber),
            scannedValue: scannedDietaryFiber,
            nutrientKey: "col0.nutrient.dietaryFiber",
            verifiedDone: verifiedDone,
            manualIDs: snapshot.manuallyVerifiedFieldIDs,
            statusRaw: &statusDietaryFiberRaw,
            correctedValue: &correctedDietaryFiber
        )
        syncMacroField(
            editedValue: editedCol.nutrition.resolvedOrZero(for: .addedSugars),
            scannedValue: scannedAddedSugar,
            nutrientKey: "col0.nutrient.addedSugars",
            verifiedDone: verifiedDone,
            manualIDs: snapshot.manuallyVerifiedFieldIDs,
            statusRaw: &statusAddedSugarRaw,
            correctedValue: &correctedAddedSugar
        )
        syncMacroField(
            editedValue: editedCol.nutrition.resolvedOrZero(for: .protein),
            scannedValue: scannedProtein,
            nutrientKey: "col0.nutrient.protein",
            verifiedDone: verifiedDone,
            manualIDs: snapshot.manuallyVerifiedFieldIDs,
            statusRaw: &statusProteinRaw,
            correctedValue: &correctedProtein
        )
    }

    private func syncMacroField(
        editedValue: Double,
        scannedValue: Double,
        nutrientKey: String,
        verifiedDone: Bool,
        manualIDs: Set<String>,
        statusRaw: inout String,
        correctedValue: inout Double?
    ) {
        if abs(editedValue - scannedValue) > 0.015 {
            statusRaw = ParameterVerificationStatus.verifiedIncorrect.rawValue
            correctedValue = editedValue
        } else if verifiedDone || manualIDs.contains(nutrientKey) {
            statusRaw = ParameterVerificationStatus.verifiedCorrect.rawValue
            correctedValue = nil
        }
    }

    // MARK: - Verification Progress & Accuracy Calculations

    @MainActor
    var fullSpectrumFieldDiffs: [FullSpectrumFieldDiffItem] {
        fullSpectrumSnapshot.computeFieldDiffs()
    }

    @MainActor
    var verifiedRequiredCount: Int {
        fullSpectrumFieldDiffs.filter { $0.verificationStatus.isVerified }.count
    }

    @MainActor
    var totalRequiredCount: Int {
        max(1, fullSpectrumFieldDiffs.count)
    }

    @MainActor
    var isFullyVerified: Bool {
        let diffs = fullSpectrumFieldDiffs
        return !diffs.isEmpty && diffs.allSatisfy { $0.verificationStatus.isVerified }
    }

    /// Total count of fields verified by the user across the full digital label.
    @MainActor
    var verifiedFieldsCount: Int {
        fullSpectrumFieldDiffs.filter { $0.verificationStatus.isVerified }.count
    }

    /// Count of verified fields marked `.verifiedCorrect` across the full digital label.
    @MainActor
    var correctFieldsCount: Int {
        fullSpectrumFieldDiffs.filter { $0.verificationStatus == .verifiedCorrect }.count
    }

    /// Count of verified fields marked `.verifiedIncorrect` (corrected, missed by scanner, or removed false positive).
    @MainActor
    var incorrectFieldsCount: Int {
        fullSpectrumFieldDiffs.filter { $0.verificationStatus == .verifiedIncorrect }.count
    }

    /// Empirical scan accuracy (`0.0 ... 1.0`) across all human-verified fields on this run, or `nil` if no fields are verified yet.
    @MainActor
    var accuracyRatio: Double? {
        let denom = verifiedFieldsCount
        guard denom > 0 else { return nil }
        return Double(correctFieldsCount) / Double(denom)
    }

    @MainActor
    var accuracyPercentageString: String {
        guard let ratio = accuracyRatio else {
            return "Unverified (0/\(totalRequiredCount))"
        }
        let pct = Int((ratio * 100.0).rounded())
        return "\(pct)% (\(correctFieldsCount)/\(verifiedFieldsCount))"
    }

    static func formatDouble(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(format: "%.0f", value)
        }
        let oneDec = (value * 10.0).rounded() / 10.0
        if abs(value - oneDec) < 0.001 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Full-Spectrum Digital-Label Verification & Diff Engine (Milestone 6.7)

/// Classification of how a single field or nutrient line on the digital FDA label compares between the
/// raw Vision scanner output (`scannedColumns`) and the user's verified digital label (`editedColumns`).
enum FullSpectrumFieldDiffKind: String, Codable, Sendable, Equatable, Hashable {
    case exactMatch = "exactMatch"
    case correctedValue = "correctedValue"
    case missedByScanner = "missedByScanner"
    case removedFalsePositive = "removedFalsePositive"

    var badgeTitle: String {
        switch self {
        case .exactMatch:
            return "Exact Match"
        case .correctedValue:
            return "Corrected"
        case .missedByScanner:
            return "Missed by Scanner"
        case .removedFalsePositive:
            return "Removed False Positive"
        }
    }
}

/// Represents a single verifiable field or nutrient line on the digital FDA label (across 1 or N columns).
struct FullSpectrumFieldDiffItem: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: String
    let columnIndex: Int
    let columnTitle: String
    let fieldTitle: String
    let scannedDisplayValue: String
    let groundTruthDisplayValue: String
    let diffKind: FullSpectrumFieldDiffKind
    let verificationStatus: ParameterVerificationStatus
}

/// Complete full-spectrum verification state for a `ScannerTestRun`, pairing the original `scannedColumns`
/// produced by `NutritionScanCoordinator` with the user-inspected/edited `editedColumns` rendered in `FDADigitalLabelView`.
struct FullSpectrumRunVerificationSnapshot: Codable, Sendable, Equatable {
    var scannedColumns: [FDADigitalLabelColumnDraft]
    var editedColumns: [FDADigitalLabelColumnDraft]
    var scannedTopology: FDALabelTopology
    var correctedTopology: FDALabelTopology?
    var scannedDemographic: FDADemographicGroup
    var correctedDemographic: FDADemographicGroup?
    var isVerifiedComplete: Bool
    var manuallyVerifiedFieldIDs: Set<String>

    init(
        scannedColumns: [FDADigitalLabelColumnDraft],
        editedColumns: [FDADigitalLabelColumnDraft],
        scannedTopology: FDALabelTopology,
        correctedTopology: FDALabelTopology? = nil,
        scannedDemographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears,
        correctedDemographic: FDADemographicGroup? = nil,
        isVerifiedComplete: Bool = false,
        manuallyVerifiedFieldIDs: Set<String> = []
    ) {
        self.scannedColumns = scannedColumns
        self.editedColumns = editedColumns
        self.scannedTopology = scannedTopology
        self.correctedTopology = correctedTopology
        self.scannedDemographic = scannedDemographic
        self.correctedDemographic = correctedDemographic
        self.isVerifiedComplete = isVerifiedComplete
        self.manuallyVerifiedFieldIDs = manuallyVerifiedFieldIDs
    }

    init(
        from payload: ScannedNutritionPayload,
        columnCandidates: [ScannedColumnCandidate]
    ) {
        let initialColumns: [FDADigitalLabelColumnDraft]
        if !columnCandidates.isEmpty {
            initialColumns = columnCandidates.map { FDADigitalLabelColumnDraft(from: $0) }
        } else {
            initialColumns = [FDADigitalLabelColumnDraft(from: payload)]
        }

        self.scannedColumns = initialColumns
        self.editedColumns = initialColumns
        self.scannedTopology = payload.topology
        self.correctedTopology = nil
        self.scannedDemographic = payload.demographicGroup
        self.correctedDemographic = nil
        self.isVerifiedComplete = false
        self.manuallyVerifiedFieldIDs = []
    }

    var effectiveTopology: FDALabelTopology {
        correctedTopology ?? scannedTopology
    }

    var effectiveDemographic: FDADemographicGroup {
        correctedDemographic ?? scannedDemographic
    }

    /// Applies the verified ground-truth digital label (`editedColumns`, `effectiveTopology`, `effectiveDemographic`)
    /// from an earlier verified run on the same fixture and marks this run's verification complete.
    mutating func applyVerifiedGroundTruth(from priorSnapshot: FullSpectrumRunVerificationSnapshot) {
        self.editedColumns = priorSnapshot.editedColumns
        if priorSnapshot.effectiveTopology != self.scannedTopology {
            self.correctedTopology = priorSnapshot.effectiveTopology
        } else {
            self.correctedTopology = nil
        }
        if priorSnapshot.effectiveDemographic != self.scannedDemographic {
            self.correctedDemographic = priorSnapshot.effectiveDemographic
        } else {
            self.correctedDemographic = nil
        }
        self.isVerifiedComplete = true
    }

    /// Resets `editedColumns` back to the untouched `scannedColumns` and clears verification completion.
    mutating func resetToScannedOutput() {
        self.editedColumns = self.scannedColumns
        self.correctedTopology = nil
        self.correctedDemographic = nil
        self.isVerifiedComplete = false
        self.manuallyVerifiedFieldIDs.removeAll()
    }

    /// Evaluates every header parameter, nutrient row, and Supplement Facts Tier-2 ingredient across all columns.
    func computeFieldDiffs() -> [FullSpectrumFieldDiffItem] {
        var items: [FullSpectrumFieldDiffItem] = []

        // 1. Label Topology
        let topoID = "meta.topology"
        let effectiveTopo = effectiveTopology
        if effectiveTopo != scannedTopology {
            items.append(
                FullSpectrumFieldDiffItem(
                    id: topoID,
                    columnIndex: 0,
                    columnTitle: "Label Structure",
                    fieldTitle: "Detected Topology",
                    scannedDisplayValue: scannedTopology.displayTitle,
                    groundTruthDisplayValue: effectiveTopo.displayTitle,
                    diffKind: .correctedValue,
                    verificationStatus: .verifiedIncorrect
                )
            )
        } else {
            let status: ParameterVerificationStatus = (isVerifiedComplete || manuallyVerifiedFieldIDs.contains(topoID))
                ? .verifiedCorrect
                : .unverified
            items.append(
                FullSpectrumFieldDiffItem(
                    id: topoID,
                    columnIndex: 0,
                    columnTitle: "Label Structure",
                    fieldTitle: "Detected Topology",
                    scannedDisplayValue: scannedTopology.displayTitle,
                    groundTruthDisplayValue: scannedTopology.displayTitle,
                    diffKind: .exactMatch,
                    verificationStatus: status
                )
            )
        }

        let maxCols = max(scannedColumns.count, editedColumns.count)
        let isMultiCol = maxCols > 1
        let baselineCoreNutrients: Set<CanonicalNutrientID> = [
            .calories, .totalFat, .saturatedFat, .transFat,
            .totalCarbohydrate, .dietaryFiber, .addedSugars, .protein
        ]

        for colIdx in 0..<maxCols {
            let sCol = colIdx < scannedColumns.count ? scannedColumns[colIdx] : nil
            let eCol = colIdx < editedColumns.count ? editedColumns[colIdx] : nil
            let colTitle = eCol?.headerTitle ?? sCol?.headerTitle ?? "Column \(colIdx + 1)"
            let colPrefix = isMultiCol ? "[\(colTitle)] " : ""

            // 2a. Metric Serving Size & Unit
            let servingID = "col\(colIdx).servingSize"
            let sServingStr = sCol.map { "\(FDADigitalLabelFormatting.formatDecimal($0.servingSize))\($0.servingUnit)" } ?? "Missing Column"
            let eServingStr = eCol.map { "\(FDADigitalLabelFormatting.formatDecimal($0.servingSize))\($0.servingUnit)" } ?? "Removed Column"
            let servingMatches: Bool = {
                guard let s = sCol, let e = eCol else { return false }
                return abs(s.servingSize - e.servingSize) <= 0.015
                    && s.servingUnit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        == e.servingUnit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }()
            if !servingMatches {
                items.append(
                    FullSpectrumFieldDiffItem(
                        id: servingID,
                        columnIndex: colIdx,
                        columnTitle: colTitle,
                        fieldTitle: "\(colPrefix)Serving Size (Metric)",
                        scannedDisplayValue: sServingStr,
                        groundTruthDisplayValue: eServingStr,
                        diffKind: sCol == nil ? .missedByScanner : .correctedValue,
                        verificationStatus: .verifiedIncorrect
                    )
                )
            } else {
                let status: ParameterVerificationStatus = (isVerifiedComplete || manuallyVerifiedFieldIDs.contains(servingID))
                    ? .verifiedCorrect
                    : .unverified
                items.append(
                    FullSpectrumFieldDiffItem(
                        id: servingID,
                        columnIndex: colIdx,
                        columnTitle: colTitle,
                        fieldTitle: "\(colPrefix)Serving Size (Metric)",
                        scannedDisplayValue: sServingStr,
                        groundTruthDisplayValue: eServingStr,
                        diffKind: .exactMatch,
                        verificationStatus: status
                    )
                )
            }

            // 2b. Household Measure
            let hhID = "col\(colIdx).householdMeasure"
            let sHHStr = Self.formatHouseholdMeasure(
                amount: sCol?.commonHouseholdMeasurementAmount,
                unit: sCol?.commonHouseholdMeasurement
            )
            let eHHStr = Self.formatHouseholdMeasure(
                amount: eCol?.commonHouseholdMeasurementAmount,
                unit: eCol?.commonHouseholdMeasurement
            )
            let hhMatches: Bool = {
                guard let s = sCol, let e = eCol else { return false }
                let amtEqual: Bool = {
                    switch (s.commonHouseholdMeasurementAmount, e.commonHouseholdMeasurementAmount) {
                    case (nil, nil): return true
                    case let (a?, b?): return abs(a - b) <= 0.015
                    default: return false
                    }
                }()
                let sUnit = (s.commonHouseholdMeasurement ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let eUnit = (e.commonHouseholdMeasurement ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return amtEqual && (sUnit == eUnit)
            }()
            if !hhMatches {
                items.append(
                    FullSpectrumFieldDiffItem(
                        id: hhID,
                        columnIndex: colIdx,
                        columnTitle: colTitle,
                        fieldTitle: "\(colPrefix)Household Measure",
                        scannedDisplayValue: sHHStr,
                        groundTruthDisplayValue: eHHStr,
                        diffKind: .correctedValue,
                        verificationStatus: .verifiedIncorrect
                    )
                )
            } else {
                let status: ParameterVerificationStatus = (isVerifiedComplete || manuallyVerifiedFieldIDs.contains(hhID))
                    ? .verifiedCorrect
                    : .unverified
                items.append(
                    FullSpectrumFieldDiffItem(
                        id: hhID,
                        columnIndex: colIdx,
                        columnTitle: colTitle,
                        fieldTitle: "\(colPrefix)Household Measure",
                        scannedDisplayValue: sHHStr,
                        groundTruthDisplayValue: eHHStr,
                        diffKind: .exactMatch,
                        verificationStatus: status
                    )
                )
            }

            // 2c. Servings Per Container (evaluated when present in scanned or edited column)
            if sCol?.servingsPerContainer != nil || eCol?.servingsPerContainer != nil {
                let spcID = "col\(colIdx).servingsPerContainer"
                let sSPCStr = sCol?.formattedServingsPerContainerLine ?? "None"
                let eSPCStr = eCol?.formattedServingsPerContainerLine ?? "None"
                let spcMatches: Bool = {
                    switch (sCol?.servingsPerContainer, eCol?.servingsPerContainer) {
                    case (nil, nil): return true
                    case let (a?, b?): return abs(a - b) <= 0.05
                    default: return false
                    }
                }()
                if !spcMatches {
                    items.append(
                        FullSpectrumFieldDiffItem(
                            id: spcID,
                            columnIndex: colIdx,
                            columnTitle: colTitle,
                            fieldTitle: "\(colPrefix)Servings Per Container",
                            scannedDisplayValue: sSPCStr,
                            groundTruthDisplayValue: eSPCStr,
                            diffKind: sCol?.servingsPerContainer == nil ? .missedByScanner : .correctedValue,
                            verificationStatus: .verifiedIncorrect
                        )
                    )
                } else {
                    let status: ParameterVerificationStatus = (isVerifiedComplete || manuallyVerifiedFieldIDs.contains(spcID))
                        ? .verifiedCorrect
                        : .unverified
                    items.append(
                        FullSpectrumFieldDiffItem(
                            id: spcID,
                            columnIndex: colIdx,
                            columnTitle: colTitle,
                            fieldTitle: "\(colPrefix)Servings Per Container",
                            scannedDisplayValue: sSPCStr,
                            groundTruthDisplayValue: eSPCStr,
                            diffKind: .exactMatch,
                            verificationStatus: status
                        )
                    )
                }
            }

            // 3. Canonical FDA Nutrients
            for nutrient in FDADigitalLabelFormatting.canonicalFDASequence {
                let sEntry = sCol?.nutrition.entry(for: nutrient)
                let eEntry = eCol?.nutrition.entry(for: nutrient)
                let isBaselineMacro = (effectiveTopo != .supplementFacts) && baselineCoreNutrients.contains(nutrient)

                guard sEntry != nil || eEntry != nil || isBaselineMacro else {
                    continue
                }

                let fieldID = "col\(colIdx).nutrient.\(nutrient.rawValue)"
                let fieldTitle = "\(colPrefix)\(nutrient.fdaLabelDisplayName)"

                switch (sEntry, eEntry) {
                case let (s?, e?):
                    let sameValue = abs(s.resolvedValue - e.resolvedValue) <= 0.015 && (s.resolvedUnit == e.resolvedUnit)
                    if sameValue {
                        let status: ParameterVerificationStatus = (isVerifiedComplete || manuallyVerifiedFieldIDs.contains(fieldID))
                            ? .verifiedCorrect
                            : .unverified
                        items.append(
                            FullSpectrumFieldDiffItem(
                                id: fieldID,
                                columnIndex: colIdx,
                                columnTitle: colTitle,
                                fieldTitle: fieldTitle,
                                scannedDisplayValue: s.formattedWeightToken(compact: false),
                                groundTruthDisplayValue: e.formattedWeightToken(compact: false),
                                diffKind: .exactMatch,
                                verificationStatus: status
                            )
                        )
                    } else {
                        items.append(
                            FullSpectrumFieldDiffItem(
                                id: fieldID,
                                columnIndex: colIdx,
                                columnTitle: colTitle,
                                fieldTitle: fieldTitle,
                                scannedDisplayValue: s.formattedWeightToken(compact: false),
                                groundTruthDisplayValue: e.formattedWeightToken(compact: false),
                                diffKind: .correctedValue,
                                verificationStatus: .verifiedIncorrect
                            )
                        )
                    }

                case (nil, let e?):
                    items.append(
                        FullSpectrumFieldDiffItem(
                            id: fieldID,
                            columnIndex: colIdx,
                            columnTitle: colTitle,
                            fieldTitle: fieldTitle,
                            scannedDisplayValue: "Missed (Not Scanned)",
                            groundTruthDisplayValue: e.formattedWeightToken(compact: false),
                            diffKind: .missedByScanner,
                            verificationStatus: .verifiedIncorrect
                        )
                    )

                case (let s?, nil):
                    items.append(
                        FullSpectrumFieldDiffItem(
                            id: fieldID,
                            columnIndex: colIdx,
                            columnTitle: colTitle,
                            fieldTitle: fieldTitle,
                            scannedDisplayValue: s.formattedWeightToken(compact: false),
                            groundTruthDisplayValue: "Removed (False Positive)",
                            diffKind: .removedFalsePositive,
                            verificationStatus: .verifiedIncorrect
                        )
                    )

                case (nil, nil):
                    let zeroToken = nutrient == .calories ? "0 kcal" : "0\(nutrient.primaryUnit.rawValue)"
                    let status: ParameterVerificationStatus = (isVerifiedComplete || manuallyVerifiedFieldIDs.contains(fieldID))
                        ? .verifiedCorrect
                        : .unverified
                    items.append(
                        FullSpectrumFieldDiffItem(
                            id: fieldID,
                            columnIndex: colIdx,
                            columnTitle: colTitle,
                            fieldTitle: fieldTitle,
                            scannedDisplayValue: zeroToken,
                            groundTruthDisplayValue: zeroToken,
                            diffKind: .exactMatch,
                            verificationStatus: status
                        )
                    )
                }
            }

            // 4. Supplement Facts Tier-2 (b)(3) Non-RDI Ingredients
            let sTier2 = sCol?.nutrition.supplementTier2Entries ?? []
            let eTier2 = eCol?.nutrition.supplementTier2Entries ?? []
            var handledTier2Keys: Set<String> = []

            for eIng in eTier2 {
                let rawName = (eIng.customName ?? "Proprietary Ingredient").trimmingCharacters(in: .whitespacesAndNewlines)
                let key = rawName.lowercased()
                handledTier2Keys.insert(key)
                let fieldID = "col\(colIdx).tier2.\(key)"
                let matchedScanned = sTier2.first {
                    ($0.customName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key
                }

                if let sIng = matchedScanned {
                    let sameVal = abs(sIng.resolvedValue - eIng.resolvedValue) <= 0.015 && (sIng.resolvedUnit == eIng.resolvedUnit)
                    if sameVal {
                        let status: ParameterVerificationStatus = (isVerifiedComplete || manuallyVerifiedFieldIDs.contains(fieldID))
                            ? .verifiedCorrect
                            : .unverified
                        items.append(
                            FullSpectrumFieldDiffItem(
                                id: fieldID,
                                columnIndex: colIdx,
                                columnTitle: colTitle,
                                fieldTitle: "\(colPrefix)\(rawName)",
                                scannedDisplayValue: sIng.formattedWeightToken(compact: false),
                                groundTruthDisplayValue: eIng.formattedWeightToken(compact: false),
                                diffKind: .exactMatch,
                                verificationStatus: status
                            )
                        )
                    } else {
                        items.append(
                            FullSpectrumFieldDiffItem(
                                id: fieldID,
                                columnIndex: colIdx,
                                columnTitle: colTitle,
                                fieldTitle: "\(colPrefix)\(rawName)",
                                scannedDisplayValue: sIng.formattedWeightToken(compact: false),
                                groundTruthDisplayValue: eIng.formattedWeightToken(compact: false),
                                diffKind: .correctedValue,
                                verificationStatus: .verifiedIncorrect
                            )
                        )
                    }
                } else {
                    items.append(
                        FullSpectrumFieldDiffItem(
                            id: fieldID,
                            columnIndex: colIdx,
                            columnTitle: colTitle,
                            fieldTitle: "\(colPrefix)\(rawName)",
                            scannedDisplayValue: "Missed (Not Scanned)",
                            groundTruthDisplayValue: eIng.formattedWeightToken(compact: false),
                            diffKind: .missedByScanner,
                            verificationStatus: .verifiedIncorrect
                        )
                    )
                }
            }

            for sIng in sTier2 {
                let rawName = (sIng.customName ?? "Proprietary Ingredient").trimmingCharacters(in: .whitespacesAndNewlines)
                let key = rawName.lowercased()
                guard !handledTier2Keys.contains(key) else { continue }
                let fieldID = "col\(colIdx).tier2.\(key)"
                items.append(
                    FullSpectrumFieldDiffItem(
                        id: fieldID,
                        columnIndex: colIdx,
                        columnTitle: colTitle,
                        fieldTitle: "\(colPrefix)\(rawName)",
                        scannedDisplayValue: sIng.formattedWeightToken(compact: false),
                        groundTruthDisplayValue: "Removed (False Positive)",
                        diffKind: .removedFalsePositive,
                        verificationStatus: .verifiedIncorrect
                    )
                )
            }
        }

        return items
    }

    private static func formatHouseholdMeasure(amount: Double?, unit: String?) -> String {
        let trimmedUnit = (unit ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let amt = amount, !trimmedUnit.isEmpty {
            return "\(FDADigitalLabelFormatting.formatDecimal(amt)) \(trimmedUnit)"
        }
        if let amt = amount {
            return FDADigitalLabelFormatting.formatDecimal(amt)
        }
        if !trimmedUnit.isEmpty {
            return trimmedUnit
        }
        return "None (nil)"
    }
}
