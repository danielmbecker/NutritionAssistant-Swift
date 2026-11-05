# Phase 5 Brief — Full-Application Migration to `ScannedFoodItem` & `NutritionProfile`

## 1. Purpose of This Document

This handoff brief defines the exact boundary between what **Phase 4 (`04_ScannedFoodItem_System_Implimentation.md`, Milestones 6.1–6.5)** delivered and verified, and what remains in **Phase 5 (Stage 2 Full-App Migration)** to transition the entire `NutritionAssistant` application from the legacy 8-macro `FoodItem` model to the full-spectrum `ScannedFoodItem` and `NutritionProfile` architecture.

A subsequent agent should use this brief as its architectural specification when executing the Stage 2 migration.

---

## 2. What Phase 4 Completed & Verified (Scope Included)

Phase 4 established a parallel, end-to-end verified slice for full-spectrum FDA nutrition scanning, interactive digital label inspection/editing, multi-column batch saving, Copy-on-Edit versioning, and bank management:

### 2.1 Full-Spectrum Persistence & Value-Type Math (`ScannedFoodItem.swift`)
- **[`ScannedNutrientEntry`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L204-L370):**
  - Captures exact value or bounded interval (`FDANutrientValue`: `.exact`, `.lessThan`, `.greaterThan`, `.range`, `.trace`), unit (`FDAUnit`), optional explicit `% DV` (`percentDV: Double?`), optional Tier-2 `(b)(3)` non-RDI ingredient name (`customName: String?`), optional chemical compound (`sourceCompoundDescription: String?`, e.g., `"folic acid (25mcg)"`), and `derivedFromPercentDVOnly: Bool`.
  - Provides live `% DV` computation against `FDADailyReferenceValues.value(for:demographic:)` via `computedPercentDV(for:)` and formatted tokens (`formattedWeightToken(compact:)`, `formattedPercentDVToken(demographic:isSupplement:)`).
- **[`NutritionProfile`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L374-L802):**
  - `Codable, Sendable, Equatable, Hashable` dictionary wrapper (`entries: [CanonicalNutrientID: ScannedNutrientEntry]`, `supplementTier2Entries: [ScannedNutrientEntry]`) supporting all 58 `CanonicalNutrientID` cases plus unlimited Supplement Facts Tier-2 botanical/proprietary ingredients.
  - Exposes O(1) convenience properties (`calories`, `fat`, `saturatedFat`, `transFat`, `cholesterol`, `sodium`, `carb`, `dietaryFiber`, `totalSugars`, `addedSugar`, `sugarAlcohol`, `protein`, `vitaminD`, `calcium`, `iron`, `potassium`, etc.).
  - Implements **First-Class Arithmetic Operators**:
    - [`scaled(by factor: Double) -> NutritionProfile`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L569-L639): Scales every `ScannedNutrientEntry` (both exact values and interval bounds) and `supplementTier2Entries` by `factor`.
    - [`+ (lhs: NutritionProfile, rhs: NutritionProfile) -> NutritionProfile`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L642-L725): Sums all matching `CanonicalNutrientID` entries (converting across compatible metric mass units `g` / `mg` / `mcg` when necessary) and merges `supplementTier2Entries` by case-insensitive `customName`.
- **[`@Model final class ScannedFoodItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L806-L1095):**
  - Registered in [`NutritionAssistantApp.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/App/NutritionAssistantApp.swift#L14-L21) and `ContentView` preview containers.
  - Persists package metadata (`name`, `foodVariationGroup`, `categoryRawValue`, `servingSize`, `servingUnitRawValue`, `householdMeasure`), label metadata (`labelTopologyRawValue`, `demographicCategoryRawValue`, `servingsPerContainer`, `servingsPerContainerModifier`, `sourceColumnTitle`, `perDayMultiplier`), JSON-encoded `nutritionProfileData: Data` (`var nutrition: NutritionProfile`), and Denormalized Core Macros for `@Query` predicates.
  - Implements **Copy-on-Edit Versioning**:
    - `isArchived: Bool`, `previousVersionID: UUID?`, `supersededByID: UUID?`.
    - [`createSupersedingVersion(...) -> ScannedFoodItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L1026-L1068) soft-archives `self` (`self.isArchived = true`, `self.supersededByID = newVersion.id`) and returns a newly minted `ScannedFoodItem`.
    - [`applyInPlaceUpdate(...)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannedFoodItem.swift#L1071-L1094) mutates `self` in place for typo fixes.

### 2.2 Multi-Column & `Example M` Vision OCR Pipeline (`FDALexicalNormalizer`, `FDANutritionValidator`, `VisionTableRowExtractor`, `NutritionScanCoordinator`)
- **[`ScannedColumnCandidate`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDADomainModels.swift#L612-L636)** and `NutritionScanEvaluation.columnCandidates: [ScannedColumnCandidate]`:
  - Extracts every distinct food/state column on multi-column labels (`Examples E, F, G, H, I`), including per-column serving weights (`(35g)`, `(19g)`, `(27g)` in `Example E`) and per-column calories.
- **`Example M` Cereal-With-Milk Filtering:**
  - [`FDALexicalNormalizer.isCombinedWithMilkColumnHeader(_:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FDALexicalNormalizer.swift#L130-L152) detects and discards `"with ... milk"` / `"skim milk"` column headers and normalizes single-remaining-column evaluations to `.standardVertical`.
- **`% DV`-Only Micronutrient RDI Derivation:**
  - Unpacks `% DV`-only micronutrient rows (`Examples E, K, & M`, such as `Thiamin 70%`, `Zinc 10%`) and automatically derives their `mg`/`mcg` weight from `FDADailyReferenceValues` (`derivedFromPercentDVNutrients`).

### 2.3 Dynamic Digital FDA Label Replica & Views (`FDADigitalLabelView`, `ScannedAddFoodView`, `ScannedFoodBankView`)
- **[`FDADigitalLabelView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift):**
  - Renders all 6 FDA structural label layouts (`Vertical Standard/Voluntary/Simplified`, `Side-by-Side Micronutrients`, `Supplement Facts 2-Tier`, `Horizontal Tabular Overflow`, `Unified Multi-Column Matrix`, and `Linear Display`) with inline tap-to-edit weights, serving sizes, column titles, `✓` Include column checkboxes, active column highlighting, read-only `% DV`, and `"+ Add Nutrient Line"`.
- **[`ScannedAddFoodView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift):**
  - Supports single-column and multi-column batch saving (`performCreateNewItems()`) and the 3-option Copy-on-Edit versioning dialog (`"Update Existing Recipes"`, `"Keep Original in Existing Recipes"`, `"Typo Fix (Affects Recipes and Historical Logs)"`).
- **[`ScannedFoodBankView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedFoodBankView.swift):**
  - Queries `@Query(filter: #Predicate<ScannedFoodItem> { !$0.isArchived })`, displays compact `Calories | Fat | Carb | Protein` rows with leading digital-label inspector buttons, and supports portion logging via `RadialHalfSheetSelector`.

### 2.4 Full-Spectrum Digital-Label Verification & Grading (`LabelScanningTestsView`, `ScannerTestModels`, `ScannerTestSuiteTransfer` — Milestone 6.7)
- **[`FullSpectrumRunVerificationSnapshot`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ScannerTestModels.swift#L1185-L1630):**
  - Persisted on `ScannerTestRun.fullSpectrumVerificationJSONData: Data? = nil` (optional for non-destructive SwiftData lightweight migration, with automatic fallback synthesis from the 14 legacy fields for earlier runs).
  - Grades `editedColumns` against `scannedColumns` across all columns, header fields, all 58 `CanonicalNutrientID`s, and Supplement Facts Tier-2 ingredients (`Exact Match`, `Corrected`, `Missed by Scanner`, `Removed False Positive`).
- **[`LabelScanningTestsView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/LabelScanningTestsView.swift#L636-L1410):**
  - Embeds [`FDADigitalLabelView`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FDADigitalLabelView.swift) directly inside `ScannerTestItemDetailView` as the interactive ground-truth verification surface, includes one-tap `"Auto-Grade Using Verified Ground Truth from Run #X"` on re-runs, and compares the full-spectrum field catalog across sequential runs in `ScannerMultiRunComparisonSectionView`.

---

## 3. Scope Boundary: What Was Intentionally Left Out of Phase 4

To verify the `ScannedFoodItem` data model and dynamic FDA digital label system without destabilizing existing user workflows, the following areas were intentionally left on the legacy 8-macro `FoodItem` architecture during Phase 4:

| Subsystem | Current State After Phase 4 | Target State in Phase 5 (Stage 2) |
| :--- | :--- | :--- |
| **Legacy `FoodItem`, `FoodBankView`, `AddFoodView`** | Untouched; coexist alongside `ScannedFoodItem`, `ScannedFoodBankView`, and `ScannedAddFoodView`. | One-time migration of existing `FoodItem` records into `ScannedFoodItem`; retire `FoodBankView`, `AddFoodView`, and `FoodItem`. |
| **`RecipeIngredient` & `RecipeItem` (`RecipeItem.swift`)** | `RecipeIngredient` stores `foodItemID: UUID` and 8 flat macro doubles (`calories`, `fat`, `saturatedFat`, `transFat`, `protein`, `carb`, `dietaryFiber`, `addedSugar`). | `RecipeIngredient` embeds `var nutrition: NutritionProfile` and links to `ScannedFoodItem.id`; `RecipeItem` computes full-spectrum `totalNutrition: NutritionProfile` and `servingNutrition: NutritionProfile`. |
| **Copy-on-Edit Recipe Propagation (`ScannedAddFoodView.swift`)** | [`saveSupersedingVersion(updateExistingRecipes:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L601-L633) creates the new `ScannedFoodItem` and archives the old version, with a placeholder (`_ = updateExistingRecipes`) for recipe ingredient updates. | When `updateExistingRecipes == true`, query all `RecipeItem` models and update any `RecipeIngredient` in `ingredients` or `additives` matching `existing.id` to point to `newVersion.id` and `newVersion.nutrition`. |
| **`AddRecipieView` & `RecipeBankView`** | Select ingredients from `@Query private var foodItems: [FoodItem]` and compute 8 flat macros. | Select ingredients from `@Query(filter: #Predicate<ScannedFoodItem> { !$0.isArchived })`, aggregate full `NutritionProfile` across ingredients/additives, and allow inspecting a recipe's per-serving `FDADigitalLabelView`. |
| **`ConsumedItem`, `TodayView`, `HistoryView`** | `ConsumedItem` stores 8 flat macro fields (`ScannedFoodBankView.logScannedFood` currently bridges to the legacy 8-macro `ConsumedItem.init`). | `ConsumedItem` persists `nutritionProfileData: Data` (`var nutrition: NutritionProfile`); `TodayView` and `HistoryView` aggregate daily `NutritionProfile` totals and allow full micronutrient/macro breakdown inspection. |
| **Manual-Entry Ergonomics (`ScannedAddFoodView`)** | Every new item opens the full digital FDA label editor (`FDADigitalLabelView`). | Optional quick-entry or simplified layout toggle for whole/unlabeled produce where a full package label is not needed. |

---

## 4. Step-by-Step Handoff Roadmap for Phase 5 (Stage 2 Full-App Migration)

### Step 5.1 — Upgrade `RecipeIngredient` & `RecipeItem` to Full-Spectrum `NutritionProfile`
- **Target File:** [`NutritionAssistant/Shared/Models/RecipeItem.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/RecipeItem.swift)
- **Required Changes:**
  1. Add `var nutrition: NutritionProfile` (with backward-compatible decoding fallback in `RecipeIngredient` if older encoded `RecipeIngredient` payloads lack `nutrition`) to [`RecipeIngredient`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/RecipeItem.swift#L28-L65).
  2. Add an initializer `init(from scannedFood: ScannedFoodItem, recipeWeight: Double)` on `RecipeIngredient` that snapshots `scannedFood.id`, `scannedFood.name`, `scannedFood.servingSize`, `scannedFood.servingUnit`, and `scannedFood.nutrition` (plus the 8 core macro properties for backward compatibility).
  3. Add a helper on `RecipeIngredient`:
     ```swift
     var scaledNutrition: NutritionProfile {
         let ratio = servingSize > 0 ? (recipeWeight / servingSize) : 1.0
         return nutrition.scaled(by: ratio)
     }
     ```
  4. On [`RecipeItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/RecipeItem.swift#L67-L163), add computed properties leveraging `NutritionProfile.+` and `.scaled(by:)`:
     ```swift
     var totalNutrition: NutritionProfile {
         ingredients.reduce(NutritionProfile.zero) { $0 + $1.scaledNutrition }
     }

     var servingNutrition: NutritionProfile {
         totalNutrition.scaled(by: servingRatio)
     }
     ```
  5. Wire [`ScannedAddFoodView.saveSupersedingVersion(updateExistingRecipes:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedAddFoodView.swift#L601-L633) so that when `updateExistingRecipes == true`:
     - Fetch all `RecipeItem` records from `modelContext`.
     - For every `RecipeItem`, replace any element in `recipe.ingredients` or `recipe.additives` where `ing.foodItemID == existing.id` with a refreshed `RecipeIngredient(from: newVersion, recipeWeight: scaledWeight)` (accounting for any serving size change if applicable).
     - Note: When `"Typo Fix (Affects Recipes and Historical Logs)"` is chosen (`applyTypoFixInPlace()`), clarify whether denormalized snapshots inside `RecipeItem.ingredients` and `ConsumedItem` should also be refreshed in-place across `modelContext`.

### Step 5.2 — Migrate `AddRecipieView` & `RecipeBankView` to `ScannedFoodItem`
- **Target Files:**
  - [`NutritionAssistant/Views/AddRecipieView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/AddRecipieView.swift)
  - [`NutritionAssistant/Views/RecipeBankView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/RecipeBankView.swift)
- **Required Changes:**
  1. In `AddRecipieView`, replace `@Query(sort: \FoodItem.name) private var foodItems: [FoodItem]` with `@Query(filter: #Predicate<ScannedFoodItem> { !$0.isArchived }, sort: \ScannedFoodItem.name) private var scannedFoodItems: [ScannedFoodItem]`.
  2. Update `IngredientSelectorSheet` and additive selection to construct `RecipeIngredient(from: scannedFood, recipeWeight:)` using `ScannedFoodItem`.
  3. Add a `"Preview Recipe Nutrition Facts"` button in `AddRecipieView` and `RecipeBankView` that renders `FDADigitalLabelView` in read-only or preview mode using a single `FDADigitalLabelColumnDraft` built from `recipe.servingNutrition`.
  4. In `RecipeBankView`, replace the 8 separate `@State private var portionBase...` variables (`RecipeBankView.swift:40-47`) with a single `portionBaseNutrition: NutritionProfile` value scaled via `NutritionProfile.scaled(by:)` and summed with confirmed additives via `+`.

### Step 5.3 — Upgrade `ConsumedItem`, `TodayView`, & `HistoryView` to `NutritionProfile`
- **Target Files:**
  - [`NutritionAssistant/Shared/Models/ConsumedItem.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ConsumedItem.swift)
  - [`NutritionAssistant/Views/ScannedFoodBankView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedFoodBankView.swift#L329-L354)
  - [`NutritionAssistant/Views/TodayView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/TodayView.swift)
  - [`NutritionAssistant/Views/HistoryView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/HistoryView.swift)
- **Required Changes:**
  1. Add `@Attribute(.externalStorage) var nutritionProfileData: Data?` and a computed `var nutrition: NutritionProfile` on [`ConsumedItem`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/ConsumedItem.swift#L4-L70). If `nutritionProfileData` is `nil` on legacy historical logs, synthesize a `NutritionProfile` on-the-fly from the 8 legacy macro properties (`calories`, `fat`, `saturatedFat`, `transFat`, `protein`, `carb`, `dietaryFiber`, `addedSugar`) so historical logs never break.
  2. Update [`ScannedFoodBankView.logScannedFood(_:amount:)`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/ScannedFoodBankView.swift#L329-L354) and `RecipeBankView` logging to pass the scaled `NutritionProfile` (`item.nutrition.scaled(by: ratio)`) directly into `ConsumedItem`.
  3. In `TodayView`, compute `private var dailyNutrition: NutritionProfile { consumedItems.reduce(.zero) { $0 + $1.nutrition } }` and allow the user to inspect a full-day `FDADigitalLabelView` (or micronutrient progress breakdown) alongside the existing compact summary header.
  4. When `"Typo Fix (Affects Recipes and Historical Logs)"` is invoked in `ScannedAddFoodView`, optionally add `sourceFoodItemID: UUID?` to `ConsumedItem` so historical logs referencing that `ScannedFoodItem` can also have their scaled `NutritionProfile` recalculated in place.

### Step 5.4 — Legacy `FoodItem` Data Migration & Tab Consolidation
- **Target Files:**
  - [`NutritionAssistant/App/NutritionAssistantApp.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/App/NutritionAssistantApp.swift)
  - [`NutritionAssistant/App/ContentView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/App/ContentView.swift)
  - [`NutritionAssistant/Shared/Models/FoodItem.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Shared/Models/FoodItem.swift)
  - [`NutritionAssistant/Views/FoodBankView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/FoodBankView.swift)
  - [`NutritionAssistant/Views/AddFoodView.swift`](file:///Users/daniel/Documents/dev-work/SwiftUI/NutritionAssistant/NutritionAssistant/Views/AddFoodView.swift)
- **Required Changes:**
  1. Write a one-time idempotent startup migration service (`LegacyFoodItemMigrationService`) that checks if any `FoodItem` records exist in `ModelContext`, converts each `FoodItem` into a `ScannedFoodItem` (preserving its `id: UUID` so existing `RecipeIngredient.foodItemID` links remain valid!), inserts the migrated `ScannedFoodItem`, and deletes or marks the legacy `FoodItem` as migrated.
  2. Consolidate `ContentView.Tab`: replace `.foodBank` (`FoodBankView`) with `ScannedFoodBankView` as the primary `"Food Bank"` tab, and retire `FoodBankView.swift`, `AddFoodView.swift`, and `FoodItem.swift` once the user confirms migration is complete.
