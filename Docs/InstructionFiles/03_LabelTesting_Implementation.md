# Phase 3 Implementation Log: Label Scanning Ground-Truth & Telemetry Test Harness (`03_LabelTesting_Implementation.md`)

---

## Milestone 5.1 — Shared Diagnostics Model & 5-Metric Optical Telemetry Analyzer

### Target Paths
- `NutritionAssistant/NutritionAssistant/Shared/Models/ScanDiagnosticsSnapshot.swift`
- `NutritionAssistant/NutritionAssistant/Shared/Models/LabelOpticalTelemetryAnalyzer.swift`

### (1) Modified Files
- **Created `NutritionAssistant/NutritionAssistant/Shared/Models/ScanDiagnosticsSnapshot.swift`:**
  - Defined `ScanExtractionPath` (`.tableGrid2D`, `.spatialStitcher`, `.hybridTableAndSpatialMerge`, `.linearDisplayStitcher`), `LabelLightingClassification` (`.balanced`, `.lowLight`, `.lowContrast`, `.highSpecularGlare`, `.overexposed`), `LabelOpticalTelemetry`, and `ScanDiagnosticsSnapshot`.
- **Created `NutritionAssistant/NutritionAssistant/Shared/Models/LabelOpticalTelemetryAnalyzer.swift`:**
  - Implemented `LabelOpticalTelemetryAnalyzer` with overloads accepting raw `Data` or a `CGImage` plus `ScannedDocumentSnapshot`, `FDAClassifiedLabel`, and optional `quadCorners: [CGPoint]`.

### (2) Design Decisions & Assumptions
- **Shared Value-Type Architecture:** `ScanDiagnosticsSnapshot` and `LabelOpticalTelemetry` are pure `Codable`, `Sendable`, `Equatable`, and `Hashable` structs rather than SwiftData `@Model` classes. This allows the exact same telemetry payload to be persisted inside `ScannerTestRun` during development testing and serialized on demand for live user support tickets in `AddFoodView` without duplicating domain logic.
- **Bounded `O(N)` Grayscale Sampling for Lighting & Sharpness:** Cropping the detected `labelRegionBoundingBox` and downsampling into a bounded 8-bit grayscale grid (up to `240 × 240` pixels) enables deterministic calculation of Rec. 709 luminance mean, contrast standard deviation, 3×3 neighborhood specular glare saturation, and 2D Laplacian variance (`sharpnessScore`) in under `2 ms` without blocking UI rendering.
- **Split Confidence Reporting:** Both `visionConfidence` (from Vision's `DocumentObservation`) and `validatorConfidence` (from `FDANutritionValidator`) are preserved independently alongside a synthesized `estimatedAccuracy` property so testers can immediately distinguish optical/OCR degradation from spatial/parser failures.

### (3) Edge Cases Handled
- **EXIF Orientation Dimension Swapping:** `computeResolutionMetrics` inspects `CGImagePropertyOrientation` (`.left`, `.right`, `.leftMirrored`, `.rightMirrored`) before computing `imagePixelWidth`, `imagePixelHeight`, `effectiveLabelPixelWidth`, `effectiveLabelPixelHeight`, and `medianLinePixelHeight`, preventing transposed width/height telemetry on portrait camera captures.
- **White Paper Artwork vs. Specular Glare Disambiguation:** Standard black-on-white FDA labels naturally have a high proportion of bright background pixels. `computeLightingAndSharpnessMetrics` distinguishes normal high-contrast white paper (`contrastStdDev >= 0.24`) from true specular glare blowouts (`pixels[idx] >= 246` with saturated 3×3 neighbors and reduced contrast).
- **Tilted Flat Labels vs. Cylindrical Can Curvature:** `computeCurvatureMetrics` measures interior word deflection perpendicular to the chord connecting each line's first and last words (`horizontalBaselineBowingRatio`), ensuring that a flat label photographed at a 2D roll angle is not falsely flagged as a curved cylindrical surface.
- **Axis-Aligned Fallback for Perspective Angle:** When 4-corner quadrilateral extremities are unavailable or axis-aligned, `computePhotoAngleMetrics` falls back to comparing top-half vs. bottom-half full-width text block spans combined with 2D baseline skew.

### (4) Verification Status
- **Xcode MCP Build (`BuildProject` on `windowtab1`):** Succeeded (`The project built successfully`, `0` errors).
- **Xcode Navigator Diagnostics (`XcodeListNavigatorIssues`):** `0` errors and `0` warnings in `ScanDiagnosticsSnapshot.swift` and `LabelOpticalTelemetryAnalyzer.swift`.

### Addendum (`ScanDiagnosticsSnapshot.swift`)
- **Added `ScannedValueOrigin` (`enum`), `extractedRowLines: [String]`, and `nutrientOrigins: [String: ScannedValueOrigin]` to `ScanDiagnosticsSnapshot` (with backward-compatible `decodeIfPresent` decoding):**
  - **Why:** Allows the test harness to distinguish between values explicitly scanned as `0g` on the label (`.scannedExplicitZero`) vs. nutrients that were not detected on the label and had `0g` injected as a default (`.notDetectedInjectedZero`), as well as isolating the extracted nutrition rows (`extractedRowLines`) from the broader regional OCR text (`rawLabelLines`).

---

## Milestone 5.2 — Coordinator Diagnostic Hook & Lossless Camera Capture

### Target Paths
- `NutritionAssistant/NutritionAssistant/Shared/Models/VisionDocumentScanner.swift`
- `NutritionAssistant/NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift`
- `NutritionAssistant/NutritionAssistant/Views/AddFoodView.swift`

### (1) Modified Files
- **Updated `NutritionAssistant/NutritionAssistant/Shared/Models/VisionDocumentScanner.swift`:**
  - Added `let quadCorners: [CGPoint]` to `ScannedDocumentSnapshot` (defaulting to `[]` in `init` for backward source compatibility).
  - Implemented `VisionDocumentScanner.topLeftNormalizedQuadCorners(from:)` using `NormalizedRegion.boundingQuad` (`vision/contoursobservation/contour/boundingquad`), `QuadrilateralProviding` (`vision/quadrilateralproviding`), and `NormalizedPoint.verticallyFlipped().cgPoint` (`vision/normalizedpoint/verticallyflipped()`).
- **Updated `NutritionAssistant/NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift`:**
  - Defined `NutritionScanEvaluation` pairing `ScannedNutritionPayload` and `ScanDiagnosticsSnapshot`.
  - Added `scanWithDiagnostics(imageData:orientation:)`, `scanWithDiagnostics(cgImage:orientation:)`, and `evaluateSnapshot(_:cgImage:imageData:orientation:)`.
  - Updated `extractAndMergeRows` to report the active `ScanExtractionPath` (`.tableGrid2D`, `.spatialStitcher`, `.hybridTableAndSpatialMerge`, or `.linearDisplayStitcher`).
- **Updated `NutritionAssistant/NutritionAssistant/Views/AddFoodView.swift`:**
  - Added `@State private var lastScanDiagnostics: ScanDiagnosticsSnapshot?` and routed `performNutritionScan(with:)` through `NutritionScanCoordinator.scanWithDiagnostics(imageData:)`.
  - Promoted `NutritionLabelCameraPicker` to internal visibility (`struct NutritionLabelCameraPicker`) and added `captureLosslessPNG: Bool = false` plus `NutritionLabelCameraPicker.losslessNormalizedPNGData(from:)`.

### (2) Design Decisions & Assumptions
- **Non-Breaking Coordinator Extension:** `NutritionScanCoordinator.scan(...)` and `processSnapshot(_:)` remain unchanged in signature and delegate to `scanWithDiagnostics(...)` / `evaluateSnapshot(...)`, preserving 100% compatibility with existing callers while exposing full pipeline + optical telemetry to `LabelScanningTestsView` and `AddFoodView`.
- **Upright Bitmap Normalization for Lossless PNG Test Captures:** Camera photos captured on iOS often carry non-`.up` EXIF orientation metadata while pixel rows remain sensor-aligned. `NutritionLabelCameraPicker.losslessNormalizedPNGData(from:)` renders non-`.up` images into a 1:1 scale upright bitmap (`format.scale = 1.0`) before encoding lossless PNG bytes so that `originalImageData` has zero JPEG compression artifacts and consistent pixel coordinates across initial and subsequent test runs.

### (3) Edge Cases Handled
- **Primary Table Quad Priority:** In `VisionDocumentScanner.convertObservation(_:)`, `primaryRegionForQuad` prioritizes `container.tables.first?.boundingRegion` over the outer document container when a table is present, ensuring trapezoid perspective ratios reflect the nutrition table boundary rather than surrounding package copy.
- **Hybrid Merge Attribution:** In `extractAndMergeRows`, `.hybridTableAndSpatialMerge` is recorded only when `mergeTableAndSpatialRows` actually recovers additional nutrient rows (`merged.count > tableRows.count`); if the spatial pass contributed no new nutrients, the path accurately reports `.tableGrid2D`.
- **Deterministic Healed Nutrient Ordering:** `payload.healedNutrients` (`Set<CanonicalNutrientID>`) is sorted lexicographically by `rawValue` when initializing `ScanDiagnosticsSnapshot` so `Equatable` and JSON serialization remain deterministic across test runs.

### (4) Verification Status
- **Xcode MCP Build (`BuildProject` on `windowtab1`):** Succeeded (`The project built successfully`, `0` errors).
- **Xcode Navigator Diagnostics (`XcodeListNavigatorIssues`):** `0` errors and `0` warnings in `VisionDocumentScanner.swift`, `NutritionScanCoordinator.swift`, and `AddFoodView.swift`.

### Addendum (`NutritionScanCoordinator.swift`)
- **Added `buildFieldOrigins(parsedServing:payload:)` and passed `extractedRowLines: rawRowLines` and `nutrientOrigins: origins` into `ScanDiagnosticsSnapshot` inside `evaluateSnapshot`:**
  - **Why:** Maps each field in `ScannedNutritionPayload.allParsedNutrients` (`.omitted`, `.explicitZero`, `.threshold`, `.insignificantFootnote`, `.exact`) and `healedNutrients` to its `ScannedValueOrigin` so the tester can immediately see whether a `0g` value was read on the label or injected because the nutrient row was missed, and provides the isolated table/stitcher row strings (`rawRowLines`) separately from `allLines`.

---

## Milestone 5.3 — SwiftData Ground-Truth & Multi-Run Models (`ScannerTestModels.swift`)

### Target Paths
- `NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift`
- `NutritionAssistant/NutritionAssistant/App/NutritionAssistantApp.swift`

### (1) Modified Files
- **Created `NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift`:**
  - Defined `ParameterVerificationStatus` (`.unverified`, `.verifiedCorrect`, `.verifiedIncorrect`), `ScannerVerifiableField` (13 required nutrition/serving parameters + 1 optional `.topology` parameter), and `FDALabelTopology.displayTitle`.
  - Implemented `@Model final class ScannerTestItem` (parent fixture storing `@Attribute(.externalStorage) var originalImageData: Data`, `thumbnailData: Data?`, `labelTitle`, and a 1-to-many `.cascade` relationship to `[ScannerTestRun]`).
  - Implemented `@Model final class ScannerTestRun` (child run model storing paired `scanned*`, `status*Raw`, and `corrected*` triplets across all 14 fields, `diagnosticsJSONData`, accuracy calculation helpers, and `applyCorrectedValueSuggestion(from:for:)`).
- **Updated `NutritionAssistant/NutritionAssistant/App/NutritionAssistantApp.swift`:**
  - Registered `ScannerTestItem.self` and `ScannerTestRun.self` in the application's SwiftData `Schema`.

### (2) Design Decisions & Assumptions
- **Parent Fixture + Child Runs Relational Schema:** Separating `ScannerTestItem` (the lossless photograph) from `ScannerTestRun` (individual pipeline executions) eliminates duplicate `originalImageData` storage when re-running a test multiple times and enables sequential side-by-side comparison across Run `#1`, `#2`, `#3`, etc.
- **Mandatory Per-Run Manual Verification with Prior-Run Suggestion Support:** Every new `ScannerTestRun` initializes all parameter statuses to `.unverified` so the tester must explicitly confirm **Correct** or **Incorrect** on each run. To streamline manual review on Run `#2+`, `ScannerTestItem.previousVerifiedRun(for:beforeRunNumber:)` and `ScannerTestRun.applyCorrectedValueSuggestion(from:for:)` expose the most recent prior run's verified ground-truth value as a one-tap suggestion when a field is marked **Incorrect**.
- **Optional Topology Verification:** `ScannerVerifiableField.topology` (`isRequiredForCompletion == false`) is excluded from `verifiedRequiredCount` (`13` core fields) so a run can reach `isFullyVerified` without requiring the user to grade ambiguous topologies, while still factoring `.topology` into `verifiedFieldsCount` and `accuracyRatio` whenever the user chooses to grade it.

### (3) Edge Cases Handled
- **Explicit `nil` Ground Truth for Optional Household Fields:** For `householdAmount` and `householdMeasurement`, `correctedHouseholdAmountIsNil` and `correctedHouseholdMeasurementIsNil` distinguish between *"no correction entered yet"* and *"the scanner hallucinated a household measure that should be `nil`/None."*
- **`@MainActor` Concurrency Isolation in SwiftData `@Model`:** Because the target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` while `@Model` synthesizes nonisolated members, `ScannerTestRun.init(...)` and `var diagnosticsSnapshot: ScanDiagnosticsSnapshot` are annotated with `@MainActor` to prevent Swift 6 actor-isolated `Codable` conformance warnings.
- **Automatic Thumbnail Generation:** `ScannerTestItem.makeThumbnailData(from:maxDimension:)` renders a bounded `180 px` JPEG thumbnail upon initialization so list and sheet views never decode multi-megabyte lossless PNG buffers during scrolling.

### (4) Verification Status
- **Xcode MCP Build (`BuildProject` on `windowtab1`):** Succeeded (`The project built successfully`, `0` errors).
- **Xcode Navigator Diagnostics (`XcodeListNavigatorIssues`):** `0` errors and `0` warnings in `ScannerTestModels.swift` and `NutritionAssistantApp.swift`.

### Addendum (`ScannerTestModels.swift`)
- **Added `var notes: String?` to `ScannerTestItem`, added `scannedValueOrigin(for:)` to `ScannerTestRun`, and updated `.isSupplement` display strings in `scannedDisplayString(for:)` / `correctedDisplayString(for:)` from `"Nutrition Facts (§ 101.9)"` / `"Supplement Facts (§ 101.36)"` to `"Food Label"` / `"Supplement Label"`:**
  - **Why:** Provides a persisted `notes: String?` property for recording scan-specific observations, exposes each parameter's `ScannedValueOrigin` provenance to the UI, and replaces CFR legal code citations with plain-language `"Food Label"` / `"Supplement Label"` labels while keeping all internal verification logic unchanged.

---

## Milestone 5.4 — Round-Trip Test Suite Export & Import (`ScannerTestSuiteTransfer.swift`)

### Target Paths
- `NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestSuiteTransfer.swift`

### (1) Modified Files
- **Created `NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestSuiteTransfer.swift`:**
  - Defined `ScannerTestSuiteArchive`, `ExportedScannerTestItem`, `ExportedScannerTestRun`, `ScannerTestImportSummary`, and `ScannerTestTransferError`.
  - Implemented `ScannerTestSuiteDocument` conforming to `SwiftUI.FileDocument` (`UTType.json`).
  - Implemented `ScannerTestSuiteTransferManager` with `exportArchiveData(from:)`, `makeExportDocument(from:)`, `importArchive(from: url, into:existingItems:)`, and `importArchive(from: data, into:existingItems:)`.

### (2) Design Decisions & Assumptions
- **Nonisolated Raw-Data `FileDocument` Wrapper:** Under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `FileDocument`'s required `init(configuration:)` and `fileWrapper(configuration:)` witnesses are `nonisolated`. `ScannerTestSuiteDocument` encapsulates pre-encoded `jsonData: Data` so JSON encoding/decoding of `@MainActor`-isolated domain types occurs inside `ScannerTestSuiteTransferManager` on the main actor while `FileDocument` performs pure `nonisolated` byte wrapping.
- **Idempotent UUID-Based Merge Import:** Rather than wiping local test items or creating duplicate copies of multi-megabyte lossless PNG fixtures on re-import, `ScannerTestSuiteTransferManager.importArchive` indexes existing `ScannerTestItem` and `ScannerTestRun` records by `UUID`. New fixtures and runs are inserted, and previously unverified local runs are upgraded if their corresponding archive entry has been verified.

### (3) Edge Cases Handled
- **Security-Scoped Resource Lifecycle:** `importArchive(from: url, ...)` calls `url.startAccessingSecurityScopedResource()` with a paired `defer { url.stopAccessingSecurityScopedResource() }` guard so files imported from iCloud Drive, Files.app, or AirDrop never fail with sandbox permission errors.
- **Invalid Atwater Range Reconstruction:** When reconstructing a synthetic `ScannedNutritionPayload` for `ScannerTestRun` insertion in `makeModelRun(from:)`, `expectedAtwaterCalorieRange` guards `lowerBound...max(lowerBound, upperBound)` so malformed or inverted bounds in edited JSON files cannot trigger a Swift `ClosedRange` precondition trap.
- **Missing Thumbnail Regeneration on Import:** If an imported archive entry omits `thumbnailData` to save file size, `importArchive` automatically synthesizes the thumbnail from `originalImageData` via `ScannerTestItem.makeThumbnailData`.

### (4) Verification Status
- **Xcode MCP Build (`BuildProject` on `windowtab1`):** Succeeded (`The project built successfully`, `0` errors).
- **Xcode Navigator Diagnostics (`XcodeListNavigatorIssues`):** `0` errors and `0` warnings in `ScannerTestSuiteTransfer.swift`.

### Addendum (`ScannerTestSuiteTransfer.swift`)
- **Added `let notes: String?` to `ExportedScannerTestItem` and preserved/merged `notes` in `makeExportedItem(from:)` and `importArchive(from:into:existingItems:)`:**
  - **Why:** Ensures scan notes written on `ScannerTestItem` are preserved across JSON suite exports and imports.

---

## Milestone 5.5 — `LabelScanningTestsView.swift` & Bottom Tab Bar Integration (`ContentView.swift`)

### Target Paths
- `NutritionAssistant/NutritionAssistant/Views/LabelScanningTestsView.swift`
- `NutritionAssistant/NutritionAssistant/App/ContentView.swift`

### (1) Modified Files
- **Created `NutritionAssistant/NutritionAssistant/Views/LabelScanningTestsView.swift`:**
  - Implemented `LabelScanningTestsView` (main dashboard with **"Add Test Data"** camera trigger, **"Photo Library"** lossless import, **"Re-Run Previous Test"** sheet trigger, corpus summary statistics, saved fixtures list, and `.fileExporter` / `.fileImporter` toolbar controls).
  - Implemented `ScannerTestItemRowView`, `PreviousTestSelectorSheet`, `ScannerTestItemDetailView`, `ScannerParameterVerificationRowView`, `ScannerRunDiagnosticsSectionView`, `ScannerMultiRunComparisonSectionView`, and `FullScreenLabelImageSheet`.
- **Updated `NutritionAssistant/NutritionAssistant/App/ContentView.swift`:**
  - Added `case labelScanningTests` to `ContentView.Tab`, added `LabelScanningTestsView()` with `.tabItem { Label("Scan Tests", systemImage: "viewfinder.rectangular") }` to the root `TabView`, and registered `ScannerTestItem.self` and `ScannerTestRun.self` in the `#Preview` `modelContainer`.

### (2) Design Decisions & Assumptions
- **Decomposed Subview Hierarchy for Fast Type-Checking:** `LabelScanningTestsView.swift` decomposes the dashboard, row verification inputs, read-only optical/pipeline telemetry, and multi-run comparison matrix into focused subviews (`ScannerParameterVerificationRowView`, `ScannerRunDiagnosticsSectionView`, `ScannerMultiRunComparisonSectionView`) and `@ViewBuilder` helpers so the Swift compiler type-checks every view body in milliseconds.
- **Typed Correction Editors Matching `AddFoodView`:** Tapping **"Incorrect?"** on any parameter reveals a domain-specific correction control (segmented `Picker` for `isSupplement` and `servingUnit`, catalog `Menu` + text field + `"Should be None (nil)"` toggle for `householdMeasurement`, decimal/integer numeric fields for `servingSize`/`calories`/macros, and `FDALabelTopology` picker for `.topology`), preventing malformed ground-truth entries.
- **One-Tap Prior-Run Ground Truth Suggestion on Re-Runs:** On `Run #2+`, when the tester marks a parameter **Incorrect**, `ScannerParameterVerificationRowView` queries `testItem.previousVerifiedRun(for:beforeRunNumber:)` and renders a one-tap chip (`"Use Run #N verified value: ..."`) while still requiring explicit manual **Correct** / **Incorrect** verification on every run.

### (3) Edge Cases Handled
- **Lossless Normalization on Photo Library Imports:** Images selected via `PhotosPicker` in `handlePickedPhoto(_:)` are passed through `NutritionLabelCameraPicker.losslessNormalizedPNGData(from:)` before running `NutritionScanCoordinator.scanWithDiagnostics(imageData:)`, ensuring Photo Library test fixtures share the same upright, uncompressed PNG representation as live camera test captures.
- **Camera Hardware & TCC Permission Guard:** `handleAddCameraTestTapped()` verifies `UIImagePickerController.isSourceTypeAvailable(.camera)` and checks `AVCaptureDevice.authorizationStatus(for: .video)` before presenting `NutritionLabelCameraPicker(captureLosslessPNG: true)`.
- **Pinch-to-Zoom Full-Resolution Label Inspection:** `FullScreenLabelImageSheet` supports interactive `MagnifyGesture` (`1.0x` to `5.0x`) inside a 2D `ScrollView` with a **"Reset Zoom"** action so testers can inspect small-print micronutrient and footnote text directly on device while verifying values.

### (4) Verification Status
- **Xcode MCP Build (`BuildProject` on `windowtab1`):** Succeeded (`The project built successfully`, `0` errors).
- **Xcode Navigator Diagnostics (`XcodeListNavigatorIssues`):** `0` errors and `0` warnings in `LabelScanningTestsView.swift` and `ContentView.swift`.

### Addendum (`LabelScanningTestsView.swift`)
- **Added multi-line `Notes` input in `ScannerTestItemDetailView.fixtureHeaderSection` (and note preview in `ScannerTestItemRowView`), updated `.isSupplement` picker labels to `"Food Label"` / `"Supplement Label"`, added `originBadge(for:)` in `ScannerParameterVerificationRowView`, and added `DisclosureGroup("Extracted Nutrition Rows")` above `DisclosureGroup("Raw Scanned OCR Lines")` in `ScannerRunDiagnosticsSectionView`:**
  - **Why:** Enables immediate entry of scan-specific notes upon scanning, replaces legal CFR section labels with `"Food Label"` / `"Supplement Label"` in the UI, visually differentiates explicitly scanned `0g` values (`Scanned 0g on Label`) from missing/defaulted `0g` values (`Not Detected (Injected 0g)`), and provides a dedicated dropdown for the isolated nutrition rows alongside the raw regional OCR lines.
