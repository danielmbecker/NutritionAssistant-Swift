# Phase 4 — `ScannedFoodItem` Full-Spectrum Model & Dynamic FDA Digital Label System Implementation Log

---

## Milestone 6.1 — Full-Spectrum `NutritionProfile` & `@Model final class ScannedFoodItem`

- **Target Path:** `NutritionAssistant/Shared/Models/ScannedFoodItem.swift`

### (1) Modified Files
- **[NEW]** [`NutritionAssistant/Shared/Models/ScannedFoodItem.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift)
  - Defined FDA display and layout extensions on [`CanonicalNutrientID`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L16-L159) (`fdaLabelDisplayName`, `fdaCompactDisplayName`, `isUpperMacronutrientSection`, `isTabularLeftStackNutrient`, `isTabularRightStackNutrient`, `isStandardMandatoryFoodNutrient`, and `omitsPercentDVOnConventionalFood`).
  - Defined [`ScannedNutrientEntry`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L164-L320) (`Codable, Sendable, Equatable, Hashable, Identifiable`) storing `nutrient`, `amount` (`DeclaredNutrientAmount`), `percentDV` (`DeclaredPercentDV`), `customName`, `sourceCompoundDescription`, and `derivedFromPercentDVOnly`, with FDA-compliant formatting helpers (`formattedWeightToken(compact:)` and `formattedPercentDVToken(demographic:isSupplement:)`).
  - Defined [`NutritionProfile`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L325-L601) (`Codable, Sendable, Equatable, Hashable`) encapsulating all 58 `CanonicalNutrientID`s in `entries: [CanonicalNutrientID: ScannedNutrientEntry]` plus `supplementTier2Entries: [ScannedNutrientEntry]` for `21 CFR § 101.36(b)(3)` non-RDI ingredients and proprietary blends, with `.scaled(by:)`, `+` aggregation, and `expectedAtwaterCalorieRange(isSupplement:)`.
  - Defined [`@Model final class ScannedFoodItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L605-L845) with full package metadata, serving & container fields, regulatory topology & demographic context, `nutritionProfileData: Data` (`@MainActor var nutrition: NutritionProfile`), synchronized summary properties, and Copy-on-Edit versioning (`isArchived`, `previousVersionID`, `supersededByID`, `createSupersedingVersion(...)`, and `applyInPlaceUpdate(...)`).
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/FDADomainModels.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDADomainModels.swift#L518-L608)
  - Extended [`ScannedNutritionPayload`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDADomainModels.swift#L519-L608) with default-initialized `servingsPerContainer`, `servingsPerContainerModifier`, `perDayMultiplier`, `allParsedPercentDVs`, `derivedFromPercentDVNutrients`, and `sourceCompounds` so `NutritionProfile(from:)` can ingest full provenance while preserving 100% source compatibility with existing callers.
  - **Addendum (Milestone 6.2):** Added [`ScannedColumnCandidate`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDADomainModels.swift#L612-L636) (`id`, `columnIndex`, `headerTitle`, `servingSizeText`, `isIncludedByDefault`, `payload`) to represent each non-milk product/serving column extracted from Dual-Column (`Examples F, G, H, I`) and Aggregate Variety Pack (`Example E`) labels.
- **[MODIFIED]** [`NutritionAssistant/App/NutritionAssistantApp.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/App/NutritionAssistantApp.swift#L8-L19)
  - Registered `ScannedFoodItem.self` in the SwiftData `Schema`.
- **[MODIFIED]** [`NutritionAssistant/App/ContentView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/App/ContentView.swift#L7-L131)
  - Added `ScannedFoodItem.self` to the `#Preview` `modelContainer`.
  - **Addendum (Milestone 6.5):** Added `case scannedFoodBank` to `ContentView.Tab` and registered `ScannedFoodBankView()` in the bottom `TabView` (`Label("Scanned Bank", systemImage: "barcode.viewfinder")`).

### (2) Design Decisions & Assumptions
- **Composable `NutritionProfile` + Synchronized Summary Fields:** Rather than duplicating 58 flat properties across `ScannedFoodItem`, `RecipeIngredient`, `RecipeItem`, and `ConsumedItem`, `ScannedFoodItem` persists the complete 58-nutrient spectrum in `NutritionProfile` (`nutritionProfileData: Data`) while synchronizing top-level summary fields (`calories`, `fat`, `saturatedFat`, `transFat`, `polyunsaturatedFat`, `monounsaturatedFat`, `cholesterol`, `sodium`, `carb`, `dietaryFiber`, `solubleFiber`, `insolubleFiber`, `totalSugars`, `addedSugar`, `sugarAlcohol`, `protein`) whenever `nutrition` is mutated. This provides zero-overhead SwiftData `@Query` sorting/filtering in `ScannedFoodBankView` and single-call `.scaled(by:)` / `+` math for future recipe and daily log integration.
- **Copy-on-Edit (`new UUID`) Immutable Versioning:** `createSupersedingVersion(...)` mints a new `ScannedFoodItem` with a fresh `UUID`, links `previousVersionID = self.id`, and soft-archives the prior record (`self.isArchived = true`, `self.supersededByID = newVersion.id`) so historical logs and un-updated recipes retain their exact original nutrient profile without polluting active Food Bank queries.
- **Strict `@MainActor` + SwiftData Concurrency Alignment:** Annotated `ScannedFoodItem.init(...)`, `var nutrition: NutritionProfile`, `syncSummaryProperties(from:)`, `createSupersedingVersion(...)`, and `applyInPlaceUpdate(...)` with `@MainActor` so `JSONEncoder`/`JSONDecoder` calls satisfy Swift 6 actor isolation under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

### (3) Edge Cases Handled
- **Omission of `"Not a significant source of..."` Footnote Entries:** `NutritionProfile.init(from:)` filters out `.insignificantFootnote` entries so nutrients listed only in a bottom disclaimer footer do not clutter the rendered digital label with un-printed rows.
- **Read-Only `% DV` Auto-Recalculation & Legal Prohibitions:** `ScannedNutrientEntry.formattedPercentDVToken(demographic:isSupplement:)` suppresses `% DV` on conventional food nutrients where `% DV` is prohibited or unestablished (`Trans Fat`, `Total Sugars`, `Polyunsaturated/Monounsaturated Fat`, `Soluble/Insoluble Fiber`, `Sugar Alcohol`, and infant-restricted nutrients under `21 CFR § 101.9(j)(5)(i)`), preserves `% DV` on `% DV`-only cereal rows (`derivedFromPercentDVOnly`), and dynamically recalculates `% DV` from `FDARegulatoryConstants` when a user edits a nutrient's weight.
- **Standalone `(25mcg)` Folic Acid Formatting:** `formattedWeightToken(compact:)` formats standalone `.folicAcid` rows in parentheses (`"(25mcg)"`) matching `Example M`, while also supporting inline `Folate 40mcg DFE (25mcg folic acid)` secondary unit formatting.

### (4) Verification Status
- **Xcode MCP `BuildProject` (`windowtab1`):** Succeeded (`"The project built successfully."`, `0` errors).
- **Xcode MCP `XcodeListNavigatorIssues` (`windowtab1`):** Verified `0` errors and `0` warnings across all new and modified files (`ScannedFoodItem.swift`, `FDADomainModels.swift`, `NutritionAssistantApp.swift`, `ContentView.swift`).

---

## Milestone 6.2 — Multi-Column & `Example M` Pipeline Upgrades

- **Target Paths:**
  - `NutritionAssistant/Shared/Models/FDADomainModels.swift`
  - `NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift`
  - `NutritionAssistant/Shared/Models/FDANutritionValidator.swift`
  - `NutritionAssistant/Shared/Models/VisionTableRowExtractor.swift`
  - `NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift`

### (1) Modified Files
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/FDADomainModels.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDADomainModels.swift#L612-L636)
  - Defined [`ScannedColumnCandidate`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDADomainModels.swift#L612-L636) to carry per-column `columnIndex`, `headerTitle`, `servingSizeText`, `isIncludedByDefault`, and `payload: ScannedNutritionPayload`.
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift#L419-L455)
  - Added [`isCombinedWithMilkColumnHeader(_ text: String) -> Bool`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift#L422-L454) detecting secondary `"combined with milk / skim milk / fat free milk / 1/2 cup milk / with milk"` column headers (`Example M`).
  - Upgraded [`parseSingleNutrientSlice`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift#L1279-L1399) and [`extractMultiColumnPairs`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift#L1417-L1471) to unpack multi-column `.addedSugars`, merged `"40mcg DFE 10%"` cells (`Example M`), and `% DV`-only micronutrient columns (`["Thiamin", "70%", "70%"]` in `Examples E & M`).
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/FDANutritionValidator.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDANutritionValidator.swift#L584-L758)
  - Upgraded [`buildPayload`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDANutritionValidator.swift#L584-L758) so `% DV`-only RDI micronutrient rows (`Examples E, K, & M`) automatically derive their `mg`/`mcg` weight from `FDARegulatoryConstants.micronutrientRDI(for:demographic:)` (`Weight = (% DV / 100) × RDI`), track `derivedFromPercentDVNutrients`, and populate `allParsedPercentDVs`, `sourceCompounds`, `servingsPerContainer`, `servingsPerContainerModifier`, and `perDayMultiplier`.
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/VisionTableRowExtractor.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/VisionTableRowExtractor.swift#L15-L1005)
  - Added [`ExtractedTableColumnMetadata`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/VisionTableRowExtractor.swift#L16-L27) and [`extractMultiColumnData(from:classifiedLabel:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/VisionTableRowExtractor.swift#L53-L75) to discover all column headers, per-column calorie values (`130, 70, 100` in `Example E`; `170, 300` in `Example F`), and per-column serving weights (`(35g), (19g), (27g)` in `Example E`), while filtering out `Example M` combined-with-milk columns.
  - Fixed [`selectPrimaryColumnCells`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/VisionTableRowExtractor.swift#L574-L607) so `% DV`-only micronutrient rows (`["Thiamin", "70%", "75%"]`) never bleed the second column's `% DV` into Column 0.
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift#L20-L465)
  - Extended [`NutritionScanEvaluation`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift#L21-L35) with `columnCandidates: [ScannedColumnCandidate]`.
  - Updated [`evaluateSnapshot`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift#L103-L465) to build validated `ScannedColumnCandidate`s for all kept (non-milk) columns and normalize `resolvedTopology` from `.dualColumnSameFood` to `.standardVertical` when `Example M`'s milk column is discarded.

### (2) Design Decisions & Assumptions
- **Non-Destructive Multi-Column Extraction:** `VisionTableRowExtractor.extractRows(from:classifiedLabel:)` retains its exact primary-column behavior for existing single-column callers (`AddFoodView` and `ScannerTestHarnessView`), while `VisionTableRowExtractor.extractMultiColumnData(from:classifiedLabel:)` preserves all column cells in `rawCells` and builds per-column metadata for `NutritionScanEvaluation.columnCandidates`.
- **Automatic `Example M` Milk-Column Omission & Topology Normalization:** When `VisionTableRowExtractor.extractColumnMetadata` detects a secondary column header matching `FDALexicalNormalizer.isCombinedWithMilkColumnHeader`, that column is discarded. If only the dry cereal column remains (`columns.count == 1`), `NutritionScanCoordinator` normalizes `resolvedTopology` to `.standardVertical` so the digital label renders solely the dry cereal column.

### (3) Edge Cases Handled
- **`% DV`-Only Micronutrients in Multi-Column Tables (`Examples E & M`):** When Vision omits empty `<td></td>` weight cells on rows like `Thiamin | | 70% | | 75%`, `extractMultiColumnPairs` recognizes each `% DV` cell on an RDI micronutrient row as its own column entry and `FDANutritionValidator.buildPayload` back-calculates the exact `mg`/`mcg` weight from the FDA RDI (`70%` Thiamin -> `0.84 mg`, `10%` Zinc -> `1.1 mg`).
- **Aggregate Variety Pack Per-Column Serving Weights (`Example E`):** `extractPerColumnServingSizeTranscripts` pairs the shared household measure (`1 box`) with each column's parenthesized metric weight (`(35g)`, `(19g)`, `(27g)`) so each saved variety-pack item receives its exact gram weight.
- **Merged `40mcg DFE 10%` Cells & Standalone `folic acid (25mcg)` Rows (`Example M`):** `extractMultiColumnPairs` handles cells containing both weight and `% DV` (`"40mcg DFE 10%"`) as a single column pair without consuming the next column's cell, and parses standalone indented `folic acid | (25mcg)` rows into `.folicAcid`.

### (4) Verification Status
- **Xcode MCP `BuildProject` (`windowtab1`):** Succeeded (`"The project built successfully."`, `0` errors).
- **Xcode MCP `XcodeListNavigatorIssues` (`windowtab1`):** Verified `0` errors and `0` warnings across all modified files.

---

## Milestone 6.3 — Dynamic Digital FDA Label Replica (`FDADigitalLabelView.swift`)

- **Target Path:** `NutritionAssistant/Views/FDADigitalLabelView.swift`

### (1) Modified Files
- **[NEW]** [`NutritionAssistant/Views/FDADigitalLabelView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift)
  - Defined [`FDADigitalLabelColumnDraft`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L20-L115) (`id`, `columnIndex`, `headerTitle`, `isIncluded`, `servingSize`, `servingUnit`, `commonHouseholdMeasurementAmount`, `commonHouseholdMeasurement`, `servingsPerContainer`, `servingsPerContainerModifier`, `perDayMultiplier`, `nutrition: NutritionProfile`), with convenience initializers from `ScannedColumnCandidate` and `ScannedFoodItem`.
  - Implemented [`FDADigitalLabelView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L140-L925) supporting all 6 structural FDA layouts:
    1. **Vertical Standard / Voluntary / Simplified (`Topologies B, C, J, & Example M`)**
    2. **Vertical with Side-by-Side Micronutrients (`Topology D`)**
    3. **Supplement Facts 2-Tier (`21 CFR § 101.36` — Tier-1 `(b)(2)` RDI nutrients + Tier-2 `(b)(3)` other dietary ingredients/proprietary blends with `†`)**
    4. **Horizontal Tabular Overflow (`Topologies A & K` inside `ScrollView(.horizontal)` with Left Sidebar + Parallel Left/Right Macro Stacks + Bullet-Delimited Micronutrients)**
    5. **Unified Multi-Column Matrix (`Topologies E, F, G, H, I` with per-column `✓` Include checkboxes, editable column header titles, per-column serving sizes and calories, and Active Column Highlighting)**
    6. **Linear Display (`Topology L` continuous flow layout with interactive clause chips)**
  - Implemented inline editors ([`FDANutrientInlineEditorSheet`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L964-L1168), [`FDAServingSizeEditorSheet`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L1172-L1281), [`FDAColumnTitleEditorSheet`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L1285-L1324)) and the searchable [`FDAAddNutrientPickerSheet`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L1328-L1434) (`"+ Add Nutrient Line"`).

### (2) Design Decisions & Assumptions
- **Auto-Matched Topology Without Manual Switcher Pill:** Per user confirmation, `FDADigitalLabelView` automatically selects its renderer from `topology`, `isSupplement`, and `columns.count` without exposing a manual topology switcher pill.
- **Strictly Read-Only `% DV` with Live Recalculation:** `% DV` cells on the digital label are non-editable (`Text` only). Inside `FDANutrientInlineEditorSheet`, a live read-only `% Daily Value` preview updates in real time from `FDARegulatoryConstants` as the user types a new weight.
- **Omission of Prose Footers:** Both the `"*The % Daily Value (DV) tells you how much a nutrient..."` footer and `"Not a significant source of..."` disclaimer are omitted from the digital label to maximize vertical clarity.
- **Active Column Highlighting in Unified Multi-Column Matrix:** Tapping any cell, serving size, or column header in column `k` sets `activeColumnIndex = k`, tinting that column's header and vertical cells so the user has unambiguous visual feedback during multi-column editing.

### (3) Edge Cases Handled
- **`% DV`-Only Micronutrient Display (`Examples E, K, & M`):** When `entry.derivedFromPercentDVOnly` is `true`, the digital label displays the scanned `% DV` in the right column alongside a subtle parenthesized derived weight `"(0.84mg)"` on single-column vertical labels (or clean `% DV` in the multi-column matrix), while storing the exact derived `mg`/`mcg` weight in `NutritionProfile`. If the user manually edits that nutrient's weight, `derivedFromPercentDVOnly` resets to `false` and `% DV` recalculates from the edited weight.
- **Standalone Indented `folic acid (25mcg)` (`Example M`) & Inline `Folate` Sub-Declarations (`Example C`):** `verticalSingleNutrientRow` indents standalone `.folicAcid` rows at `Level 1` (`14pt`) with parenthesized weight `"(25mcg)"`, and `FDANutrientInlineEditorSheet` allows adding/editing `Folic Acid (mcg)` directly when editing `Folate`.
- **Blank Manual Label Fallback:** When `FDADigitalLabelView` is opened for manual creation with an empty `NutritionProfile`, `orderedVerticalUpperMacros` automatically seeds the 10 mandatory FDA macronutrient lines (`Total Fat`, `Saturated Fat`, `Trans Fat`, `Cholesterol`, `Sodium`, `Total Carbohydrate`, `Dietary Fiber`, `Total Sugars`, `Added Sugars`, `Protein`) at `0g`/`0mg` so the digital label is immediately ready for tap-to-edit entry.

### (4) Verification Status
- **Xcode MCP `BuildProject` (`windowtab1`):** Succeeded in `3.76s` (`"The project built successfully."`, `0` errors).
- **Xcode MCP `XcodeListNavigatorIssues` (`windowtab1`):** Verified `0` errors and `0` warnings.
- **Addendum (Milestone 6.7):** Added `Codable` and `Hashable` conformance and `init(from payload: ScannedNutritionPayload, id:columnIndex:headerTitle:isIncluded:)` to [`FDADigitalLabelColumnDraft`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L22-L83) so full-spectrum multi-column label drafts can be persisted inside [`FullSpectrumRunVerificationSnapshot`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift#L1185-L1630) and exported in `.json` test archives.

---

## Milestone 6.4 — Scan, Multi-Column Batch Save & Copy-on-Edit Versioning Workflow (`ScannedAddFoodView.swift`)

- **Target Path:** `NutritionAssistant/Views/ScannedAddFoodView.swift`

### (1) Modified Files
- **[NEW]** [`NutritionAssistant/Views/ScannedAddFoodView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift)
  - Implemented [`ScannedAddFoodView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L18-L742) integrating:
    - Camera & Photo Library scanning via [`NutritionScanCoordinator.scanWithDiagnostics(imageData:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/NutritionScanCoordinator.swift#L60-L73) and [`applyScanEvaluation(_:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L703-L725).
    - Package identity (`brandName` with `"Unbranded"` toggle, `name`, `foodVariationGroup`, `processingLevel`, and horizontal `UserFoodCategory` capsule selector).
    - Interactive [`FDADigitalLabelView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L140-L925) card and live Atwater calorie cross-check & nutrient spectrum telemetry card (`expectedAtwaterCalorieRange(isSupplement:)` and `additionalPopulatedNutrientCount`).
    - Multi-column batch-save preview card and batch-save execution ([`performCreateNewItems()`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L561-L598)) for all checked columns (`includedColumns`).
    - Contextual 3-option Copy-on-Edit versioning confirmation dialog when saving edits to an existing `ScannedFoodItem`:
      1. `"Update Existing Recipes"` ([`saveSupersedingVersion(updateExistingRecipes: true)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L601-L633))
      2. `"Keep Original in Existing Recipes"` ([`saveSupersedingVersion(updateExistingRecipes: false)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L601-L633))
      3. `"Typo Fix (Affects Recipes and Historical Logs)"` ([`saveInPlaceTypoFix()`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L636-L664))

### (2) Design Decisions & Assumptions
- **Transparent Multi-Column Naming (`resolvedItemName(for:baseName:)`):** On multi-column panels (`Examples E, F, G, H, I`), if the user leaves `Base Package Name` blank (common on Variety Packs like `Example E` where each column header is already a distinct product name such as `"Wheat Squares Sweetened"`), each checked column saves using its column header title. If the user provides a `Base Package Name` (e.g., `"Brownie Mix"` on `Example F`), each checked column encodes both the base name and column header (`"Brownie Mix — Per 1/4 cup dry mix"`, `"Brownie Mix — Per baked portion"`).
- **Single-Column Normalization Upon Batch Save:** When a multi-column panel is batch-saved into individual `ScannedFoodItem` records, each persisted `ScannedFoodItem` stores its own `columnHeaderTitle` and normalizes its saved `topology` to `.standardVertical` so re-opening that individual saved item renders its single-item nutrition label cleanly.

### (3) Edge Cases Handled
- **Zero Checked Columns Guard:** `isFormValid` requires `!includedColumns.isEmpty` and validates that every checked column resolves to a non-empty name and positive `servingSize`.
- **Active Column Telemetry Synchronization:** When a user taps any cell in column `k` of a multi-column matrix (`activeColumnIndex = k`), the Atwater Calorie Cross-Check card dynamically displays the expected Atwater calorie range and populated nutrient count for column `k`.

### (4) Verification Status
- **Xcode MCP `BuildProject` (`windowtab1`):** Succeeded in `2.33s` (`"The project built successfully."`, `0` errors).
- **Xcode MCP `XcodeListNavigatorIssues` (`windowtab1`):** Verified `0` errors and `0` warnings.

---

## Milestone 6.5 — `ScannedFoodBankView.swift` & `ContentView.swift` Tab Integration

- **Target Paths:**
  - `NutritionAssistant/Views/ScannedFoodBankView.swift`
  - `NutritionAssistant/App/ContentView.swift`

### (1) Modified Files
- **[NEW]** [`NutritionAssistant/Views/ScannedFoodBankView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedFoodBankView.swift)
  - Implemented [`ScannedFoodBankView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedFoodBankView.swift#L32-L355) querying `@Query(filter: #Predicate<ScannedFoodItem> { !$0.isArchived })`.
  - Preserved the compact 4-column macro summary (`Calories | Fat | Carb | Protein`), category grouping, collapsible `foodVariationGroup` sections, and `IconNavigationHelper` jump bar from `FoodBankView`.
  - Added a quick digital-label inspector button (`list.bullet.rectangle.portrait`) and context menu action (`"Inspect / Edit Digital FDA Label"`) opening [`ScannedAddFoodView(existingItem:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L56-L78), plus portion logging via [`RadialHalfSheetSelector`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/RadialHalfSheetSelector.swift).
- **[MODIFIED]** [`NutritionAssistant/App/ContentView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/App/ContentView.swift#L7-L84)
  - Added `case scannedFoodBank` to `ContentView.Tab` and registered `ScannedFoodBankView()` as a dedicated bottom navigation tab (`Label("Scanned Bank", systemImage: "barcode.viewfinder")`).

### (2) Design Decisions & Assumptions
- **Active-Only `@Query` Predicate (`!$0.isArchived`):** Soft-archived `ScannedFoodItem` records created by Copy-on-Edit versioning remain in SwiftData for historical reference integrity, while `@Query(filter: #Predicate<ScannedFoodItem> { !$0.isArchived })` ensures only the latest active version appears in `ScannedFoodBankView`.
- **Dual-Interaction Row Ergonomics:** Tapping a row's leading label icon (or selecting `"Inspect / Edit Digital FDA Label"` from the context menu) opens the full-spectrum digital FDA label in `ScannedAddFoodView`, while tapping the row body opens `RadialHalfSheetSelector` for rapid portion logging.

### (3) Edge Cases Handled
- **Empty State Onboarding:** When no active `ScannedFoodItem` records exist yet, `ScannedFoodBankView` presents a dedicated empty-state callout with a direct `"Scan or Add Food"` action button.
- **Version Indicator Badge (`v2+`):** Items that superseded an earlier version (`item.previousVersionID != nil`) display a subtle `v2+` capsule badge next to their name.

### (4) Verification Status
- **Xcode MCP `BuildProject` (`windowtab1`):** Succeeded in `2.70s` (`"The project built successfully."`, `0` errors).
- **Xcode MCP `XcodeListNavigatorIssues` (`windowtab1`):** Verified `0` errors and `0` warnings.

---

## Milestone 6.6 — Scope Boundary & Stage-2 Full-Application Migration Brief (`05_ScannedFoodItem_FullMigration_Brief.md`)

- **Target Paths:**
  - `05_ScannedFoodItem_FullMigration_Brief.md`
  - `Docs/InstructionFiles/05_ScannedFoodItem_FullMigration_Brief.md`

### (1) Modified Files
- **[NEW]** [`05_ScannedFoodItem_FullMigration_Brief.md`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/05_ScannedFoodItem_FullMigration_Brief.md) (and mirrored at [`Docs/InstructionFiles/05_ScannedFoodItem_FullMigration_Brief.md`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/Docs/InstructionFiles/05_ScannedFoodItem_FullMigration_Brief.md))
  - Documented the exact scope boundary between Phase 4 (Milestones 6.1–6.5) and Phase 5 (Stage 2 Full-Application Migration).
  - Provided a 4-step architectural handoff roadmap covering [`RecipeIngredient`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/RecipeItem.swift#L28-L65), [`RecipeItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/RecipeItem.swift#L67-L163), [`AddRecipieView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/AddRecipieView.swift), [`RecipeBankView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/RecipeBankView.swift), [`ConsumedItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ConsumedItem.swift), [`TodayView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/TodayView.swift), [`HistoryView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/HistoryView.swift), and idempotent legacy [`FoodItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FoodItem.swift) data migration.

### (2) Design Decisions & Assumptions
- **Parallel-Slice Handoff Clarity:** Explicitly mapped how [`NutritionProfile.scaled(by:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L569-L639) and [`NutritionProfile.+`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L642-L725) replace the 8 flat macro accumulators across `RecipeItem`, `RecipeBankView`, `ConsumedItem`, and `TodayView`.
- **Copy-on-Edit Recipe Propagation Specification:** Detailed how [`ScannedAddFoodView.saveSupersedingVersion(updateExistingRecipes:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L601-L633) will update `RecipeIngredient` entries in `RecipeItem.ingredients` and `RecipeItem.additives` once `RecipeIngredient` embeds `NutritionProfile`.

### (3) Edge Cases Handled
- **Backward Compatibility for Historical Logs & Encoded Ingredients:** Specified fallback synthesis of `NutritionProfile` from the 8 legacy macro fields when decoding older `RecipeIngredient` or `ConsumedItem` records created prior to Phase 5.
- **UUID Preservation During `FoodItem -> ScannedFoodItem` Migration:** Specified preserving `FoodItem.id` when migrating to `ScannedFoodItem` so existing `RecipeIngredient.foodItemID` references remain valid without orphan links.

### (4) Verification Status
- **Xcode MCP `BuildProject` (`windowtab1`):** Succeeded in `0.54s` (`"The project built successfully."`, `0` errors).
- **Xcode MCP `XcodeListNavigatorIssues` (`windowtab1`):** Verified `0` errors and `0` warnings.

---

## Milestone 6.7 — Full-Spectrum Digital-Label Verification & Grading in `LabelScanningTestsView` (Option B)

- **Target Paths:**
  - `NutritionAssistant/Views/FDADigitalLabelView.swift`
  - `NutritionAssistant/Shared/Models/ScannerTestModels.swift`
  - `NutritionAssistant/Shared/Models/ScannerTestSuiteTransfer.swift`
  - `NutritionAssistant/Views/LabelScanningTestsView.swift`

### (1) Modified Files
- **[MODIFIED]** [`NutritionAssistant/Views/FDADigitalLabelView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift#L22-L83)
  - Conformed `FDADigitalLabelColumnDraft` to `Codable` and `Hashable` and added `init(from payload: ScannedNutritionPayload, ...)`.
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/ScannerTestModels.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift#L356-L1630)
  - Added optional `var fullSpectrumVerificationJSONData: Data? = nil` to `ScannerTestRun` for non-destructive SwiftData lightweight migration.
  - Defined [`FullSpectrumFieldDiffKind`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift#L1150-L1169), [`FullSpectrumFieldDiffItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift#L1172-L1181), and [`FullSpectrumRunVerificationSnapshot`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift#L1185-L1630) evaluating all header fields, all 58 `CanonicalNutrientID`s, Supplement Facts Tier-2 ingredients, and multi-column candidates (`columnCandidates`).
  - Added `synthesizeLegacyFullSpectrumSnapshot()` and `synchronizeLegacyFields(from:)` so legacy runs and 14-field readers stay synchronized.
- **[MODIFIED]** [`NutritionAssistant/Shared/Models/ScannerTestSuiteTransfer.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestSuiteTransfer.swift#L20-L565)
  - Bumped `ScannerTestSuiteArchive.currentSchemaVersion` to `2` and added optional `fullSpectrumVerification: FullSpectrumRunVerificationSnapshot? = nil` on `ExportedScannerTestRun`.
- **[MODIFIED]** [`NutritionAssistant/Views/LabelScanningTestsView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/LabelScanningTestsView.swift#L636-L1410)
  - Replaced the legacy 14-row parameter list in `ScannerTestItemDetailView` with `digitalLabelVerificationSection(for:)` (embedding `FDADigitalLabelView`), `fullSpectrumDiffBreakdownSection(for:)`, and one-tap `"Auto-Grade Using Verified Ground Truth from Run #X"` carry-over on re-runs.
  - Upgraded `ScannerMultiRunComparisonSectionView` to compare the full-spectrum field catalog across sequential runs.

### (2) Design Decisions & Assumptions
- **Non-Destructive Lightweight Migration:** Storing `fullSpectrumVerificationJSONData: Data? = nil` as an optional attribute on `ScannerTestRun` allows SwiftData to migrate the existing SQLite store in place without requiring app deletion.
- **Direct In-Label Ground-Truth Authoring:** Any inline edit on `FDADigitalLabelView` (editing a nutrient weight, changing serving size/unit, adding a missed nutrient row via `"+ Add Nutrient Line"`, or deleting a false-positive row) automatically classifies that field as `.verifiedIncorrect` (`Corrected`, `Missed by Scanner`, or `Removed False Positive`) with the user's ground-truth value, while `"Confirm Digital Label & Complete Verification"` marks all unedited fields as `.verifiedCorrect`.

### (3) Edge Cases Handled
- **Legacy Run Compatibility (`fullSpectrumVerificationJSONData == nil`):** Earlier test runs created before Milestone 6.7 automatically synthesize a 1-column `FullSpectrumRunVerificationSnapshot` from their saved 14 parameters so they render inside `FDADigitalLabelView` without re-scanning.
- **Legacy v1 `.json` Archive Import:** `ExportedScannerTestRun.fullSpectrumVerification` is optional, allowing v1 `.json` exports to import cleanly and synthesize their full-spectrum snapshot on load.

### (4) Verification Status
- **Xcode MCP `BuildProject` (`windowtab1`):** Succeeded in `9.59s` (`"The project built successfully."`, `0` errors).
- **Xcode MCP `XcodeListNavigatorIssues` (`windowtab1`):** Verified `0` errors and `0` warnings.


