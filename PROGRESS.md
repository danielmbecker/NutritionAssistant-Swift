# PROGRESS.md — Living Memory Bank & Handoff Log

> Companion to `CLAUDE.md`. Read both at session start. Append a handoff entry at session end.

## 1. Current Project State

**Stack:** SwiftUI + SwiftData (iOS 17+), `@Observable`, HealthKit (read-only). Single on-disk `ModelContainer`, 6 `@Model` types. No backend, no networking.

**Active architecture:** 5-tab `TabView` (History, Today, Food Bank, Recipes, Add Recipe). Views query SwiftData directly; `SettingsViewModel` is the only ViewModel; `HealthKitManager.shared` is the only singleton. Settings is a sheet launched from Today/History.

**Recent / major areas of development (inferred from code + `Notes.swift`):**
- Logical-day model (`dayStartHour`, `ConsumedItem.logicalDate`) and `HistoryView` charts (dual-axis Swift Charts, period picker, weekly averages).
- Recipe system: weight vs fraction recipes, additives/extras flow, edited-ingredient logging, variation groups, JSON import/export (`SharingModels.swift`).
- HealthKit dashboard + TDEE/BMR-based caloric goal context (`CaloricContextType`, weight intention) in Settings.
- Macro locks (grams/percent) persisted to `UserSettings`; custom food/recipe categories; CSV import/export for foods and settings.

**Not fully read in the initial scan** (reviewed via targeted grep only): `AddFoodView`, `AddRecipieView`, `CalorieAndMacroSectionView` (lines 120+), `MacroSettingsSectionView`, `RadialHalfSheetSelector`, `FractionSelectionView`, `RecipeWeightsHalfSheetSelector`, `AddExtrasHalfSheetSelector`, `IconNavigationHelper`, `TodayViewVisualDataBar`, `CalorieEtcDataView`, `SingleFoodMetricDisplayView`, `GoalRowView`, `SuffixTextField`, `AnimatedSaveButton`, `Docs/Vision/*`. Read these before editing them.

## 2. Active Known Issues / Tech Debt

| # | Severity | Issue | Files |
|---|---|---|---|
| 1 | **High (bug)** | `@AppStorage("dayStartHour")` in Food/Recipe banks is never written → always 0. Non-zero day start mis-stamps `logicalDate` for newly logged items. Proposed fix: read `UserSettings.first?.dayStartHour` (as Today/History do) or centralize in a helper. | `FoodBankView`, `RecipeBankView`, `UserSettings`, `SettingsView` |
| 2 | Medium | Recipe/portion nutrient math duplicated in 3 places (`RecipeItem` ext, `RecipeBankView`, `TodayView.updateConsumedRecipe`). Extract to one model-layer function. | `RecipeItem`, `RecipeBankView`, `TodayView` |
| 3 | Medium | `UserSettings` singleton enforced by convention; dedupe logic duplicated in `ContentView` and `SettingsViewModel`; `.first` on unsorted `@Query`. | `ContentView`, `SettingsViewModel`, all `userSettingsList.first` users |
| 4 | Medium | Chained sheets rely on `asyncAfter(0.2)` + shared `@State`; known bug that edited recipe weights don't flow into `RadialHalfSheetSelector` base values (see `Notes.swift`). | `RecipeBankView`, `TodayView`, `RadialHalfSheetSelector`, `RecipeWeightsHalfSheetSelector` |
| 5 | Medium | No SwiftData `VersionedSchema`/migration plan; `ModelContainer` failure = `fatalError`; `@Model` properties lack inline defaults (new non-optional fields risk breaking existing stores). | `NutritionAssistantApp`, all `@Model` files |
| 6 | Medium | `SettingsViewModel` is a one-shot copy; CSV import patches only some VM fields (not locks / caloric context / intention). | `SettingsView`, `SettingsViewModel` |
| 7 | Low | HealthKit data not refetched when `dayStartHour` / `healthKitCustomDayWindow` change; only fetched from dashboard `onAppear`. | `HealthKitDashboardView`, `HealthKitManager`, `SettingsView` |
| 8 | Low | `HistoryView.onNavigateToToday` never injected → "Today" back button is a no-op. Unused `Tab.home` case. | `ContentView`, `HistoryView` |
| 9 | Low | `TodayView` can show a stale day if app stays open across the day boundary. | `TodayView` |
| 10 | Low | `HistoryView` recomputes full aggregation (all `ConsumedItem`s) in computed properties each body pass; will degrade with large logs. | `HistoryView` |
| 11 | Low | Denormalized snapshots: edits/deletes of `FoodItem` don't propagate to recipes/history (may be intentional; document the decision). | `ConsumedItem`, `RecipeItem` |
| 12 | Low | Food CSV import: no dedupe, ignores `foodVariationGroup`; "Delete All Food Items" dev button ships in Settings. | `SettingsView` |
| 13 | Low | `AddRecipieView` filename/type typo (`Recipie`); `AppSharingDocumentDTO` private → `TempDecode` re-declared in `SettingsView`. | `AddRecipieView`, `SharingModels`, `SettingsView` |
| 14 | Low | Housekeeping: `Notes.swift`, `test_csv.swift`, `sim_log.txt`, `FDA_FoodLabelGuide.pdf` in repo root; `.DS_Store` present. | repo root |
| 15 | Info | Concurrency: `HealthKitManager` not `@MainActor` (GCD + `NSLock`); verify default actor isolation build setting. | `HealthKitManager`, `SharingModels` |

## 3. Session Handoff Log

> Copy the template below to the TOP of this log (newest first) at the end of each session.

### Template

```
### [YYYY-MM-DD] — <Feature / Task>
**Date/Feature:**
**Files Modified:**
- `path/File.swift` — what/why
**New Cross-File Interactions / Side Effects:**
- (e.g. "FileA writes X which FileB observes via Y"; confirm `CLAUDE.md` updated: yes/no)
**Build/Test Verification:** (Xcode MCP build result, tests run)
**Next Steps for the Next Developer:**
- [ ] ...
```

### Entries

### [2026-10-18] — Initial architecture scan & context files
**Date/Feature:** Created `CLAUDE.md` and `PROGRESS.md` (documentation only).
**Files Modified:** `CLAUDE.md` (new), `PROGRESS.md` (new). No source code changed.
**New Cross-File Interactions / Side Effects:** None introduced; existing ones documented in `CLAUDE.md` §3.
**Build/Test Verification:** N/A (no code changes).
**Next Steps for the Next Developer:**
- [ ] Fix Known Issue #1 (`dayStartHour` dual source of truth) — highest priority.
- [ ] Fully read the "not fully read" files above and extend `CLAUDE.md` §2/§3 as needed.
- [ ] Decide on shared recipe-math extraction (#2) and a SwiftData migration strategy (#5) — present options before coding.
