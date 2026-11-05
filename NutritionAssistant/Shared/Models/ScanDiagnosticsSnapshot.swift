//
//  ScanDiagnosticsSnapshot.swift
//  NutritionAssistant
//
//  Milestone 5.1: Shared Diagnostics Model & 5-Metric Optical Telemetry Types
//  Decoupled, Codable diagnostic telemetry snapshot returned alongside ScannedNutritionPayload
//  for both development testing (ScannerTestItem / ScannerTestRun) and live user support tickets.
//

import CoreGraphics
import Foundation

// MARK: - Scan Extraction Path & Lighting Classifications

/// Identifies which internal spatial/table extraction path produced the final `[RawExtractedRow]` array.
enum ScanExtractionPath: String, Codable, CaseIterable, Sendable, Hashable {
    case tableGrid2D = "2D Table Grid"
    case spatialStitcher = "Spatial Row Stitcher"
    case hybridTableAndSpatialMerge = "Hybrid Table + Spatial Merge"
    case linearDisplayStitcher = "Linear Display Stitcher"
}

/// Qualitative summary of label illumination, contrast, and specular glare within the detected label bounding box.
enum LabelLightingClassification: String, Codable, CaseIterable, Sendable, Hashable {
    case balanced = "Balanced"
    case lowLight = "Low Light"
    case lowContrast = "Low Contrast"
    case highSpecularGlare = "Specular Glare Detected"
    case overexposed = "Overexposed"
}

/// Distinguishes whether a scanned value (especially `0` / `0g`) was explicitly read by Vision OCR on the label
/// versus injected as a fallback default because the scanner did not detect that nutrient row.
enum ScannedValueOrigin: String, Codable, CaseIterable, Sendable, Hashable {
    case scannedExact = "Scanned on Label"
    case scannedExplicitZero = "Scanned 0g on Label"
    case notDetectedInjectedZero = "Not Detected (Injected 0g)"
    case thresholdDeclaration = "Threshold (<1g / <0.5g)"
    case insignificantFootnote = "Footnote (Insignificant)"
    case healedFromPercentDV = "Healed via % DV"
    case metricFallbackConversion = "Household-to-Metric Fallback"
    case fallbackDefaultServing = "Not Detected (Default 100g)"

    var isInjectedFallback: Bool {
        switch self {
        case .notDetectedInjectedZero, .fallbackDefaultServing:
            return true
        default:
            return false
        }
    }
}

// MARK: - 5-Metric Optical & Physical Telemetry

/// Captures the 5 physical and optical camera capture metrics for root-cause analysis of OCR and spatial failures:
/// 1. `labelResolution` (effective label pixel dimensions, frame coverage, and median text line pixel height)
/// 2. `labelLighting` (mean luminance, contrast standard deviation, and specular glare clipping ratio)
/// 3. `photoAngle` (horizontal/vertical trapezoid ratios and estimated perspective foreshortening angle)
/// 4. `labelSharpness` (Laplacian / Sobel edge-gradient focus score and blur flag)
/// 5. `labelCurvature` (parabolic horizontal baseline bowing ratio from cylindrical cans/bottles)
struct LabelOpticalTelemetry: Codable, Sendable, Equatable, Hashable {
    // 1. labelResolution
    let imagePixelWidth: Int
    let imagePixelHeight: Int
    let effectiveLabelPixelWidth: Int
    let effectiveLabelPixelHeight: Int
    let labelAreaCoverageRatio: Double
    let medianLinePixelHeight: Double

    // 2. labelLighting
    let meanLuminance: Double
    let contrastStdDev: Double
    let glareClippingRatio: Double
    let lightingClassification: LabelLightingClassification

    // 3. photoAngle
    let horizontalTrapezoidRatio: Double
    let verticalTrapezoidRatio: Double
    let estimatedPerspectiveAngleDegrees: Double

    // 4. labelSharpness
    let sharpnessScore: Double
    let isLikelyBlurred: Bool

    // 5. labelCurvature
    let horizontalBaselineBowingRatio: Double
    let isCurvedSurfaceLikely: Bool

    init(
        imagePixelWidth: Int = 0,
        imagePixelHeight: Int = 0,
        effectiveLabelPixelWidth: Int = 0,
        effectiveLabelPixelHeight: Int = 0,
        labelAreaCoverageRatio: Double = 0.0,
        medianLinePixelHeight: Double = 0.0,
        meanLuminance: Double = 0.5,
        contrastStdDev: Double = 0.2,
        glareClippingRatio: Double = 0.0,
        lightingClassification: LabelLightingClassification = .balanced,
        horizontalTrapezoidRatio: Double = 1.0,
        verticalTrapezoidRatio: Double = 1.0,
        estimatedPerspectiveAngleDegrees: Double = 0.0,
        sharpnessScore: Double = 50.0,
        isLikelyBlurred: Bool = false,
        horizontalBaselineBowingRatio: Double = 0.0,
        isCurvedSurfaceLikely: Bool = false
    ) {
        self.imagePixelWidth = imagePixelWidth
        self.imagePixelHeight = imagePixelHeight
        self.effectiveLabelPixelWidth = effectiveLabelPixelWidth
        self.effectiveLabelPixelHeight = effectiveLabelPixelHeight
        self.labelAreaCoverageRatio = labelAreaCoverageRatio
        self.medianLinePixelHeight = medianLinePixelHeight
        self.meanLuminance = meanLuminance
        self.contrastStdDev = contrastStdDev
        self.glareClippingRatio = glareClippingRatio
        self.lightingClassification = lightingClassification
        self.horizontalTrapezoidRatio = horizontalTrapezoidRatio
        self.verticalTrapezoidRatio = verticalTrapezoidRatio
        self.estimatedPerspectiveAngleDegrees = estimatedPerspectiveAngleDegrees
        self.sharpnessScore = sharpnessScore
        self.isLikelyBlurred = isLikelyBlurred
        self.horizontalBaselineBowingRatio = horizontalBaselineBowingRatio
        self.isCurvedSurfaceLikely = isCurvedSurfaceLikely
    }

    // MARK: - Human-Readable Diagnostic Summaries

    var resolutionSummary: String {
        let coveragePct = Int((labelAreaCoverageRatio * 100.0).rounded())
        let linePx = String(format: "%.1f", medianLinePixelHeight)
        return "\(effectiveLabelPixelWidth)×\(effectiveLabelPixelHeight) px (\(coveragePct)% of \(imagePixelWidth)×\(imagePixelHeight) frame) • \(linePx) px/line"
    }

    var lightingSummary: String {
        let lumaPct = Int((meanLuminance * 100.0).rounded())
        let contrastPct = Int((contrastStdDev * 100.0).rounded())
        let glarePct = String(format: "%.1f", glareClippingRatio * 100.0)
        return "\(lightingClassification.rawValue) (Luma \(lumaPct)%, Contrast \(contrastPct)%, Glare \(glarePct)%)"
    }

    var photoAngleSummary: String {
        let angleStr = String(format: "%.1f°", estimatedPerspectiveAngleDegrees)
        let hRatioStr = String(format: "%.2f", horizontalTrapezoidRatio)
        let vRatioStr = String(format: "%.2f", verticalTrapezoidRatio)
        return "~\(angleStr) perspective (H-Ratio \(hRatioStr), V-Ratio \(vRatioStr))"
    }

    var sharpnessSummary: String {
        let scoreStr = String(format: "%.1f / 100", sharpnessScore)
        return isLikelyBlurred ? "Blurred / Soft Focus (\(scoreStr))" : "Sharp (\(scoreStr))"
    }

    var curvatureSummary: String {
        let bowPct = String(format: "%.2f%%", horizontalBaselineBowingRatio * 100.0)
        return isCurvedSurfaceLikely ? "Curved / Cylindrical (\(bowPct) bow)" : "Flat / Minimal Warp (\(bowPct) bow)"
    }
}

// MARK: - Shared Pipeline & Optical Diagnostics Snapshot

/// Comprehensive diagnostic snapshot produced by `NutritionScanCoordinator` on every scan.
/// Used both in `LabelScanningTestsView` (`ScannerTestRun`) and for live production scan diagnostics.
struct ScanDiagnosticsSnapshot: Codable, Sendable, Equatable, Hashable {
    let visionConfidence: Double
    let validatorConfidence: Double
    let structuralTopology: FDALabelTopology
    let lexicalTopology: FDALabelTopology
    let resolvedTopology: FDALabelTopology
    let extractionPath: ScanExtractionPath
    let labelSkewSlope: Double
    let labelSkewDegrees: Double
    let atwaterCalorieCheckPassed: Bool
    let expectedAtwaterMinCalories: Int
    let expectedAtwaterMaxCalories: Int
    let healedNutrients: [CanonicalNutrientID]
    let diagnostics: [ValidationDiagnostic]
    let discardedWarningCount: Int
    let discardedDecoyCount: Int
    let extractedRowLines: [String]
    let rawLabelLines: [String]
    let nutrientOrigins: [String: ScannedValueOrigin]
    let opticalTelemetry: LabelOpticalTelemetry

    /// Combined estimated accuracy (`0.0 ... 1.0`) synthesizing Vision OCR confidence and Phase 1 validator confidence.
    var estimatedAccuracy: Double {
        let clampedVision = min(max(visionConfidence, 0.0), 1.0)
        let clampedValidator = min(max(validatorConfidence, 0.0), 1.0)
        return (clampedVision * 0.45) + (clampedValidator * 0.55)
    }

    init(
        visionConfidence: Double = 1.0,
        validatorConfidence: Double = 1.0,
        structuralTopology: FDALabelTopology = .standardVertical,
        lexicalTopology: FDALabelTopology = .standardVertical,
        resolvedTopology: FDALabelTopology = .standardVertical,
        extractionPath: ScanExtractionPath = .tableGrid2D,
        labelSkewSlope: Double = 0.0,
        labelSkewDegrees: Double = 0.0,
        atwaterCalorieCheckPassed: Bool = true,
        expectedAtwaterMinCalories: Int = 0,
        expectedAtwaterMaxCalories: Int = 0,
        healedNutrients: [CanonicalNutrientID] = [],
        diagnostics: [ValidationDiagnostic] = [],
        discardedWarningCount: Int = 0,
        discardedDecoyCount: Int = 0,
        extractedRowLines: [String] = [],
        rawLabelLines: [String] = [],
        nutrientOrigins: [String: ScannedValueOrigin] = [:],
        opticalTelemetry: LabelOpticalTelemetry = LabelOpticalTelemetry()
    ) {
        self.visionConfidence = visionConfidence
        self.validatorConfidence = validatorConfidence
        self.structuralTopology = structuralTopology
        self.lexicalTopology = lexicalTopology
        self.resolvedTopology = resolvedTopology
        self.extractionPath = extractionPath
        self.labelSkewSlope = labelSkewSlope
        self.labelSkewDegrees = labelSkewDegrees
        self.atwaterCalorieCheckPassed = atwaterCalorieCheckPassed
        self.expectedAtwaterMinCalories = expectedAtwaterMinCalories
        self.expectedAtwaterMaxCalories = expectedAtwaterMaxCalories
        self.healedNutrients = healedNutrients
        self.diagnostics = diagnostics
        self.discardedWarningCount = discardedWarningCount
        self.discardedDecoyCount = discardedDecoyCount
        self.extractedRowLines = extractedRowLines
        self.rawLabelLines = rawLabelLines
        self.nutrientOrigins = nutrientOrigins
        self.opticalTelemetry = opticalTelemetry
    }

    private enum CodingKeys: String, CodingKey {
        case visionConfidence
        case validatorConfidence
        case structuralTopology
        case lexicalTopology
        case resolvedTopology
        case extractionPath
        case labelSkewSlope
        case labelSkewDegrees
        case atwaterCalorieCheckPassed
        case expectedAtwaterMinCalories
        case expectedAtwaterMaxCalories
        case healedNutrients
        case diagnostics
        case discardedWarningCount
        case discardedDecoyCount
        case extractedRowLines
        case rawLabelLines
        case nutrientOrigins
        case opticalTelemetry
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.visionConfidence = try container.decodeIfPresent(Double.self, forKey: .visionConfidence) ?? 1.0
        self.validatorConfidence = try container.decodeIfPresent(Double.self, forKey: .validatorConfidence) ?? 1.0
        self.structuralTopology = try container.decodeIfPresent(FDALabelTopology.self, forKey: .structuralTopology) ?? .standardVertical
        self.lexicalTopology = try container.decodeIfPresent(FDALabelTopology.self, forKey: .lexicalTopology) ?? .standardVertical
        self.resolvedTopology = try container.decodeIfPresent(FDALabelTopology.self, forKey: .resolvedTopology) ?? .standardVertical
        self.extractionPath = try container.decodeIfPresent(ScanExtractionPath.self, forKey: .extractionPath) ?? .tableGrid2D
        self.labelSkewSlope = try container.decodeIfPresent(Double.self, forKey: .labelSkewSlope) ?? 0.0
        self.labelSkewDegrees = try container.decodeIfPresent(Double.self, forKey: .labelSkewDegrees) ?? 0.0
        self.atwaterCalorieCheckPassed = try container.decodeIfPresent(Bool.self, forKey: .atwaterCalorieCheckPassed) ?? true
        self.expectedAtwaterMinCalories = try container.decodeIfPresent(Int.self, forKey: .expectedAtwaterMinCalories) ?? 0
        self.expectedAtwaterMaxCalories = try container.decodeIfPresent(Int.self, forKey: .expectedAtwaterMaxCalories) ?? 0
        self.healedNutrients = try container.decodeIfPresent([CanonicalNutrientID].self, forKey: .healedNutrients) ?? []
        self.diagnostics = try container.decodeIfPresent([ValidationDiagnostic].self, forKey: .diagnostics) ?? []
        self.discardedWarningCount = try container.decodeIfPresent(Int.self, forKey: .discardedWarningCount) ?? 0
        self.discardedDecoyCount = try container.decodeIfPresent(Int.self, forKey: .discardedDecoyCount) ?? 0
        self.extractedRowLines = try container.decodeIfPresent([String].self, forKey: .extractedRowLines) ?? []
        self.rawLabelLines = try container.decodeIfPresent([String].self, forKey: .rawLabelLines) ?? []
        self.nutrientOrigins = try container.decodeIfPresent([String: ScannedValueOrigin].self, forKey: .nutrientOrigins) ?? [:]
        self.opticalTelemetry = try container.decodeIfPresent(LabelOpticalTelemetry.self, forKey: .opticalTelemetry) ?? LabelOpticalTelemetry()
    }
}
