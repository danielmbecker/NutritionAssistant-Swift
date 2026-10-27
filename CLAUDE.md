# CLAUDE.md — NutritionAssistant Architecture Cheat Sheet

SwiftUI + SwiftData, iOS 17+ (uses `@Observable`, `#Predicate`). No networking layer. No Combine. No async/await in app code.
Persona/process rules live in `GEMINI.md` (Xcode MCP only for builds; draft architectural changes before writing). Backlog scratchpad: `Notes.swift` (root, not in target).
Source root: `NutritionAssistant/{App,Shared/Models,Shared/Extensions,Views}`. Root also holds `sim_log.txt`, `test_csv.swift`, `Docs/Vision/*` (Vision framework notes, unrelated to runtime).

## 1. High-Level Architecture & Data Flow

**Boot:** `App/NutritionAssistantApp.swift` builds ONE `ModelContainer` (on-disk) with schema
`[FoodItem, ConsumedItem, UserSettings, RecipeItem, UserRecipeCategory, UserFoodCategory]`, `fatalError` on failure.
No `VersionedSchema`/migration plan. Injected via `.modelContainer` → every view uses `@Environment(\.modelContext)` + `@Query`.

**Navigation:** `App/ContentView.swift` = `TabView` (5 tabs): History, Today (default), FoodBank, RecipeBank, AddRecipe.
- `Tab.home` enum case is unused. Settings is NOT a tab: `SettingsView` is a sheet from `TodayView` and `HistoryView` gear buttons.
- Tint comes from `UserSettings.userSelectedPrimaryColorHex` via `Color(hex:)` (`Shared/Extensions/Color+Extensions.swift`).
- Custom `tabBinding` intercepts tab switches: leaving AddRecipe stamps a time; returning after >180s regenerates `addRecipeID` (`.id()` reset) and clears `isAddRecipeDirty`.
- Every sheet/popover is local `@State` in its owning view (`sheet(item:)`/`sheet(isPresented:)`). No router/coordinator.

**Layers (no ViewModel layer except Settings):**
- UI: `Views/*` read SwiftData directly via `@Query` and mutate `@Model` objects in place. Autosave (explicit `try? modelContext.save()` only in a few Settings paths).
- State: `SettingsViewModel` (`@Observable`, owned by `SettingsView` as `@State`) is the ONLY ViewModel. `HealthKitManager.shared` is the only singleton.
- Persistence: SwiftData only (+ CSV via `TabularData` and JSON via `FileDocument` in Settings).
- External: HealthKit read-only (steps, active/basal energy, workouts).

**Core flows:**
1. *Log a food:* `FoodBankView` tap row → `RadialHalfSheetSelector` → `logFood()` snapshots a scaled `ConsumedItem` (stamps `logicalDate`) → `TodayContentView` `@Query` (filtered by `logicalDate == todayLogical`) updates.
2. *Log a recipe:* `RecipeBankView` context menu → [optional `RecipeWeightsHalfSheetSelector` edit] → `RadialHalfSheetSelector` → [optional additive confirm loop or `AddExtrasHalfSheetSelector`] → `logRecipe()` → `ConsumedItem(isRecipe: true)`.
3. *Goals:* `SettingsView` → `SettingsViewModel` copy of `UserSettings` → section views (`CalorieAndMacroSectionView`, `GoalRowView`, `MacroSettingsSectionView`) via `@Binding` + `onSave*` closures → `UserSettings` mutated through `userSettingsList.first`.
4. *History:* `HistoryView` `@Query`s ALL `ConsumedItem`, aggregates by `logicalDate` (O(N+D)) in computed properties on every body pass; goals from `UserSettings`.
5. *Today header:* `TodayViewVisualDataBar` (macro bars) + `HealthKitDashboardView` (burn/steps).

## 2. File Dependency & Coupling Map (READ TOGETHER before editing)

| Domain | Always inspect together |
|---|---|
| **Boot / Schema** | `NutritionAssistantApp.swift`, every `@Model` file (`FoodItem`, `ConsumedItem`, `UserSettings`, `RecipeItem`, `UserFoodCategory`, `UserRecipeCategory`), `ContentView.swift` (UserSettings dedupe) |
| **Day boundary ("logical day")** | `ConsumedItem.swift` (`Date.logicalDay`, `healthKitWindowStart`), `UserSettings.dayStartHour`, `TodayView.swift`, `HistoryView.swift`, `FoodBankView.swift`, `RecipeBankView.swift`, `HealthKitDashboardView.swift`, `HealthKitManager.swift`, `SettingsView.swift` (picker + CSV) |
| **Logging foods** | `FoodBankView.swift`, `RadialHalfSheetSelector.swift`, `FractionSelectionView.swift`, `FoodItem.swift`, `ConsumedItem.swift`, `TodayView.swift` (`updateConsumedItem`), `AddFoodView.swift` |
| **Recipes (model + math)** | `RecipeItem.swift` (`RecipeIngredient`, computed totals, `servingRatio`), `RecipeBankView.swift` (`logRecipe`, `computePortionBaseMacros`, `servingBase*`), `TodayView.swift` (`updateConsumedRecipe`), `AddRecipieView.swift`, `RecipeWeightsHalfSheetSelector.swift`, `AddExtrasHalfSheetSelector.swift`, `ConsumedItem.swift` |
| **Recipe import/export** | `SharingModels.swift` (`RecipeItemDTO`, `AppSharingDocument`), `RecipeItem.swift` (`toDTO`, `init(from:)`), `SettingsView.swift` (`exportRecipeItemsToJSON`/`importRecipeItemsFromJSON`) |
| **Settings / Goals** | `SettingsView.swift`, `SettingsViewModel.swift`, `UserSettings.swift`, `CalorieAndMacroSectionView.swift`, `MacroSettingsSectionView.swift`, `GoalRowView.swift`, `SuffixTextField.swift`, `RadialHalfSheetSelector.swift` (used for custom/intention input), `HealthKitManager.swift` |
| **HealthKit / TDEE** | `HealthKitManager.swift`, `HealthKitDashboardView.swift`, `CalorieAndMacroSectionView.swift` (`computeDailyTarget`, `onChange` of TDEE fields), `UserSettings.swift` (`CaloricContextType`, `healthKitCustomDayWindow`), `NutritionAssistant.entitlements` |
| **Today screen** | `TodayView.swift` (contains `TodayView` + `TodayContentView`), `TodayViewVisualDataBar.swift`, `SingleFoodMetricDisplayView.swift`, `CalorieEtcDataView.swift`, `HealthKitDashboardView.swift` |
| **History charts** | `HistoryView.swift` (private `NC`, `DailySummary`, `WeeklySummaryCard`), `UserSettings.swift`, `ConsumedItem.swift` |
| **Categories / Variation groups** | `FoodItem.swift` (`FoodCategoryList`), `RecipeItem.swift` (`RecipeCategory`), `UserFoodCategory.swift`, `UserRecipeCategory.swift`, `AddFoodView.swift`, `AddRecipieView.swift`, `FoodBankView.swift` (`FoodListItem`), `RecipeBankView.swift` (`RecipeListItem`), `IconNavigationHelper.swift` |
| **CSV import/export** | `SettingsView.swift` (column-name strings are the contract between export & import), `FoodItem.swift`, `UserSettings.swift` |
| **Tab shell / theming** | `ContentView.swift`, `AddRecipieView.swift` (`isDirty`), `Color+Extensions.swift` |

## 3. Non-Obvious Side Effects & Gotchas

1. **TWO sources of truth for day start hour.** `UserSettings.dayStartHour` is what Settings writes and Today/History/HealthKit read. `FoodBankView` and `RecipeBankView` instead use `@AppStorage("dayStartHour")` — NOTHING writes that key, so it is always 0. Any non-zero day-start setting mis-stamps `logicalDate` on newly logged items (item appears on wrong day in Today/History). Fix by reading `UserSettings` (see PROGRESS.md).
2. **`logicalDate` is a permanent stamp.** Changing `dayStartHour` never restamps old items. `TodayView` meal-time edit changes `timestamp` only, not `logicalDate`.
3. **`UserSettings` is a singleton by convention only.** No uniqueness constraint. Code uses `userSettingsList.first` (unsorted `@Query`). Dedupe runs in BOTH `ContentView.onAppear` and `SettingsViewModel.initializeSettingsIfNeeded` (deletes extras). Never `@Query` + `.first` assuming stable order if duplicates can exist.
4. **`SettingsViewModel` is a one-time COPY.** Loaded in `SettingsView.onAppear`; model→VM sync never repeats. External changes to `UserSettings` while open (e.g. CSV import) require manual VM updates (import code manually sets 8 inputs; it does NOT refresh locks/caloric context/intention).
5. **Settings writes rely on autosave.** `save*` methods in `SettingsViewModel` mutate `settingsList.first` directly; only some Settings bindings call `modelContext.save()`.
6. **`HealthKitManager.shared`** (`@Observable`): auth + fetch triggered ONLY from `HealthKitDashboardView.onAppear` (1s delayed, to avoid Simulator privacy timeout). Window params (`healthKitCustomDayWindow`, `dayStartHour`) are captured at fetch time — changing them in Settings does NOT refetch until the dashboard reappears. `CalorieAndMacroSectionView` observes the singleton's TDEE/BMR fields via `.onChange` → `computeDailyTarget()` which may write goal state back through bindings/`onSaveCalories`.
7. **Snapshot (denormalized) data model.** `ConsumedItem` copies all nutrients from `FoodItem`/`RecipeItem`; `RecipeIngredient` (Codable struct, stored inside `RecipeItem.ingredients`/`additives` and `ConsumedItem.recipeIngredients`) copies `FoodItem` fields and holds `foodItemID` as a plain UUID (NOT a relationship). Editing/deleting a `FoodItem` never updates recipes or history.
8. **Recipe/portion math is duplicated** in `RecipeItem` extension, `RecipeBankView` (`logRecipe`, `computePortionBaseMacros`, `servingBase*`, `customizedServingRatio`) and `TodayView.updateConsumedRecipe`. Change one → change all. Fraction semantics: `servingSize < 1` = fraction of batch; `>= 1` = recipe makes N portions (ratio = 1/N). Additives are plate-sized (NOT batch-scaled).
9. **Chained sheets via `asyncAfter(0.2)`** (RecipeBank: edit→portion→extras/additives loop; Today: ingredients→portion). Shared `@State` (`customizedIngredients`, `adjustedAmount`, `adjustedAdditiveAmount`, `additiveConfirmationIndex`) lives in the presenting view — resetting or reordering it breaks the chain. `Notes.swift` records a known bug: weight edits don't propagate to `RadialHalfSheetSelector`'s base values.
10. **`RadialHalfSheetSelector`** has its own `@Query` for `UserSettings` and optional `onAddExtras` (shows an extras button only when non-nil). Used for foods, recipes, additives, settings inputs, and edit portion.
11. **`TodayView` → `TodayContentView` split** exists so `@Query`'s predicate (`logicalDate == todayLogical`) is rebuilt in `init`. `todayLogical` is only recomputed when `TodayView.body` re-evaluates; app left open across the day boundary can show a stale day.
12. **`AddRecipieView` (sic, filename typo)** is both a tab (bound to `ContentView.isAddRecipeDirty`) and a sheet (`.constant(false)`, with `existingRecipe` or `variationSource`). Variations inherit `recipeVariationGroup ?? source.name`. Edit path mutates the `@Model` live (no draft copy) — verify before refactoring.
13. **Variation groups:** `foodVariationGroup` / `recipeVariationGroup` strings group rows into `.group` entries in Bank views; matching is by exact string.
14. **Custom categories** are stored as free strings on items; `UserFoodCategory`/`UserRecipeCategory` are only a picker list. Custom food categories sort last (`displayOrder` → 999). Deleting a custom category does not touch items.
15. **Import/Export contracts:** Recipe JSON root key `"recipes"`; `RecipeItemDTO` optional fields (`additives`, `finalWeightPostponed`) exist for back-compat. `AppSharingDocumentDTO` is `private` so `SettingsView` re-declares a local `TempDecode` — keep keys in sync. Recipe import dedupes by lowercased name; food CSV import does NOT dedupe and ignores `foodVariationGroup`. `UserSettings` CSV exports/imports only goals, types, day start, HK window, color (not locks/caloric context).
16. **`HistoryView.onNavigateToToday`** is never provided by `ContentView` → the "Today" back button is currently a no-op.
17. **SwiftData schema risk:** `@Model` stored properties have no inline defaults (defaults live in `init`). Adding a new non-optional property without a default will break lightweight migration of existing stores; no migration plan exists.
18. **`SettingsView` "Delete All Food Items"** deletes `FoodItem` only (no confirmation of recipe/history impact).

## 4. Core Data Structures & Concurrency Rules

**@Model (SwiftData):**
- `FoodItem`: id, timestamp, brandName, name, processingLevel, servingSize/Unit, calories(Int), fat/satFat/transFat/protein/carb/fiber/addedSugar(Double), category(String), foodVariationGroup?
- `ConsumedItem`: snapshot of nutrients + `timestamp` + `logicalDate` + category + recipe fields (`isRecipe`, `recipeCategory`, `recipeIngredients?`, `recipeAdditives?`, `recipeCustomBatchWeight?`, `recipeRatio`).
- `RecipeItem`: name, type, `measurementType` (`.fraction|.weight`), `ingredients`/`additives` `[RecipeIngredient]`, category, `customBatchWeight?`, `finalWeightPostponed`, `servingSize?`, `recipeVariationGroup?`.
- `UserSettings`: goals + `GoalType` (`.goal|.limit`) per nutrient, `dayStartHour`, `healthKitCustomDayWindow`, `MacroLock` ×3, `CaloricContextType`, `customCaloricBase`, `WeightIntention?`/`Unit`/`Value`, `userSelectedPrimaryColorHex`.
- `UserFoodCategory`, `UserRecipeCategory`: `id`, `name`.
- Non-persisted: `RecipeIngredient` (Codable/Sendable), `RecipeItemDTO`, `AppSharingDocument` (FileDocument), `DailySummary`, `FoodListItem`/`RecipeListItem` enums (single|group).

**State passing:** `@Query` in views (no repository); `@Binding` down into reusable components (`RadialHalfSheetSelector.value`, Settings sections, `AddRecipieView.isDirty`); closures (`onSave`, `onDismiss`, `onNext`, `onSave*`) up; `@State` + `sheet(item:)` for presentation. `@Bindable var x = viewModel` inside `body` for `@Observable` VM bindings.

**Concurrency conventions (as observed):**
- `@Observable` (Observation framework) for non-SwiftData state; NOT `ObservableObject`.
- `HealthKitManager` is NOT `@MainActor`; HK callbacks hop with `DispatchQueue.main.async`; averages use `DispatchGroup` + `NSLock`. Keep UI-bound property writes on main.
- `SharingModels.swift` uses `nonisolated` encode/decode + `Sendable` DTOs (implies default-MainActor isolation build setting — verify in Xcode build settings before adding types).
- `FoodItem.previewData` is `@MainActor`. Delayed UI hops use `DispatchQueue.main.asyncAfter`, not `Task.sleep`.
- All SwiftData access is main-context only. Do not introduce background `ModelContext`s without discussing.

## 5. AI Operating Rules

1. **Read every coupled file** listed for the relevant domain in Section 2 BEFORE proposing or making edits. Grep for symbol usage across `Views/` first; do not re-derive functionality that exists (check `Shared/Models`, `FoodCategoryList`, `Date.logicalDay`, `RadialHalfSheetSelector`).
2. **Update this `CLAUDE.md` immediately** when you introduce a new cross-file dependency, singleton, observer, `@AppStorage` key, notification, shared `@State` chain, or schema change. Also append a Session Handoff entry to `PROGRESS.md`.
3. Keep this file < 200 lines, dense, no prose padding.
4. Architectural changes (schema, state ownership, concurrency model): present options + consequences and get approval first (per `GEMINI.md`).
5. Build/verify only via the Xcode MCP server (never raw `xcodebuild`/`xcrun`).
6. Never add a second source of truth for a `UserSettings` value (see Gotcha #1).
