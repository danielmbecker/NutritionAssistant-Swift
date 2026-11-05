# Phase 2 Instructions: Modern Vision Pipeline, Topological Classification, Spatial Row-Stitching & `AddFoodView` Integration (v1 Scope)

## 0. Mission, Target Environment & Pre-Existing Phase 1 Foundation
You are building the **iOS 26.0 Swift-native Vision pipeline, spatial geometry engine, topological table classifier, and `AddFoodView` integration** that scans real-world `"Nutrition Facts"` (`21 CFR § 101.9`) and `"Supplement Facts"` (`21 CFR § 101.36`) labels via the iPhone camera and auto-populates `AddFoodView.swift` to create a `FoodItem` (`FoodItem.swift`)[cite: 1, 2].

### v1 Scope Boundary (Nutrition & Supplement Panels Only)
- **IN SCOPE for v1:** Scanning `"Nutrition Facts"` and `"Supplement Facts"` panels to populate `AddFoodView` (`isSupplement`, `servingSize`, `servingUnit`, `commonHouseholdMeasurementAmount`, `commonHouseholdMeasurement`, `calories`, `fat`, `saturatedFat`, `transFat`, `carb`, `dietaryFiber`, `addedSugar`, `protein`)[cite: 1, 2].
- **OUT OF SCOPE for v1 (Deferred to v2 & v3):** Do NOT extract or populate `brandName`, `name`, `category`, `processingLevel`, `foodVariationGroup`, or `ingredients` / `ingredientsText`. Leave those fields untouched in `AddFoodView`[cite: 1].

### Pre-Existing Phase 1 Foundation (Read `Phase1_API_Contract.md` First!)
The pure-Swift FDA regulatory domain layer is **already implemented and compiled in this Xcode project** across `FoodItem.swift`, `FDADomainModels.swift`, `FDARegulatoryConstants.swift`, `FDALexicalNormalizer.swift`, and `FDANutritionValidator.swift`[cite: 1].

**Mandatory Step 0 (Before Planning or Reading Vision Docs):**
1. Read `Phase1_API_Contract.md` in full. It contains the exact Swift type declarations, enum cases, struct properties, method signatures, and the **"Phase 2 Integration Recipe"** producing `ScannedNutritionPayload`.
2. Read `AddFoodView.swift` and `FoodItem.swift` to see how form `@State` properties are bound and validated[cite: 1].
3. **Do NOT read the full `.swift` implementation files of Phase 1** unless you encounter a specific compiler diagnostic that `Phase1_API_Contract.md` does not answer. Rely on `Phase1_API_Contract.md` to keep your context window clean for the Vision pipeline.

### Target Deployment & Tooling Environment
- **Minimum Deployment Target:** **iOS 26.0** (strictly hard-pinned)[cite: 1, 2]. Do NOT write `#available(iOS 18, *)` or `#available(iOS 26, *)` availability guards.
- **Modern Swift-Native Vision Only:** Legacy Objective-C `VN*` classes (`VNRequest`, `VNImageRequestHandler`, `VNRecognizeTextRequest`, `VNRecognizedTextObservation`, etc.) are **strictly forbidden**. Use ONLY the modern Swift-native Vision API documented in `Docs/Vision/Vision_Modern_Documentation.md`[cite: 1].
- **Tooling Preference (Xcode MCP & Native Search over Terminal):**
  - Always use **Xcode MCP tools** for creating and editing Swift files, managing Xcode project targets, and running build/compiler diagnostics.
  - Always use **native workspace search (regex/pattern search)** and **bounded line-range file-read tools** to inspect the `.md` reference files. Do NOT spawn bash terminal subshells (`grep`, `awk`, `cat`, `xcodebuild`) unless a native tool or Xcode MCP equivalent does not exist.

---

## 1. The Three Reference Files for Phase 2

### 1a. `Docs/Vision/Vision_Modern_Documentation.md` (Authoritative Vision API, ~1.1 MB, ~25,800 lines, ~278K tokens)
Apple's modern Swift-native Vision API (iOS 18+ / iOS 26.0): `RecognizeDocumentsRequest`, `DocumentObservation`, `RecognizeTextRequest`, `ImageRequestHandler`, `NormalizedRegion`, `NormalizedRect`, `async perform(on:)`[cite: 1]. This API is newer than your training data—**do NOT answer or write signatures from memory.**

**NEVER read this file in full.** Structure:
1. `<framework name="Vision" documentCount="690">` header[cite: 1].
2. `<index>` (lines ~3–700): one line per document, `<entry id="vision/..." kind="..." />`. Holds ids and kinds ONLY (no descriptions or signatures)[cite: 1].
3. `<document id="vision/...">` blocks, one per page. Each block holds:
   - `<title>`, `<kind>` (Structure, Instance Method, Initializer, Enumeration, etc.)[cite: 1].
   - `<status deprecated="true" renamed="X" />`. Appears ONLY when deprecated. If absent, the symbol is NOT deprecated[cite: 1].
   - `<availability>`, e.g., `iOS 18.0+, macOS 15.0+` or `iOS 26.0+`[cite: 1].
   - `<declaration language="swift">`: the exact Swift signature[cite: 1].
   - `<related>`: parent, conformsTo, etc.[cite: 1].
   - `<purpose>`: Apple's one-line summary (~53 pages have an empty purpose; this is Apple's data)[cite: 1].
   - `<content>`: Overview, Parameters, Return Value, Discussion, and a Topics list of members with signatures[cite: 1].

Conventions:
- `ref:<id>` links to another document in the file (e.g., `ref:vision/documentobservation`). A `#Fragment` suffix points to a heading within that page[cite: 1].
- Ids are lowercase. Method ids keep argument labels (`init(_:)`, `perform(on:orientation:)`). Overloads/same-named symbols get suffixes (`-80bya`, `-swift.enum`, `-swift.property`)[cite: 1].
- 290 enum-case pages are folded into their parent enum's page. Look for a case on its parent enum's page (27 cases kept their own document due to differing availability/text)[cite: 1].
- A full `https://developer.apple.com/...` link means that page is NOT in this file. Do not guess its content.

### 1b. `Docs/FDA_Labeling_Guidelines/FDA_Labeling-Guidelines_StructureExamples.md` (Topological Maps, ~550 lines, ~4.5K tokens)
Contains 12 clean, CSS-free HTML table archetypes (`A` through `L`) representing the 2D grid topologies of 21 CFR `§ 101.9`[cite: 1, 2]:
- `A)` Tabular Format (`§ 101.9(d)(11)(iii)`)
- `B)` Standard Vertical Format (`§ 101.9(d)(12)`)
- `C)` Standard Vertical with Voluntary Nutrients (`§ 101.9(d)(12)`)
- `D)` Standard Vertical with Side-by-Side Micronutrients (`§ 101.9(d)(8)`)
- `E)` Aggregate Display — Variety Packs (`§ 101.9(d)(13)(ii)`)
- `F)` Dual-Column Display — Two Forms of the Same Food (`§ 101.9(e)(5)`)
- `G)` Dual-Column Display — Per Serving and Per Container (`§ 101.9(e)(6)(i)`)
- `H)` Dual-Column Display — Per Serving and Per Unit (`§ 101.9(e)(6)(i)`)
- `I)` Tabular Dual-Column Display (`§ 101.9(e)(6)(ii)`)
- `J)` Simplified Display (`§ 101.9(f)(4)`)
- `K)` Tabular Display for Small Packages (`§ 101.9(j)(13)(ii)(A)(1)`)
- `L)` Linear Display for Small Packages (`§ 101.9(j)(13)(ii)(A)(2)`)

### 1c. `Docs/FDA_Labeling_Guidelines/FDA_Labeling Guidelines_summary.md` (Spatial & Visual Rules Reference, ~550 lines, ~9K tokens)
Consult specifically for spatial layout and geometric heuristics not already encapsulated in the Phase 1 text/math modules[cite: 1, 2]:
- `Part 1.1` & `Part 3.4`: Multi-column splits, right-hand continuation panels, and tabular footnotes.
- `Part 1.6`: Visual typography (point-size bounding-box height hierarchy: largest = numeric `"Calories"` value; second largest = `"Calories"` label and `"Nutrition Facts"` title).
- `Part 5.2` & `Part 6.5`: Decoy comparative string rejection and hairline-boxed warning rejection.

---

## 2. Routing Table: Which File to Use

| Question / Task | Where to Look |
|---|---|
| Exact Swift signatures, structs, enums, and call sequence for Phase 1 domain modules | `Phase1_API_Contract.md` (read in full first; do NOT open the raw Phase 1 `.swift` files unless debugging) |
| How `AddFoodView` binds `@State` text fields and saves `FoodItem` | `AddFoodView.swift` & `FoodItem.swift`[cite: 1] |
| Modern Vision types (`RecognizeDocumentsRequest`, `DocumentObservation`, `Table`, `Cell`, `NormalizedRegion`, `NormalizedRect`, `ImageRequestHandler`) | `Docs/Vision/Vision_Modern_Documentation.md`[cite: 1] |
| How multi-column, tabular, dual-column, or aggregate cells span rows/columns | `Docs/FDA_Labeling_Guidelines/FDA_Labeling-Guidelines_StructureExamples.md` (`A`–`L`) + `FDA_Labeling Guidelines_summary.md` (`1.1`, `3.4`)[cite: 1, 2] |
| Bounding-box height ratios (`Calories` vs body text) or warning table rejection | `Docs/FDA_Labeling_Guidelines/FDA_Labeling Guidelines_summary.md` (`1.6`, `5.2`, `6.5`)[cite: 1, 2] |

---

## 3. Search & Read Protocol (Native Workspace Tools Only)
Always search for the narrowest pattern first using native workspace search tools. **Never open `Vision_Modern_Documentation.md` in full, and do not use bash terminal commands (`grep`, `awk`) when native search/read tools are available.**

1. **Known Vision type name:** Use workspace pattern search on `Docs/Vision/Vision_Modern_Documentation.md` for `^<document id="vision/<lowercasename>">` (e.g., `recognizedocumentsrequest`, `documentobservation`) to get the exact starting line number[cite: 1].
2. **Name unknown:** Search the index (lines 1–705) for `<entry id=".*<keyword>` (case-insensitive)[cite: 1].
3. **Concept unknown:** Search purpose lines for `<purpose>.*<keyword>` (case-insensitive)[cite: 1].
4. **Members of a type:** Search the index for `<entry id="vision/<type>/`[cite: 1].
5. **Read the page:** Once you have the starting line number of `<document id="vision/...">`, read a bounded slice of `120–150` lines starting at that line until you reach `</document>`[cite: 1].
6. **Follow a `ref:<id>`:** Return to Step 1 with that id[cite: 1].
7. **Before writing Vision code:** Verify `<declaration>`, `<availability>`, and `<status deprecated>` on the page, and cite the doc `id` used[cite: 1].

---

## 4. Required Deliverables & 5-Milestone Implementation Protocol

When creating your implementation plan, optimize for **architectural modularity and geometric reliability** over minimizing step count. Structure your Phase 2 implementation as **5 sequential file milestones (4.1 through 4.5)**.

For **every single milestone (4.1 through 4.5)**, you MUST execute this exact loop before advancing to the next milestone:
1. **Implement:** Create or update the target `.swift` file via Xcode MCP with complete production logic and zero placeholder stubs.
2. **Verify Compilation:** Run an Xcode MCP build/diagnostic check and resolve all compiler errors before starting the next milestone.

### 4.1 Milestone 1: `VisionDocumentScanner.swift` (Modern Vision Adapter & Defensive Filter)
- **Vision API Lookup First:** Use native workspace search on `Docs/Vision/Vision_Modern_Documentation.md` (following Section 3) to verify the exact signatures for `RecognizeDocumentsRequest`, `DocumentObservation`, `DocumentObservation.Container.Table`, `Table.Cell`, `NormalizedRegion`, and `NormalizedRect`[cite: 1, 2]. Cite the doc `id`s in a file header comment.
- **Async Execution & Defensive Filtering:** Execute `RecognizeDocumentsRequest` asynchronously on the input image. Immediately pass candidate table and paragraph transcripts through Phase 1's `FDALexicalNormalizer` decoy filter (`Part 5.2` relative claim strings) and warning filter (`Part 6.5` `§ 101.17` hairline-boxed warnings) to discard false-positive boxes[cite: 2].
- **Normalized Spatial Snapshot Types:** Convert surviving `DocumentObservation` tables and paragraphs into lightweight, Vision-decoupled Swift structs (`ScannedDocumentSnapshot`, `ScannedTableGrid`, `ScannedTableCell`, and `ScannedTextBlock`) containing plain-text transcripts, `rowRange: ClosedRange<Int>`, `columnRange: ClosedRange<Int>`, and normalized `CGRect` bounding boxes (`minX`, `midY`, `minY`, `maxY`, `width`, `height`)[cite: 2].
- **Milestone Gate:** Verify clean compilation via Xcode MCP before starting Milestone 2.

### 4.2 Milestone 2: `FDALabelTopologyClassifier.swift` (Topology & Sidebar Classifier)
- Inspect `ScannedDocumentSnapshot` (both `tables` and spatially adjacent `textBlocks`) against the 12 HTML archetypes (`A`–`L`) in `FDA_Labeling-Guidelines_StructureExamples.md` and `Part 3` (`Supplement Facts`) of `FDA_Labeling Guidelines_summary.md`[cite: 1, 2].
- **Real-World Sidebar & Header Recovery:** On physical packages (curved cans/bottles or wide Tabular labels `A, I, K`), `RecognizeDocumentsRequest` frequently emits `"Nutrition Facts"` / `"Supplement Facts"`, `"Serving size"`, `"Calories 170"`, or right-hand footnotes as standalone `ScannedTextBlock` paragraphs outside `tables[0]`[cite: 2]. Use normalized bounding-box proximity and `Part 1.6` bounding-box height hierarchy (largest height = numeric `"Calories"` value; second largest = `"Calories"` label and `"Nutrition Facts"` / `"Supplement Facts"` header) to locate and attach header, serving size, and calorie blocks to the candidate label region[cite: 2].
- Output a classification result containing the resolved `FDALabelTopology`, `isSupplement: Bool` (`true` for `Supplement Facts`, `false` for `Nutrition Facts`), isolated serving-size/calorie header transcripts, and a unified `RawExtractedRow` intermediate struct definition used by Milestones 3 and 4[cite: 2].
- **Milestone Gate:** Verify clean compilation via Xcode MCP before starting Milestone 3.

### 4.3 Milestone 3: `VisionTableRowExtractor.swift` (2D Grid Unpacker for `A`–`K` & Supplements)
- Given a classified `ScannedTableGrid` and `FDALabelTopology`, unpack the 2D cell grid (`rowRange`, `columnRange`) into an ordered array of `[RawExtractedRow]` (holding nutrient label transcript, quantitative weight transcript, `% DV` transcript, and relative `minX` indentation level)[cite: 2].
- **Solving the Tabular Horizontal Row Trap (`Topologies A, I, K`):** In `RecognizeDocumentsRequest`, `Table.rows` groups cells by vertical Y-axis alignment, meaning a single horizontal row on a Tabular label contains two side-by-side nutrient stacks (`[Left Nutrient+Wt, Left %DV, Right Nutrient+Wt, Right %DV]`)[cite: 2]. Detect repeated `"Amount/serving"` and `"% Daily Value*"` column headers and split each horizontal row into two independent `RawExtractedRow` records (reading down the left stack, then the right stack)[cite: 2].
- **Dual-Column & Aggregate Column Selection (`Topologies E, F, G, H, I`):** When multiple weight/`% DV` column pairs exist, isolate the primary `"Per Serving"` / `"As Packaged"` column pair (first data column pair) for `FoodItem` extraction, and unpack bullet-delimited (`•`) micronutrient footer rows[cite: 2].
- **Milestone Gate:** Verify clean compilation via Xcode MCP before starting Milestone 4.

### 4.4 Milestone 4: `VisionSpatialRowStitcher.swift` (Curved-Surface Y-Axis Fallback & Linear Parser)
- Build the geometric fallback for when `ScannedDocumentSnapshot.tables` is empty, incomplete, or fractured by cylinder warp (curved bottles, protein powder tubs, flexible pouches) or when the label is `Topology L` (`LinearString`)[cite: 2].
- **Skew-Compensated Y-Axis Row Stitching:**
  - Estimate label tilt/skew slope from header lines or horizontal dividers.
  - Project `ScannedTextBlock` items onto skew-corrected Y-axis bands to pair left-aligned nutrient declarations with horizontally aligned gram weights and right-aligned `% DV` tokens into `[RawExtractedRow]`[cite: 2].
  - Cluster `minX` coordinates to assign Level 0, Level 1, and Level 2 indentation (`Part 1.2`) for sub-nutrients (`Saturated Fat`, `Trans Fat`, `Dietary Fiber`, `Total Sugars`, `Includes Xg Added Sugars`)[cite: 2].
  - Detect vertical column splits on `Topology D` (Side-by-Side Micronutrients) and `Part 3.4` (Right-Hand Supplement Continuation Panels) to de-interleave left and right sub-columns before stitching rows[cite: 2].
  - For `Topology L` (`LinearString`), split continuous comma/parenthesis-delimited paragraph text into `[RawExtractedRow]` records[cite: 2].
- **Milestone Gate:** Verify clean compilation via Xcode MCP before starting Milestone 5.

### 4.5 Milestone 5: `NutritionScanCoordinator.swift` + `AddFoodView.swift` Integration
- Create `NutritionScanCoordinator.swift` to orchestrate Milestones 1–4 and feed the extracted header transcripts and `[RawExtractedRow]` array into Phase 1's `FDALexicalNormalizer` and `FDANutritionValidator` (following the **"Phase 2 Integration Recipe"** in `Phase1_API_Contract.md`) to return a validated `ScannedNutritionPayload`.
- Update `AddFoodView.swift` to add a camera/photo scan trigger that runs `NutritionScanCoordinator` and populates `AddFoodView`'s `@State` properties from `ScannedNutritionPayload`[cite: 1]:
  - `isSupplement` (`Bool?`)
  - `servingSize` formatted cleanly into `@State private var servingSize`
  - `servingUnit` (`"g"` or `"ml"`) into `@State private var servingUnit`
  - `commonHouseholdMeasurementAmount` into `@State private var commonHouseholdMeasurementAmount`
  - `commonHouseholdMeasurement` into `@State private var commonHouseholdMeasurement`
  - `calories`, `fat`, `saturatedFat`, `transFat`, `carb`, `dietaryFiber`, `addedSugar`, `protein` formatted into their corresponding `@State` strings (populating `"0"` rather than `""` for zero values so `AddFoodView`'s Save button validation is immediately satisfied)[cite: 1].
  - Leave `brandName`, `name`, `category`, `processingLevel`, `foodVariationGroup`, and `ingredientsText` untouched for manual entry in v1[cite: 1].
- **Final Gate:** Verify the entire Xcode project compiles with zero errors via Xcode MCP.

---

## 5. Hard Rules
1. **Read `Phase1_API_Contract.md` first—never duplicate Phase 1 modules.** Reuse the models, constants, normalizers, and validators already compiled in Phase 1 without opening the raw Phase 1 `.swift` files unless debugging a compiler error.
2. **Search first, read second (using native tools).** Never open `Vision_Modern_Documentation.md` in full; locate exact line numbers via workspace pattern search and read at most ~150 lines at a time[cite: 1].
3. **Use Xcode MCP for all Swift & project operations.** Create, edit, and compile Swift files through Xcode MCP tools rather than raw shell commands.
4. **Never write a Vision API signature from memory.** Always verify the exact `<declaration>` and `<availability>` in `Vision_Modern_Documentation.md` and cite the doc `id` you used[cite: 1].
5. **Modern Swift-native Vision API only (iOS 26.0 target).** Never use legacy `VN*` classes, and never use a deprecated Vision symbol when a replacement is named[cite: 1].
6. **Zero truncation or placeholder stubs.** Write complete, production-ready Swift implementations and verify the entire target builds cleanly via Xcode MCP.
7. **Report gaps honestly.** If a Vision doc is missing, empty, or only linked as an external URL, state that clearly and ask the user rather than guessing.