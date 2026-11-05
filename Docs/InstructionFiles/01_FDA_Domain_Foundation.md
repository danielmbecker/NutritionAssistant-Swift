# Phase 1 Instructions: FDA Regulatory Domain, Lexical Parsers & Self-Healing Math Engine (v1 Nutrition & Supplement Label Scope)

## 0. Mission, Target App Schema (`FoodItem.swift`) & Environment
You are building the **pure-Swift regulatory domain, lexical normalization, and mathematical self-healing validation layer** for a production iOS nutrition and supplement label scanner[cite: 1, 2].

### How This Pipeline Connects to the App (`FoodItem.swift` & `AddFoodView.swift`)
All data extracted by this Vision pipeline exists to **auto-populate `AddFoodView.swift`**, which creates and saves a SwiftData `FoodItem` model (`FoodItem.swift`)[cite: 1].
- **v1 Feature Scope (Nutrition & Supplement Panels Only):**
  - **IN SCOPE for v1:** Conventional `"Nutrition Facts"` (`21 CFR § 101.9`) and Dietary `"Supplement Facts"` (`21 CFR § 101.36`) panels, mapping directly into `FoodItem` / `AddFoodView`[cite: 1, 2].
  - **OUT OF SCOPE for v1 (Deferred to v2 & v3):** Front-of-pack Principal Display Panel (PDP) brand/product metadata (`Part 6.1–6.4`) is deferred to v2, and external `"Ingredients:"` paragraph tokenization (`Part 2` & `Part 5.1`) is deferred to v3[cite: 1, 2]. **Do NOT build ingredient tokenizers or front-of-pack brand/address parsers in v1.** (You MUST still implement `Part 5.2` decoy comparison filters and `Part 6.5` hairline warning box filters to protect table extraction)[cite: 1, 2].
- **Scope Boundary for Phase 1 (Pure Domain Only — No Vision Framework Code Yet):**
  - In Phase 1, you are building the foundational Swift models, constant tables, lexical normalizers, decoy/warning filters, and math validators (`Foundation` only) plus adding `isSupplement: Bool?` to `FoodItem.swift`[cite: 1].
  - **Do NOT** import `Vision` or write camera/OCR request code in Phase 1. A separate Phase 2 Vision pipeline will consume the modules you build here.
- **Minimum Deployment Target:** **iOS 26.0** (strictly hard-pinned)[cite: 1, 2]. Do NOT write `#available` version checks.
- **Tooling Mandate (Xcode MCP & Native Search over Terminal):**
  - Always use **Xcode MCP tools** for creating and editing Swift files, managing Xcode project targets, and running build/compiler diagnostics.
  - Always use **native workspace search (regex/pattern search)** and **bounded line-range file-read tools** to inspect the `.md` reference files. Do NOT spawn bash terminal subshells (`grep`, `awk`, `cat`, `xcodebuild`) unless a native tool or Xcode MCP equivalent does not exist.

### Critical Design-Time vs. Runtime Constraint
**NONE of the `.md` reference files in this workspace will be bundled into the iOS application.**
- **Do NOT** write code that loads, parses, or matches against these `.md` files at runtime.
- **DO compile the FDA's regulatory grammar**, nomenclature aliases, mathematical invariants (RDI/DRV/Atwater), and rounding rules directly into native, strongly-typed Swift files[cite: 1, 2].

---

## 1. Target Data Extraction Mapping (`FoodItem.swift` & `AddFoodView.swift`)

Inspect `FoodItem.swift` and `AddFoodView.swift` before starting[cite: 1]. Your Phase 1 domain payload (`ScannedNutritionPayload`) must map cleanly into these exact `FoodItem` / `AddFoodView` properties:

- `var timestamp: Date`
  - Generated automatically upon saving in `AddFoodView`. Ignored by the Vision pipeline.
- `var brandName: String`, `var name: String`, `var processingLevel: String`, `var category: String`, `var foodVariationGroup: String?`, `var ingredients: [String]`
  - **Unpopulated in v1 (Deferred to v2/v3):** The Vision tool must leave these untouched so `AddFoodView`'s existing manual inputs and defaults remain intact.
- `var isSupplement: Bool?` *(Add this property to `FoodItem.swift` and `AddFoodView.swift`)*
  - Set to `true` when the scanned panel is classified as `"Supplement Facts"` (`21 CFR § 101.36`, e.g., protein powders, pre-workouts, vitamins) and `false` when classified as `"Nutrition Facts"` (`21 CFR § 101.9`)[cite: 2].
- `var servingSize: Double`
  - **Core Data Value:** The numeric metric quantity located inside the parenthetical following the household measure on the `"Serving size"` line—for example, `225.0` from `"1 cup (225g)"` or `32.0` from `"1 scoop (32g)"` (`Part 1.4.1`, `Part 3.1`)[cite: 1, 2].
  - **Edge Cases to Handle:**
    1. *Parenthetical Slash Syntax:* If the parenthetical contains a slash (`"1 slice (28g/1 oz)"` or `"1 oz (28g/about 1/2 pickle)"`), extract the metric number (`28.0`) preceding the slash[cite: 1, 2].
    2. *Prepared Suffixes:* Ignore trailing parenthetical suffixes like `"(makes 1 cup prepared)"` (`§ 101.9(b)(7)(v)`)[cite: 1, 2].
    3. *Single-Serving Metric Omission (`§ 101.9(b)(7)(i)`) & Dosage Supplements (`§ 101.36(b)(1)`):* If a single-serving container omits the parenthetical metric weight (e.g., `"1 can (12 fl oz)"` or `"1 cup"`), compute `servingSize` using standard FDA metric conversions (`1 fl oz = 30 ml`, `1 oz = 28 g`, `1 cup = 240 ml`, `1 tbsp = 15 ml`, `1 tsp = 5 ml`)[cite: 1, 2]. If a pill/capsule supplement has no metric weight (`"Serving Size: 2 Capsules"`), default `servingSize` to the discrete unit count (`2.0`) or `0.0` so `AddFoodView` remains valid[cite: 2].
- `var servingUnit: String`
  - **Core Data Value:** The metric unit string inside the parenthetical following `servingSize`—for example, `"g"` from `"1 cup (225g)"` or `"ml"` from `"1 cup (240 mL)"`[cite: 1, 2].
  - **Strict Normalization for `AddFoodView` Picker:** Because `AddFoodView` binds `servingUnit` to a segmented picker with options `["g", "ml"]`, always normalize `"G"`, `"g"`, `"grams"`, `"gram"` → `"g"` and `"mL"`, `"ML"`, `"ml"`, `"milliliters"` → `"ml"`[cite: 1].
- `var commonHouseholdMeasurementAmount: Double?`
  - **Core Data Value:** The numeric quantity preceding the household measurement unit before the parenthetical metric weight—for example, `1.0` from `"1 cup (225g)"` or `2.0` from `"about 2 slices (56g)"`[cite: 1, 2].
  - **Fraction & Modifier Parsing (`Part 1.4.1`):** Strip leading modifiers (`"about"`, `"approx."`, `"usually"`) and parse vulgar fractions (`"1/4"` → `0.25`, `"1/3"` → `0.33`, `"1/2"` → `0.5`, `"2/3"` → `0.67`, `"3/4"` → `0.75`), mixed fractions (`"1 1/2"` → `1.5`), and Unicode fraction glyphs (`¼`, `½`, `¾`, `⅓`, `⅔`) into `Double`[cite: 1, 2].
- `var commonHouseholdMeasurement: String?`
  - **Core Data Value:** The household or dosage unit string following `commonHouseholdMeasurementAmount` and preceding the parenthetical `(g/mL)`—for example, `"cup"` from `"1 cup (225g)"`, `"slices"` from `"2 slices (56g)"`, or `"scoop"` / `"capsules"` on `Supplement Facts`[cite: 1, 2].
- `var calories: Int`
  - **Core Data Value:** The integer associated with the `"Calories"` (or `"Calories (Energy)"`) row (`Part 1.2.1`, `Part 1.6.1`)[cite: 2]. Always present across `"Nutrition Facts"` styles (may be `0`, or `<5 cal` expressed as `0`)[cite: 2]. On `"Supplement Facts"`, if omitted because the supplement contains 0 calories, default to `0`[cite: 2].
  - **Typography & Disambiguation Cue (`Part 1.6.1`):** The numeric `"Calories"` value has the largest bounding-box height on the label (`>= 22 pt`, or `>= 14 pt` on small packages). Never confuse `"Calories"` with indented `"Calories from saturated fat"`, `"Sat fat cal"`, or footnote references to `"2,000 calories"` / `"1,000 calories"`[cite: 1, 2].
- `var fat: Double`
  - **Core Data Value:** The gram (`g`) weight associated with `"Total Fat"` or `"Fat, total"` (`Part 1.2.2`)[cite: 2]. Always present without exception on `"Nutrition Facts"` labels; if omitted on a zero-fat `"Supplement Facts"` panel (`Part 3.2.1`), default to `0.0`[cite: 2]. Must be strictly differentiated from indented sub-fats (`Saturated`, `Trans`, `Polyunsaturated`, `Monounsaturated`)[cite: 2].
- `var saturatedFat: Double`
  - **Core Data Value:** The gram (`g`) weight associated with Level-1 indented `"Saturated Fat"`, `"Saturated"`, or small-package `"Sat fat"` (`Part 1.2.2`, `Part 1.3`)[cite: 1, 2].
  - **Disambiguation & Omission Rules:** Never derive from `"Calories from saturated fat"` / `"Sat fat cal"`[cite: 1, 2]. While present on standard vertical labels, `"Saturated Fat"` may be legally omitted on Simplified Format labels (`Part 1.1.6`), when noted in `"Not a significant source of saturated fat"`, or on `"Supplement Facts"` when `0g`—in all omitted or `"<0.5g"` cases, record as `0.0`[cite: 2].
- `var transFat: Double`
  - **Core Data Value:** The gram (`g`) weight associated with Level-1 indented `"Trans Fat"` or `"Trans"` (`Part 1.2.2`)[cite: 2]. Not always present (omitted on Simplified labels, when noted in `"Not a significant source of trans fat"`, or on `"Supplement Facts"`). When omitted or `"<0.5g"`, record as `0.0`[cite: 2].
- `var carb: Double`
  - **Core Data Value:** The gram (`g`) weight associated with `"Total Carbohydrate"`, `"Carbohydrate, total"`, or `"Total carb."` (`Part 1.2.6`, `Part 1.3`)[cite: 1, 2]. Always present on `"Nutrition Facts"`; if omitted on a zero-carb `"Supplement Facts"` panel, record as `0.0`[cite: 2].
  - **Threshold Strings (`Part 1.2.6`):** If declared as `"<1g"`, `"less than 1g"`, or `"Contains less than 1 gram"`, record as `0.5` (or `0.0` if `"0g"`)[cite: 2].
- `var dietaryFiber: Double`
  - **Core Data Value:** The gram (`g`) weight associated with Level-1 indented `"Dietary Fiber"` or small-package `"Fiber"` (`Part 1.2.6`, `Part 1.3`)[cite: 1, 2]. Differentiate from Level-2 `"Soluble fiber"` and `"Insoluble fiber"`[cite: 2]. Not always present; if omitted or noted in `"Not a significant source of dietary fiber"`, record as `0.0` (if `"<1g"`, record as `0.5`)[cite: 2].
- `var addedSugar: Double`
  - **Core Data Value:** The gram (`g`) weight associated with Level-2 indented `"Added Sugars"` following `"Total Sugars"` (`Part 1.2.6`)[cite: 2].
  - **Inline Prefix Syntax Alert:** Unlike every other nutrient on the label, `"Added Sugars"` embeds its gram weight **before** the nutrient name: `"Includes [X]g Added Sugars"` or `"Incl. [X]g Added Sugars"` (with `% DV` in the right column)[cite: 2]. Never confuse with parent `"Total Sugars"` or `"Sugar alcohol"`[cite: 2]. If omitted or noted in `"Not a significant source of added sugars"`, record as `0.0` (if `"<1g"`, record as `0.5`)[cite: 2].
- `var protein: Double`
  - **Core Data Value:** The gram (`g`) weight associated with `"Protein"` (`Part 1.2.7`)[cite: 2]. Always present on `"Nutrition Facts"`; if omitted on `"Supplement Facts"` (`§ 101.36(b)(2)(i)`), record as `0.0` (if `"<1g"`, record as `0.5`)[cite: 2]. Ignore adjacent `"not a significant source of protein"` strings or `% DV` numbers[cite: 2].

---

## 2. Authoritative Reference Files for Phase 1

### 2a. `Docs/FDA_Labeling_Guidelines/FDA_Labeling Guidelines_summary.md` (Primary Specification, ~550 lines, ~9K tokens)
A distilled technical specification of **21 CFR Part 101 (Subparts A–D)**[cite: 1, 2]:
- **Part 1 (`§ 101.9` Conventional Nutrition Facts):**
  - `1.1` 10 Label Topologies, Structural Varieties, & Legitimate Exemption Replacement Strings
  - `1.2` Canonical Nutrient Hierarchy (Level 0/1/2 indentation), Allowed Names, Units, & Rounding Increments
  - `1.3` Authorized Abbreviations & Lexical Normalization Dictionary (small packages & dual-column headers)
  - `1.4` Serving Size & Servings Per Container Token Grammar & Discrete Unit Thresholds
  - `1.5` Mathematical Cross-Validation Constants (DRVs, 27 RDIs across 4 demographic groups, Biochemical Conversions, Atwater 4-4-9 & Sugar Alcohol factors, Sub-Nutrient Ceiling Rules)
  - `1.6` Visual Typography & Bold/Reverse-Printing Invariants
- **Part 3 (`§ 101.36` Dietary Supplements / `Supplement Facts`):**
  - `3.1` Dynamic Column Headings (`Each Tablet Contains`, omitted `% DV` column)
  - `3.2` Two-Tiered Partitioning (`(b)(2)` RDI/DRV nutrients with modified 29-micronutrient order vs. `(b)(3)` Other Dietary Ingredients & Proprietary Blends)
  - `3.3` Inline Source Compound Declarations (`as`/`from`, parenthetical or indented)
  - `3.4` Multi-Demographic Columns, `Per Day` Multipliers, Right-Hand Continuation Splits, & Dot-Leader Rows (`\.{2,}`)
- **Part 5.2 & Part 6.5 (Defensive Filtering Rules):**
  - `5.2` Decoy Comparative Nutrient Strings Adjacent to the Nutrition Box (Keywords to reject)
  - `6.5` Mandatory Hairline-Boxed Warnings (`§ 101.17` iron, unpasteurized juice, shell eggs) that must be rejected as false-positive tables.
- *(Note: `Part 2` Ingredients, `Part 4` Raw Produce, `Part 5.1` Ingredient Asterisks, and `Part 6.1–6.4` PDP Metadata are out of scope for v1—skip them).*

### 2b. `Docs/FDA_Labeling_Guidelines/FDA_Labeling-Guidelines_StructureExamples.md` (Topological Reference, ~550 lines, ~4.5K tokens)
Contains 12 clean HTML table archetypes (`A` through `L`) representing the 2D grid topologies of 21 CFR `§ 101.9`[cite: 1, 2]. Consult this to ensure your `FDALabelTopology` enum and multi-column selection logic (`DualColumn`, `AggregateVariety`, `Simplified`, `LinearString`, `SupplementFacts`) handle every layout[cite: 2].

---

## 3. Required Deliverables & Incremental Milestone Protocol

When creating your implementation plan, optimize for **exhaustive completeness and regulatory accuracy** over minimizing steps. Structure your work as **4 sequential file milestones (3.1 through 3.4)** followed by a final contract audit (`3.5`).

For **every single milestone (3.1 through 3.4)**, you MUST execute this exact three-step loop before moving to the next file:
1. **Implement:** Create or update the `.swift` file(s) via Xcode MCP with 100% complete regulatory logic and zero truncation.
2. **Verify Compilation:** Run a build/diagnostic check via Xcode MCP and resolve all compiler errors or warnings.
3. **Append to `Phase1_API_Contract.md`:** Immediately create (on Milestone 3.1) or update (on Milestones 3.2–3.4) `Phase1_API_Contract.md` in the workspace root with that file's target path, a 1-sentence responsibility summary, and a Swift code block containing **ONLY its public/internal type declarations, enum cases, struct properties, and method signatures** (omitting function bodies, private helpers, and static dictionary/RDI array literals). *If a later milestone requires modifying an earlier `.swift` file, immediately update that file's section in `Phase1_API_Contract.md` so the contract never drifts.*

### 3.1 Milestone 1: `FoodItem.swift` Update + `FDADomainModels.swift`
- Update `FoodItem.swift` (and `AddFoodView.swift` if needed for init/state) to add `var isSupplement: Bool? = nil`[cite: 1].
- Create `FDADomainModels.swift`:
  - Define `FDALabelTopology` covering all regulatory topologies (`standardVertical`, `sideBySideMicronutrients`, `tabularHorizontal`, `dualColumnSameFood`, `dualColumnPerContainer`, `dualColumnPerUnit`, `tabularDualColumn`, `aggregateVariety`, `simplified`, `smallPackageTabular`, `linearString`, `supplementFacts`)[cite: 2].
  - Define `CanonicalNutrientID` covering **all** mandatory and voluntary food/supplement nutrients (even though `FoodItem` only persists calories, fats, carbs, fiber, added sugars, and protein, the parser MUST recognize `Total Sugars`, `Sugar Alcohol`, `Cholesterol`, `Sodium`, `Potassium`, and all 27 RDI vitamins/minerals so their numbers are used for math validation and never misassigned to `FoodItem` fields)[cite: 2].
  - Define `DeclaredNutrientAmount` that explicitly distinguishes: `(a)` omitted, `(b)` explicit `0`, `(c)` threshold strings (`"<1g"` → `0.5` for carbs/fiber/sugar/protein; `"<0.5g"` → `0.0` for fat; `"<5mg"` for cholesterol), `(d)` footnote-keyed insignificance (`"*"`, `"†"`, `"Not a significant source of..."` → `0.0`), and `(e)` exact numerical amount + validated `NutrientUnit`[cite: 2].
  - Define `ScannedNutritionPayload`, a struct holding the validated, ready-to-bind values for `AddFoodView` (`isSupplement: Bool`, `servingSize: Double`, `servingUnit: String`, `commonHouseholdMeasurement: String?`, `commonHouseholdMeasurementAmount: Double?`, `calories: Int`, `fat: Double`, `saturatedFat: Double`, `transFat: Double`, `carb: Double`, `dietaryFiber: Double`, `addedSugar: Double`, `protein: Double`, plus diagnostic confidence/healed flags).
- **Milestone Gate:** Compile via Xcode MCP -> Create `Phase1_API_Contract.md` with Section 1.

### 3.2 Milestone 2: `FDARegulatoryConstants.swift` (Exhaustive RDI, DRV & Rounding Tables)
- Hardcode the complete **DRV** and **27-nutrient RDI** lookup tables across all 4 demographic groups (`infantsThrough12Months`, `children1Through3Years`, `adultsAndChildren4OrMoreYears`, `pregnantAndLactatingWomen`) from `Part 1.5`[cite: 2].
- Hardcode Atwater `4-4-9` and sugar alcohol caloric factors (`Part 1.5.3`) and standard household-to-metric volume/weight conversions (`Part 1.4.1`)[cite: 2].
- Implement programmatic **21 CFR `§ 101.9(c)` Rounding Rules** for every nutrient class (calories `5`/`10 kcal` steps; fats `<0.5g -> 0`, `<5g -> 0.5g` steps, `>=5g -> 1g` steps; carbs/fiber/sugars/protein `<0.5g -> 0`, `<1g -> <1g`, `>=1g -> 1g` steps; sodium `5mg`/`10mg` steps) so the validator can compute the exact legal interval `[minActual, maxActual]` for any printed value[cite: 2].
- **Milestone Gate:** Compile via Xcode MCP -> Append Section 2 to `Phase1_API_Contract.md`.

### 3.3 Milestone 3: `FDALexicalNormalizer.swift` (Nomenclature, Serving Grammar & Defensive Filters)
- Compile the canonical nutrient hierarchy (Level 0/1/2 indentation) and allowed synonym sets (`Part 1.2`), small-package authorized abbreviations (`Part 1.3`), and the `Part 3.2` 29-micronutrient sequence for supplements[cite: 2].
- Provide an order-independent nutrient resolver that normalizes noisy OCR text, strips footnote superscripts (`Folate 6` vs `Vitamin B6`), and resolves canonical `CanonicalNutrientID`s[cite: 2].
- **Special Inline Pattern Handlers:**
  - Handle `"Includes [X]g Added Sugars"` / `"Incl. [X]g Added Sugars"` where the gram weight precedes `"Added Sugars"` (`Part 1.2.6`)[cite: 2].
  - Handle both same-cell inline weights (`"Total Fat 8g"`) and separate-column weights, strip dot-leader runs (`\.{2,}` in `Part 3.4`), and strip inline supplement source compounds (`"as..."` / `"from..."` in `Part 3.3`)[cite: 2].
- **Serving Size & Household Measure Parser (`Part 1.4.1` & `Part 3.1`):**
  - Parse `[Household Amount + Household Unit] ([Metric Size + g/mL])` into the 4 `FoodItem` serving properties (`servingSize`, `servingUnit` normalized to `"g"` or `"ml"`, `commonHouseholdMeasurementAmount` with vulgar/mixed/Unicode fraction support, and `commonHouseholdMeasurement`), including single-serving conversion fallbacks and slash-syntax handling[cite: 2].
- **Defensive Decoy & Warning Box Filters (`Part 5.2` & `Part 6.5`):**
  - Provide pure functions that detect and reject **Decoy Comparative Nutrient Strings** (`"reduced from"`, `"lowered from"`, `"compared with"`, `"per 3 oz"`, `"regular"`, `"not a low"`, `"not a sodium free"`) and **Mandatory Hairline-Boxed Warnings** (`§ 101.17` iron overdose warning, unpasteurized juice warning, `SAFE HANDLING INSTRUCTIONS` on shell eggs)[cite: 2].
- **Milestone Gate:** Compile via Xcode MCP -> Append Section 3 to `Phase1_API_Contract.md`.

### 3.4 Milestone 4: `FDANutritionValidator.swift` (Math Cross-Validation, Self-Healing & `ScannedNutritionPayload` Builder)
- **Demographic Detection:** Automatically infer the active `FDADemographicGroup` from footnote cues (`"1,000 calories"` vs `"2,000 calories"`, or the absence of `% DV` on infant macronutrients) or multi-column headers (`Part 1.1.9`, `Part 3.4`)[cite: 2].
- **OCR Error Recovery via Regulatory-Tolerance Math Invariants:**
  1. *`% DV` Cross-Check & Decimal Healing:* Verify `(ScannedAmount / DRV_or_RDI) * 100 ≈ ScannedPercentDV`, accounting for `§ 101.9(c)` rounding increments and unrounded-vs-declared calculation rules (`Part 1.5`, `Part 3.2.1`)[cite: 2]. **Auto-mutate ("heal") a scanned amount ONLY when** the raw value fails validation AND applying a `0.1x`/`0.01x` decimal shift or single-glyph swap (`15g` → `1.5g`, `O` → `0`) brings the candidate within the legal rounding interval of the scanned `% DV`.
  2. *Sub-Nutrient Ceiling Invariants (with Rounding Slop):* Enforce `Added Sugars <= Total Sugars + RoundingTolerance`, `Total Sugars <= Total Carbohydrate + RoundingTolerance`, and `Saturated + Trans + Poly + Mono <= Total Fat + SumOfConstituentRoundingTolerances` (`Part 1.5.3`) so legal cumulative `0.5g`/`1g` rounding steps never trigger false validation failures[cite: 2].
  3. *Atwater 4-4-9 & Sugar Alcohol Calorie Check:* Cross-check `Calories` against `4*Protein + 4*(Carbs - InsolubleFiber - Allulose) + 9*Fat` (adjusting for dietary fiber and sugar alcohol factors in `Part 1.5.3` plus legal `5/10 kcal` calorie rounding steps)[cite: 2]. Output this as a confidence score/flag rather than blindly overwriting declared `Calories`.
  4. *Unit & Glyph Disambiguation:* Enforce strict legal units per nutrient (`g`, `mg`, `mcg`, `IU`, `DFE`, `NE`, `RAE`) to auto-correct classic OCR glyph swaps (`Omcg` → `0mcg`, `1mg` vs `lmg`, `g` vs `9` or `q`)[cite: 2].
- **`ScannedNutritionPayload` Assembly:** Convert the validated nutrient dictionary and parsed serving size into a `ScannedNutritionPayload` that applies all `FoodItem` omission defaults (`0.0` for omitted `saturatedFat`, `transFat`, `dietaryFiber`, `addedSugar`, and omitted `Supplement Facts` macros; `0.5` for `"<1g"` carb/fiber/sugar/protein thresholds). For Dual-Column labels (`Part 1.1.4`), select the primary `"Per Serving"` (left) column by default[cite: 2].
- **Milestone Gate:** Compile via Xcode MCP -> Append Section 4 to `Phase1_API_Contract.md`.

### 3.5 Final Milestone Gate: Integration Recipe & Contract Audit
Once Milestone 3.4 compiles cleanly via Xcode MCP:
1. Verify that every declaration in `Phase1_API_Contract.md` matches the final compiled state of all Phase 1 files.
2. Append a final **"Phase 2 Integration Recipe"** section (10–15 lines of concise Swift code) at the bottom of `Phase1_API_Contract.md` showing the exact call sequence for the Phase 2 Vision agent to filter decoys/warnings, normalize cell transcripts, parse the serving size line, and produce a validated `ScannedNutritionPayload` for `AddFoodView`.

---

## 4. Hard Rules
1. **Zero truncation or placeholder stubs.** Never use comments like `// ... remaining nutrients` or `// TODO: add abbreviations` when generating lookup tables, enums, or regex dictionaries. Every regulatory constant table must be 100% complete.
2. **Use Xcode MCP for all Swift & project operations.** Create, edit, and compile each Swift file through Xcode MCP tools, fixing any compiler errors before advancing to the next milestone.
3. **Update `Phase1_API_Contract.md` after every single milestone.** Never defer contract logging to the end of the session, and keep earlier sections synced if any signature changes.
4. **Stay strictly within v1 scope.** Do not build ingredient list tokenizers (`Part 2`) or front-of-pack brand/product metadata parsers (`Part 6.1–6.4`).
5. **Compile rules into Swift—never bundle `.md` files.** All regulatory constants, regexes, synonyms, and math rules must be self-contained in Swift code.