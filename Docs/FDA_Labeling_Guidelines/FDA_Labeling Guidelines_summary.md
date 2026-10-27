# 21 CFR Part 101 (Subparts A–D) — Technical Specification for iOS Vision (`RecognizeDocumentsRequest`) Nutrition, Ingredient, & Package Metadata Parsing

## Table of Contents
- [Part 1: Conventional Food Nutrition Labeling (§ 101.9)](#part-1-conventional-food-nutrition-labeling--1019)
  - [1.1 Label Topologies, Structural Varieties, & Exemption Strings (§ 101.9)](#11-label-topologies-structural-varieties--exemption-strings--1019)
  - [1.2 Canonical Nutrient Hierarchy, Nomenclature, Units, & Rounding (§ 101.9(c) & (d))](#12-canonical-nutrient-hierarchy-nomenclature-units--rounding--1019c--d)
  - [1.3 Authorized Abbreviations & Lexical Normalization Dictionary](#13-authorized-abbreviations--lexical-normalization-dictionary)
  - [1.4 Serving Size & Servings Per Container Parsing Rules (§ 101.9(b))](#14-serving-size--servings-per-container-parsing-rules--1019b)
  - [1.5 Mathematical Cross-Validation Constants (DRV, RDI, & Atwater)](#15-mathematical-cross-validation-constants-drv-rdi--atwater)
  - [1.6 Visual Typography & Adjacency Heuristics (§ 101.4 & § 101.9(d))](#16-visual-typography--adjacency-heuristics--1014---1019d)
- [Part 2: Ingredient List Parsing Specification (§ 101.2, § 101.4, & § 101.22)](#part-2-ingredient-list-parsing-specification--1012--1014---10122)
  - [2.1 Spatial Location & Header Anchor Tokens (§ 101.2 & § 101.4)](#21-spatial-location--header-anchor-tokens--1012---1014)
  - [2.2 Structural Grammar of an Ingredient Statement (§ 101.4)](#22-structural-grammar-of-an-ingredient-statement--1014)
  - [2.3 Collective Class Names & Variable Blend Rules (§ 101.4(b))](#23-collective-class-names--variable-blend-rules--1014b)
  - [2.4 Spices, Flavorings, Colorings, & Chemical Preservatives (§ 101.22)](#24-spices-flavorings-colorings--chemical-preservatives--10122)
- [Part 3: Subpart C — Dietary Supplements (`Supplement Facts`) Specification (§ 101.36)](#part-3-subpart-c--dietary-supplements-supplement-facts-specification--10136)
  - [3.1 Header, Serving Size, & Column Heading Variations (§ 101.36(b)(1)–(2) & (e))](#31-header-serving-size--column-heading-variations--10136b12--e)
  - [3.2 Two-Tiered Ingredient Partitioning & Modified Nutrient Order (§ 101.36(b)(2)–(3) & (e)(6))](#32-two-tiered-ingredient-partitioning--modified-nutrient-order--10136b23--e6)
  - [3.3 Inline Source Compound Declarations (§ 101.36(d))](#33-inline-source-compound-declarations--10136d)
  - [3.4 Multi-Column, Split-Continuation, & Small-Package Topologies (§ 101.36(b)(2)(iii)(E), (e)(8)–(12), (i)(2))](#34-multi-column-split-continuation--small-package-topologies--10136b2iiie-e812-i2)
- [Part 4: Raw Produce & Fish Point-of-Purchase Variations (§§ 101.42–101.45)](#part-4-raw-produce--fish-point-of-purchase-variations--1014210145)
- [Part 5: Subpart D — How Nutrient Content Claims Alter Panel & Ingredient Text (§§ 101.54–101.67)](#part-5-subpart-d--how-nutrient-content-claims-alter-panel--ingredient-text--1015410167)
  - [5.1 Ingredient List Asterisk Footnotes (`*`) (§§ 101.60–101.62 & § 101.67)](#51-ingredient-list-asterisk-footnotes---1016010162---10167)
  - [5.2 Decoy Nutrient Strings Placed Adjacent to the Nutrition Box (§§ 101.54–101.62)](#52-decoy-nutrient-strings-placed-adjacent-to-the-nutrition-box--1015410162)
  - [5.3 Claim-to-Label Mathematical Invariants (Optional OCR Sanity Check)](#53-claim-to-label-mathematical-invariants-optional-ocr-sanity-check)
- [Part 6: Front-of-Pack (PDP), Package Metadata, & Boxed Warnings Specification (§§ 101.1–101.7, 101.13, 101.15, 101.17, 101.18, & 101.22(i))](#part-6-front-of-pack-pdp-package-metadata--boxed-warnings-specification--10111017-10113-10115-10117-10118--10122i)
  - [6.1 Principal Display Panel (PDP) & Information Panel Geometry (§§ 101.1, 101.2, & 101.15)](#61-principal-display-panel-pdp--information-panel-geometry--1011-1012--10115)
  - [6.2 Statement of Identity, Product Form, & Characterizing Flavor Metadata (§ 101.3, § 101.13, § 101.18, & § 101.22(i))](#62-statement-of-identity-product-form--characterizing-flavor-metadata--1013--10113--10118---10122i)
  - [6.3 Manufacturer, Packer, or Distributor Metadata (§ 101.5)](#63-manufacturer-packer-or-distributor-metadata--1015)
  - [6.4 Net Quantity of Contents Declaration (§ 101.7)](#64-net-quantity-of-contents-declaration--1017)
  - [6.5 Mandatory Boxed Warnings & Safe-Handling Statements (§ 101.17)](#65-mandatory-boxed-warnings--safe-handling-statements--10117)

---

## Part 1: Conventional Food Nutrition Labeling (§ 101.9)

### 1.1 Label Topologies, Structural Varieties, & Exemption Strings (§ 101.9)
The iOS Vision parser must first classify which FDA layout topology it is examining based on the spatial arrangement of `DocumentObservation` tables and text blocks:

1. **Standard Vertical Format (§ 101.9(d)(1)–(10)):**
   - Enclosed in a hairline box with a top-to-bottom reading order: `"Nutrition Facts"` header → `"____ servings per container"` → `"Serving size"` (with the amount right-justified if space allows) → thick bar → `"Amount per serving"` subheading → `"Calories"` (with optional indented `"Calories from saturated fat"`) → bar → right-aligned `"% Daily Value*"` column header → macronutrients and sodium (left column: nutrient name + weight; right column: `% DV`) → bar → vitamins and minerals → bar → asterisked footnote (`"*The % Daily Value tells you how much a nutrient in a serving of food contributes to a daily diet. 2,000 calories a day is used for general nutrition advice."`) → optional hairline and caloric conversion footer (`"Calories per gram: fat 9, carbohydrate 4, protein 4"`).
   - **Micronutrient Array Options (§ 101.9(d)(8)):** Vitamins and minerals may be stacked vertically in a single column or arrayed horizontally in two side-by-side columns (where `Vitamin D` and `Calcium` appear on line 1, and `Iron` and `Potassium` appear on line 2).
   - **Calorie-Free Footnote Omission / Truncation (§ 101.9(d)(9)):** Foods eligible to bear `"calorie free"`, `"free of calories"`, `"without calories"`, `"trivial source of calories"`, `"negligible source of calories"`, or `"dietarily insignificant source of calories"` claims under `§ 101.60(b)` may omit the `*The % Daily Value...` footnote entirely, or print only its first sentence (`"The % Daily Value tells you how much a nutrient in a serving of food contributes to a daily diet"`).
2. **Side-Shifted Footnote / Split Micronutrient Format (§ 101.9(d)(11)(i)–(ii)):**
   - When vertical space below the vitamins/minerals or below `Potassium` is insufficient, the footnote or the remaining vitamins and minerals may be moved to the **right** of the `"% Daily Value"` column, separated by a vertical line. (See also [Section 3.4 Right-Hand Continuation Split](#34-multi-column-split-continuation--small-package-topologies--10136b2iiie-e812-i2) for dietary supplements).
3. **Tabular (Horizontal) Format (§ 101.9(d)(11)(iii) & § 101.9(j)(13)(ii)(A)(1)):**
   - Permitted when continuous vertical space is less than approximately 3 inches, or on small/intermediate packages with `<= 40` square inches of label space.
   - **3-Zone Horizontal Architecture:** Features a left sidebar (`"Nutrition Facts"`, servings per container, `"Serving size"`, and `"Calories per serving"`), a center 4-column grid containing two parallel side-by-side nutrient stacks (each with its own `"Amount/serving"` and `"% Daily Value*"` headers), and a right sidebar containing the `% DV` footnote.
   - **Inline Micronutrient Footer:** Vitamins and minerals span horizontally beneath both parallel nutrient stacks, separated by bullets (`•`).
4. **Dual-Column Formats (§ 101.9(b)(2)(i)(D), (b)(6), (b)(10)–(12), (e), (h)(4)):**
   - Presents two sets of quantitative weight (`g`/`mg`/`mcg`) and `"% Daily Value"` columns separated by vertical lines.
   - **Header Modification (§ 101.9(d)(4) & (e)(1)):** Dual-column labels omit the standard `"Amount per serving"` subheading and instead display two or more descriptive column headings immediately below the serving size (e.g., `"Per 1/4 cup mix"` and `"Per prepared portion"`).
   - **Common Dual-Column Triggers:**
     - *Per Serving vs. Per Container/Unit:* Required on single-unit or discrete-unit packages containing `200%` to `300%` of the Reference Amount (and voluntary for packages containing `>150%` to `<200%`). (See [Section 1.4.1](#14-serving-size--servings-per-container-parsing-rules--1019b) for unit-weight thresholds).
     - *As Purchased vs. As Prepared:* Used for foods commonly combined with other ingredients or cooked (e.g., dry cereal vs. cereal with milk, or dry cake mix vs. prepared cake).
     - *Alternate Measurement Basis:* Second column declared per `100 g`, `100 mL`, `1 oz`, `1 fl oz`, per `1 unit` (for multi-unit servings), or `per cup popped` for popcorn.
     - *Multi-Demographic RDI Groups:* Separate `% DV` columns declared for both `"infants through 12 months of age"` and `"children 1 through 3 years of age"`.
5. **Aggregate Display (Variety Packs) (§ 101.9(d)(13) & (h)(2)):**
   - Used on outer packages containing multiple separately packaged foods (e.g., cereal or snack variety packs) or interchangeable containers (e.g., round ice cream tubs). (See also [Section 3.4 Aggregate Supplement Display](#34-multi-column-split-continuation--small-package-topologies--10136b2iiie-e812-i2)).
   - The identity of each distinct food product is placed as a column header immediately to the right of the `"Nutrition Facts"` title, with separate sub-columns for quantitative weight and `"% Daily Value"` underneath each product header.
6. **Simplified Format (§ 101.9(f)):**
   - Permitted when a food contains insignificant amounts of 8 or more of the 15 core nutrients (or 6 or more of 12 for infant/young child foods).
   - **Mandatory 5 Core Rows:** Must always declare `Total calories`, `total fat`, `total carbohydrate`, `protein`, and `sodium`, plus any other core nutrients present in more than insignificant amounts and any added/claimed vitamins or minerals.
   - **Footer Rules:** Omits the standard `% DV` footnote, uses `*% DV = % Daily Value` when `"Daily Value"` is abbreviated in the header, and requires the bottom statement `"Not a significant source of ________"` listing omitted insignificant nutrients whenever nutrition claims are made or voluntary/added nutrients are declared.
7. **Linear (String) Display (§ 101.9(d)(3)(i) & (j)(13)(ii)(A)(2)):**
   - Permitted on small packages (`<12` sq. in., or `<= 40` sq. in. when a tabular display cannot fit).
   - Renders all nutrition facts as a continuous paragraph/string of text rather than a grid table; notably, the numeric count of servings may be printed *after* the `"servings per container"` text (e.g., `"Servings per container: 1"`). Small-package tabular and linear formats may omit the standard `% DV` footnote or use the abbreviated statement `"% DV = % Daily Value"`.
8. **Bilingual Nutrition Labels (§ 101.9(d)(14) & § 101.15(c)(2)):**
   - May be printed as two separate panels or merged into a single panel where the second language immediately follows English; identical numeric values do not need to be repeated (e.g., `"Protein/Proteinas 2 g"`).
9. **Infant & Young Child Format Modifications (§ 101.9(j)(5)):**
   - *Infants (through 12 months):* Must **not** declare a `% Daily Value` for `saturated fat`, `trans fat`, `cholesterol`, `sodium`, `dietary fiber`, `total sugars`, or `added sugars`, and must **not** include a footnote.
   - *Children (1 through 3 years):* Replaces `"2,000 calories"` with `"1,000 calories"` in the standard footnote (`"*The % Daily Value tells you how much a nutrient in a serving of food contributes to a daily diet. 1,000 calories a day is used for general nutrition advice."`).
10. **Legitimate Panel Absence & Replacement Strings (§ 101.9(a)(3), (j), & § 101.36(h)):**
    - A scan of a food package may legitimately detect no Nutrition Facts panel—or detect a specific regulatory replacement string—under the following exemptions:
      - *Multiunit Inner Containers (§ 101.9(j)(15) & § 101.36(i)(3)):* Individual unit containers securely enclosed inside a labeled multiunit retail package are exempt if they bear no labeling at all, or if they display the statement `"This Unit Not Labeled For Retail Sale"` (or `"This Unit Not Labeled For Individual Retail Sale"`) in type `>= 1/16 inch`.
      - *Small-Package Contact String (§ 101.9(j)(13)(i)(A) & (a)(3)):* Packages with `<12` sq. in. of available labeling area (bearing no nutrition claims) may omit the nutrition panel if they print an address or telephone number for consumers to obtain nutrition information (e.g., `"For nutrition information, call 1-800-123-4567"` or `"For nutrition information write to ______"`).
      - *Other Exempt Categories (§ 101.9(j)):* Small-business/low-volume exemptions (`<= $500,000` total gross sales or `<= $50,000` food sales, or `<100` full-time equivalent employees and `<100,000` units with no claims); foods containing insignificant amounts of all mandatory nutrients (plain coffee beans, tea leaves, plain unsweetened instant coffee/tea, dehydrated condiments, flavor extracts, food colors); raw fruits, vegetables, and fish (`§ 101.9(j)(10)`, governed by [Part 4](#part-4-raw-produce--fish-point-of-purchase-variations--1014210145)); custom-processed fish/game meats (`§ 101.9(j)(11)(ii)`); shell egg cartons where nutrition info is printed inside the lid or on an insert (`§ 101.9(j)(14)`); bulk shipping containers (`§ 101.9(j)(9)`); and infant formulas (`21 CFR Part 107`) or medical foods (`§ 101.9(j)(7)–(8)`).

---

### 1.2 Canonical Nutrient Hierarchy, Nomenclature, Units, & Rounding (§ 101.9(c) & (d))
No nutrients other than the mandatory and voluntary items listed in `§ 101.9(c)` may appear inside the conventional `"Nutrition Facts"` box, and they must appear in the exact top-to-bottom sequence below (for `"Supplement Facts"` ordering exceptions, see [Section 3.2](#32-two-tiered-ingredient-partitioning--modified-nutrient-order--10136b23--e6)):

1. **Calories (§ 101.9(c)(1) & (c)(8)(v)):**
   - *Allowed Names:* `"Calories"`, `"Total calories"`, `"Calories, total"`, with optional parenthetical synonym `"Calories (Energy)"`.
   - *Units & Rounding:* Whole number (optional parenthetical kilojoules `kJ` immediately following); rounded to nearest `5`-calorie increment up to `50` calories, and nearest `10`-calorie increment above `50` calories (`<5` calories may be expressed as `0`).
   - *Indented Sub-Item (Voluntary):* `"Calories from saturated fat"` or `"Calories from saturated"` (same `5`/`10` rounding increments).
2. **Total Fat (§ 101.9(c)(2)):**
   - *Allowed Names:* `"Total fat"` or `"Fat, total"`.
   - *Units & Rounding:* Grams (`g`); `<0.5 g` expressed as `0`; `<5 g` rounded to nearest `0.5 g` (`1/2 g`) increment; `>5 g` rounded to nearest `1 g` increment.
   - *Indented Sub-Nutrients (all in `g`, using the exact same `0.5 g` / `1 g` rounding rules):*
     - **Level 1 (Mandatory):** `"Saturated fat"` or `"Saturated"` (if omitted when `<0.5 g` total fat, triggers footer `"Not a significant source of saturated fat"`).
     - **Level 1 (Mandatory):** `"Trans fat"` or `"Trans"` (`"Trans"` may be italicized; no `% DV` exists; if omitted when `<0.5 g` total fat, triggers footer `"Not a significant source of trans fat"`).
     - **Level 1 (Voluntary / Conditionally Mandatory):** `"Polyunsaturated fat"` or `"Poly-unsaturated"`.
     - **Level 1 (Voluntary / Conditionally Mandatory):** `"Monounsaturated fat"` or `"Monounsaturated"`.
     - *Mutual Trigger Rule (§ 101.9(c)(2)(iii)–(iv)):* If either `Polyunsaturated fat` or `Monounsaturated fat` is declared, or if any claim is made about fatty acids or cholesterol (other than a qualifying `"fat free"` claim under `§ 101.62(b)(1)`), declaration of **both** `Polyunsaturated fat` and `Monounsaturated fat` becomes mandatory.
3. **Cholesterol (§ 101.9(c)(3)):**
   - *Allowed Name:* `"Cholesterol"`.
   - *Units & Rounding:* Milligrams (`mg`) to nearest `5 mg` increment.
   - *Special String Values:* `<2 mg` may be stated as `0` or omitted (triggering `"Not a significant source of cholesterol"`); `2 mg` to `5 mg` may be stated as `"less than 5 milligrams"` or `"<5 mg"`.
4. **Sodium (§ 101.9(c)(4)):**
   - *Allowed Name:* `"Sodium"`.
   - *Units & Rounding:* Milligrams (`mg`); `<5 mg` expressed as `0`; `5 mg` to `140 mg` rounded to nearest `5 mg` increment; `>140 mg` rounded to nearest `10 mg` increment.
5. **Fluoride (Voluntary) (§ 101.9(c)(5)):**
   - *Allowed Name:* `"Fluoride"`.
   - *Units & Rounding:* Milligrams (`mg`); `<0.1 mg` expressed as `0`; `<=0.8 mg` rounded to nearest `0.1 mg` increment; `>0.8 mg` rounded to nearest `0.2 mg` increment.
6. **Total Carbohydrate (§ 101.9(c)(6)):**
   - *Allowed Names:* `"Total carbohydrate"` or `"Carbohydrate, total"`.
   - *Units & Rounding:* Grams (`g`) to nearest `1 g` increment; `<1 g` may be expressed as `"Contains less than 1 gram"`, `"less than 1 gram"`, or `"<1 g"`; `<0.5 g` may be expressed as `0`.
   - *Indented Sub-Nutrients (all in `g`, using the exact same `1 g` rounding and `<1 g` / `0` string rules):*
     - **Level 1 (Mandatory):** `"Dietary fiber"` (if omitted when `<1 g`, triggers `"Not a significant source of dietary fiber"`).
       - **Level 2 under Dietary Fiber (Voluntary):** `"Soluble fiber"` and `"Insoluble fiber"` (mandatory if a claim is made about soluble or insoluble fiber).
     - **Level 1 (Mandatory):** `"Total Sugars"` (no `% DV` column value; if omitted when `<1 g`, triggers `"Not a significant source of total sugars"`).
       - **Level 2 under Total Sugars (Mandatory):** `"Added Sugars"`, formatted with the inline syntax `"Includes [X]g Added Sugars"` (if omitted when `<1 g`, triggers `"Not a significant source of added sugars"`).
     - **Level 1 (Voluntary):** `"Sugar alcohol"` (or the specific chemical name such as `"xylitol"`, `"mannitol"`, or `"sorbitol"` if only one sugar alcohol is present; mandatory when a claim is made about sugar alcohol, total sugars, or added sugars when sugar alcohols are present).
7. **Protein (§ 101.9(c)(7)):**
   - *Allowed Name:* `"Protein"`.
   - *Units & Rounding:* Grams (`g`) to nearest `1 g` increment (same `<1 g` / `0` rules as carbohydrate).
   - *`% DV` & Adjacency Rules:* The `% DV` column for protein is optional (and often blank) on adult labels, but **mandatory** if a protein claim is made or if the food is intended for infants or children under 4 years of age (except it must **not** be declared on infant foods if the Protein Efficiency Ratio (PER) is `<40%` of casein). If protein digestibility-corrected amino acid score (PDCAAS) is `<20%` for ages 4+ (or `<40%` for ages 1–3), either `"not a significant source of protein"` or the digestibility-corrected `% DV` must appear; for infants with PER `<40%`, `"not a significant source of protein"` must appear adjacent to the gram weight.
8. **Vitamins and Minerals (§ 101.9(c)(8)):**
   - *Mandatory 4 (in strict sequence):* `Vitamin D` (`mcg`, optionally followed by parenthetical `(IU)`), `Calcium` (`mg`), `Iron` (`mg`), and `Potassium` (`mg`). Quantitative weights (`mg`/`mcg`) are mandatory on standard labels, but may be omitted on small-package formats under `§ 101.9(j)(13)`.
   - *Voluntary/Conditional Micronutrients (must follow this exact sequence when declared):* `Vitamin A` (`mcg`, with optional indented or parenthetical `"([X] percent as beta-carotene)"`), `Vitamin C` (`mg`, optional synonym `"Vitamin C (Ascorbic acid)"`), `Vitamin E` (`mg`), `Vitamin K` (`mcg`), `Thiamin` (`mg`, optional synonym `"Thiamin (Vitamin B1)"`), `Riboflavin` (`mg`, optional synonym `"Riboflavin (Vitamin B2)"`), `Niacin` (`mg`), `Vitamin B6` (`mg`), `Folate` (`mcg DFE`, with mandatory parenthetical `"([X] mcg folic acid)"` when folic acid is added/claimed), `Vitamin B12` (`mcg`), `Biotin` (`mcg`), `Pantothenic acid` (`mg`), `Phosphorus` (`mg`), `Iodine` (`mcg`), `Magnesium` (`mg`), `Zinc` (`mg`), `Selenium` (`mcg`), `Copper` (`mg`), `Manganese` (`mg`), `Chromium` (`mcg`), `Molybdenum` (`mcg`), `Chloride` (`mg`), and `Choline` (`mg`).
   - *`% DV` Rounding Increments for Micronutrients (§ 101.9(c)(8)(iii)):* Nearest `2%` increment up to `10%`; nearest `5%` increment from `>10%` up to `50%`; nearest `10%` increment above `50%`.
   - *Insignificant Micronutrient Declarations (`<2% RDI`):* May be declared as `0`, omitted if noted in `"Not a significant source of..."`, or marked with an asterisk (`*`) or symbol pointing to `"Contains less than 2 percent of the Daily Value of this (these) nutrient (nutrients)"` (or `"<2 percent"`).

---

### 1.3 Authorized Abbreviations & Lexical Normalization Dictionary
To prevent parser failures on small packages (`§ 101.9(j)(13)(ii)(B)`), dual-column headers, or side-by-side displays, the Swift tokenizer must normalize these exact FDA-authorized abbreviations back to their canonical keys:

- **Header & Structural Abbreviations:**
  - `"Serv size"` → `Serving size`
  - `"Servings"` → `Servings per container`
  - `"Percent Daily Value"`, `"Percent DV"`, `"% DV"` → `% Daily Value`
  - `"Incl"` → `Includes` (also permitted on dual-column displays)
  - `"Cal"` → `Calories` (permitted on vending/menu/written displays)
- **Nutrient Name Abbreviations:**
  - `"Sat fat cal"` → `Calories from saturated fat` (and `"fat cal"` → `Calories from fat` in written restaurant info)
  - `"Sat fat"` → `Saturated fat`
  - `"Monounsat fat"` → `Monounsaturated fat`
  - `"Polyunsat fat"` → `Polyunsaturated fat`
  - `"Cholest"` → `Cholesterol`
  - `"Total carb"` → `Total carbohydrate` (also permitted on dual-column displays)
  - `"Fiber"` → `Dietary fiber`
  - `"Sol fiber"` → `Soluble fiber`
  - `"Insol fiber"` → `Insoluble fiber`
  - `"Sugar alc"` → `Sugar alcohol`
  - `"Vit"` → `Vitamin` (also permitted on standard vertical side-by-side displays)
  - `"Potas"` → `Potassium` (also permitted on standard vertical side-by-side displays)
- **Authorized Unit Abbreviations (§ 101.7(n), § 101.9(b)(7)(iv), (d)(7)(i)):**
  - *Metric:* `"g"` (grams), `"mg"` (milligrams), `"mcg"` (micrograms), `"mL"` (milliliters), `"kJ"` (kilojoules).
  - *Household / Avoirdupois (periods and plural forms optional):* `"tbsp"` (tablespoon), `"tsp"` (teaspoon), `"oz"` (ounce), `"fl oz"` (fluid ounce), `"lb"` (pound), `"gal"` (gallon), `"pt"` (pint), `"qt"` (quart), `"wt"` (weight).

---

### 1.4 Serving Size & Servings Per Container Parsing Rules (§ 101.9(b))
1. **Serving Size Token Structure (§ 101.9(b)(2), (b)(5)–(b)(7)):**
   - Standard syntax is `[Household Quantity + Household Unit] ([Metric Quantity + g/mL])`, such as `"2 slices (56g)"` or `"1 cup (240 mL)"`. (For dietary supplement serving units and `"Per Day"` multipliers, see [Section 3.1](#31-header-serving-size--column-heading-variations--10136b12--e) and [Section 3.4](#34-multi-column-split-continuation--small-package-topologies--10136b2iiie-e812-i2)).
   - **Allowed Household Units:** `cup`, `tbsp`, `tsp`, `piece`, `slice`, `cracker`, `bar`, `jar`, `tray`, `can`, `box`, `package`, `oz`, `fl oz`, or fractions of large discrete units (`1/12 cake`, `1/8 pie`, `1/4 pizza`).
   - **Allowed Fractional Increments:**
     - *Cups:* `1/4` or `1/3` cup increments.
     - *Tablespoons:* `1`, `1 1/3`, `1 1/2`, `1 2/3`, `2`, or `3` tbsp.
     - *Teaspoons:* `1/8`, `1/4`, `1/2`, `3/4`, `1`, or `2` tsp.
     - *Fractional Slices:* `1/2`, `1/3`, `1/4`, `1/5`, `1/6`, or smaller fractions divisible by 2 or 3.
     - *Ounces:* `0.5 oz` increments paired with a visual unit of measure (e.g., `"1 oz (28 g/about 1/2 pickle)"`).
   - **Metric & Ounce Equivalent Rounding (§ 101.9(b)(7)(ii)–(iii)):**
     - The gram (`g`) or milliliter (`mL`) quantity in parentheses is rounded to the nearest whole number for quantities `>= 5 g (mL)`, to the nearest `0.5 g (mL)` between `2` and `5 g (mL)`, and in `0.1 g (mL)` increments below `2 g (mL)`.
     - **Parenthetical Slash Syntax:** May include ounces (`oz` or `fl oz`) or visual dimensions after a slash inside the parentheses, e.g., `"1 slice (28 g/1 oz)"` or `"1 oz (28 g/about 1/2 pickle)"`. When ounces follow the metric measure after a slash, the ounce quantity is expressed in `0.1 oz` increments.
   - **Prepared-Product Parenthetical Suffix (§ 101.9(b)(7)(v)):** For products that only require adding water or another ingredient with insignificant nutrients and no significant change to the nutrient profile, the finished prepared amount may be appended in parentheses at the end of the serving size declaration (e.g., `"1/2 cup (120 mL) concentrated soup (makes 1 cup prepared)"`).
   - **Discrete Unit Weight vs. Reference Amount Thresholds (§ 101.9(b)(2)(i)(A)–(D) & (b)(6)):**
     - `<= 50%` of Reference Amount (RACC): Serving size is the number of whole units that most closely approximates the RACC.
     - `> 50%` to `< 67%` of RACC: Manufacturer may declare `1 unit` or `2 units`.
     - `67%` to `< 200%` of RACC: Serving size must be `1 unit`. Furthermore, any product packaged and sold individually containing `< 200%` of the RACC is a single-serving container and must label the entire container as `1 serving` (with an optional left column per household measure if between `> 150%` and `< 200%` RACC).
     - `200%` to `300%` of RACC: First column is based on the serving size approximating the RACC, and a mandatory second dual-column lists amounts and `% DV` per individual unit (or per container if packaged and sold individually under `§ 101.9(b)(12)(i)`).
   - **Single-Serving Metric Omission (§ 101.9(b)(7)(i)):** Single-serving containers may omit the parenthetical `(g)`/`(mL)` metric weight if it is already declared in the net weight statement on the Principal Display Panel (unless declared on a drained-weight basis). If voluntarily provided, the metric value must match the net quantity statement exactly.
   - **Standard Metric Conversions (§ 101.9(b)(5)(viii)):** `1 tsp = 5 mL`, `1 tbsp = 15 mL`, `1 cup = 240 mL`, `1 fl oz = 30 mL`, `1 oz = 28 g`.
2. **Servings Per Container Modifiers (§ 101.9(b)(8)):**
   - May be omitted entirely on single-serving containers (or when stated in the net quantity of contents declaration, or on raw produce/fish under [Part 4](#part-4-raw-produce--fish-point-of-purchase-variations--1014210145)).
   - Between 2 and 5 servings, values are rounded to the nearest `0.5` increment; above 5, to the nearest whole number.
   - **Prefix Modifiers to Parse:**
     - `"about"` (mandatory whenever the serving count is rounded, e.g., `"about 2 servings"`, `"about 3.5 servings"`).
     - `"usually"` (e.g., `"usually 5 servings"` on drained-solids products like pickles or maraschino cherries).
     - `"varied"` (e.g., `"varied"` or `"varied (5 servings)"` on random-weight cheeses or gift packages).

---

### 1.5 Mathematical Cross-Validation Constants (DRV, RDI, & Atwater)
The Swift parser can use these exact regulatory constants from `§ 101.9(c)` (also referenced by `§ 101.36(b)(2)` in [Part 3](#part-3-subpart-c--dietary-supplements-supplement-facts-specification--10136)) to mathematically verify OCR reads—detecting dropped decimal points or misread digits by checking if `(Scanned Amount / DRV or RDI) * 100 ≈ Scanned % DV`. Under `§ 101.9(d)(7)(ii)`, conventional labels may compute `% DV` by dividing *either* the declared (rounded) label amount *or* the actual (unrounded) amount by the DRV, so the validator must allow for `±1%` rounding tolerance (see [Section 3.2.1](#32-two-tiered-ingredient-partitioning--modified-nutrient-order--10136b23--e6) for the stricter Supplement Facts calculation rule):

1. **Daily Reference Values (DRVs) Across Demographics (§ 101.9(c)(9) & (c)(7)(iii)):**
   - **Total Fat (`g`):** Adults/Children `>= 4 yrs = 78 g` | Infants `<= 12 mos = 30 g` | Children `1–3 yrs = 39 g` | Pregnant/Lactating `= 78 g`.
   - **Saturated Fat (`g`):** Adults/Children `>= 4 yrs = 20 g` | Infants `= N/A` | Children `1–3 yrs = 10 g` | Pregnant/Lactating `= 20 g`.
   - **Cholesterol (`mg`):** Adults/Children `>= 4 yrs = 300 mg` | Infants `= N/A` | Children `1–3 yrs = 300 mg` | Pregnant/Lactating `= 300 mg`.
   - **Total Carbohydrate (`g`):** Adults/Children `>= 4 yrs = 275 g` | Infants `= 95 g` | Children `1–3 yrs = 150 g` | Pregnant/Lactating `= 275 g`.
   - **Sodium (`mg`):** Adults/Children `>= 4 yrs = 2,300 mg` | Infants `= N/A` | Children `1–3 yrs = 1,500 mg` | Pregnant/Lactating `= 2,300 mg`.
   - **Dietary Fiber (`g`):** Adults/Children `>= 4 yrs = 28 g` | Infants `= N/A` | Children `1–3 yrs = 14 g` | Pregnant/Lactating `= 28 g`.
   - **Added Sugars (`g`):** Adults/Children `>= 4 yrs = 50 g` | Infants `= N/A` | Children `1–3 yrs = 25 g` | Pregnant/Lactating `= 50 g`.
   - **Protein (`g` - DRV/RDI combined):** Adults/Children `>= 4 yrs = 50 g` | Infants `= 11 g` | Children `1–3 yrs = 13 g` | Pregnant/Lactating `= 71 g`.
2. **Reference Daily Intakes (RDIs) for Vitamins & Minerals (§ 101.9(c)(8)(iv)):**
   - Format below: `Nutrient (Unit): [Adults >= 4 yrs | Infants <= 12 mos | Children 1–3 yrs | Pregnant/Lactating]`:
     - **Vitamin D (`mcg`):** `20 | 10 | 15 | 15`
     - **Calcium (`mg`):** `1,300 | 260 | 700 | 1,300`
     - **Iron (`mg`):** `18 | 11 | 7 | 27`
     - **Potassium (`mg`):** `4,700 | 700 | 3,000 | 5,100`
     - **Vitamin A (`mcg RAE`):** `900 | 500 | 300 | 1,300`
     - **Vitamin C (`mg`):** `90 | 50 | 15 | 120`
     - **Vitamin E (`mg`):** `15 | 5 | 6 | 19`
     - **Vitamin K (`mcg`):** `120 | 2.5 | 30 | 90`
     - **Thiamin (`mg`):** `1.2 | 0.3 | 0.5 | 1.4`
     - **Riboflavin (`mg`):** `1.3 | 0.4 | 0.5 | 1.6`
     - **Niacin (`mg NE`):** `16 | 4 | 6 | 18`
     - **Vitamin B6 (`mg`):** `1.7 | 0.3 | 0.5 | 2.0`
     - **Folate (`mcg DFE`):** `400 | 80 | 150 | 600`
     - **Vitamin B12 (`mcg`):** `2.4 | 0.5 | 0.9 | 2.8`
     - **Biotin (`mcg`):** `30 | 6 | 8 | 35`
     - **Pantothenic acid (`mg`):** `5 | 1.8 | 2 | 7`
     - **Phosphorus (`mg`):** `1,250 | 275 | 460 | 1,250`
     - **Iodine (`mcg`):** `150 | 130 | 90 | 290`
     - **Magnesium (`mg`):** `420 | 75 | 80 | 400`
     - **Zinc (`mg`):** `11 | 3 | 3 | 13`
     - **Selenium (`mcg`):** `55 | 20 | 20 | 70`
     - **Copper (`mg`):** `0.9 | 0.2 | 0.3 | 1.3`
     - **Manganese (`mg`):** `2.3 | 0.6 | 1.2 | 2.6`
     - **Chromium (`mcg`):** `35 | 5.5 | 11 | 45`
     - **Molybdenum (`mcg`):** `45 | 3 | 17 | 50`
     - **Chloride (`mg`):** `2,300 | 570 | 1,500 | 2,300`
     - **Choline (`mg`):** `550 | 150 | 200 | 550`
   - **Biochemical Equivalence & Unit Conversions (§ 101.9(c)(8)(iv) Footnotes 3–7):**
     - *Vitamin A (`RAE` = Retinol Activity Equivalents):* `1 mcg RAE = 1 mcg retinol = 2 mcg supplemental beta-carotene = 12 mcg dietary beta-carotene = 24 mcg dietary alpha-carotene = 24 mcg dietary beta-cryptoxanthin`.
     - *Vitamin E (`alpha-tocopherol`):* `1 mg alpha-tocopherol (label claim) = 1 mg alpha-tocopherol = 1 mg RRR-alpha-tocopherol = 2 mg all-rac-alpha-tocopherol`.
     - *Niacin (`NE` = Niacin Equivalents):* `1 mg NE = 1 mg niacin = 60 mg tryptophan`.
     - *Folate (`DFE` = Dietary Folate Equivalents):* `1 mcg DFE = 1 mcg naturally occurring folate = 0.6 mcg folic acid`.
3. **Caloric Energy Cross-Check Factors (§ 101.9(c)(1)(i)):**
   - **General 4-4-9 Rule:** `Protein = 4 cal/g`, `Total Carbohydrate = 4 cal/g` (or minus non-digestible carbs and sugar alcohols, with soluble non-digestible carbs at `2 cal/g`), `Total Fat = 9 cal/g`.
   - **Sugar Alcohol Caloric Factors:** Isomalt (`2.0 cal/g`), Lactitol (`2.0 cal/g`), Xylitol (`2.4 cal/g`), Maltitol (`2.1 cal/g`), Sorbitol (`2.6 cal/g`), Hydrogenated starch hydrolysates (`3.0 cal/g`), Mannitol (`1.6 cal/g`), and Erythritol (`0 cal/g`).
   - **Sub-Nutrient Ceiling Rule (§ 101.9(g)(10)(v)(B)):** Declared `Added Sugars` can never exceed declared `Total Sugars` on the label.

---

### 1.6 Visual Typography & Adjacency Heuristics (§ 101.4 & § 101.9(d))
1. **Bounding-Box Height (Font Size) Hierarchy (§ 101.9(d)(1)(iii) & (d)(2)–(3)):**
   - **Largest Bounding Box (`>= 22 pt`, or `>= 14 pt` on small packages):** Numeric `"Calories"` value.
   - **Second Largest (`>= 16 pt`, or `>= 10 pt` on small packages):** The `"Calories"` label and `"Nutrition Facts"` title.
   - **Medium (`>= 10 pt`, or `>= 9 pt` on small packages; `>= 8 pt` if `"Serving size"` cannot fit):** `"____ servings per container"` and `"Serving size"`.
   - **Standard Body (`>= 8 pt`, or `>= 6 pt` on small `<12` sq. in. packages):** Nutrient rows and micronutrient declarations.
   - **Smallest (`>= 6 pt`):** `"Amount per serving"`, `"% Daily Value*"`, footnotes, and caloric conversion lines.
2. **Bold Highlighting & Reverse-Printing Invariants (§ 101.9(d)(1)(i) & (iv)):**
   - Only `"Nutrition Facts"`, `"Serving size"`, `"Amount per serving"`, `"% Daily Value*"`, unindented top-level nutrient names (`"Calories"`, `"Total Fat"`, `"Cholesterol"`, `"Sodium"`, `"Total Carbohydrate"`, `"Protein"`), and `"% Daily Value"` percentage numbers are bolded. Sub-nutrients (`Saturated Fat`, `Trans Fat`, `Dietary Fiber`, `Total Sugars`, `Added Sugars`) and quantitative weights (`g`/`mg`/`mcg`) are never bolded.
   - **Reverse Printing Prohibited:** Reverse printing (white/light text on a dark/black background) is legally prohibited as a form of highlighting; the label must use black or single-color type on a white or neutral contrasting background whenever practical.
3. **Out-of-Table Ingredient List Parsing (§ 101.4(a), (b), (g)):**
   - Located immediately below or contiguous and to the right of the nutrition label, prefixed by `"Ingredients"` or `"Other ingredients"`. See [Part 2](#part-2-ingredient-list-parsing-specification--1012--1014---10122) for complete ingredient list tokenization rules.

---

## Part 2: Ingredient List Parsing Specification (§ 101.2, § 101.4, & § 101.22)

### 2.1 Spatial Location & Header Anchor Tokens (§ 101.2 & § 101.4)
Because ingredient lists sit outside the gridded Nutrition Facts table, `RecognizeDocumentsRequest` returns them inside `DocumentObservation.Container.text.paragraphs` rather than `.tables`. The spatial parser can locate and anchor the ingredient block using these rules:

- **Conventional Foods Placement (§ 101.2(a), (d), (e) & § 101.4(a)(1)):** The ingredient list appears on either the Principal Display Panel or the Information Panel in one continuous block without intervening material. On two-piece containers (separate lid and body), the nutrition label may appear on the body while the ingredient statement appears on the lid, or vice versa (see [Section 6.1](#61-principal-display-panel-pdp--information-panel-geometry--1011-1012--10115)).
- **Dietary Supplements Placement (§ 101.4(g)):** Must be located **immediately below** the nutrition (`Supplement Facts`) label, or if space is insufficient below, **immediately contiguous and to the right** of the nutrition label.
- **Mandatory Prefix Anchors (§ 101.4(g)):**
  - `"Ingredients"` (or `"Ingredients:"`): Used when no dietary ingredient sources are listed inside the nutrition table.
  - `"Other ingredients"` (or `"Other ingredients:"`): Mandatory on dietary supplements whenever any dietary ingredients or their sources are already declared inside the `Supplement Facts` table (see [Section 3.3](#33-inline-source-compound-declarations--10136d)).
  - *Dietary Supplement Deduplication Rule (§ 101.4(a)(1) & (g)):* Dietary ingredients listed inside the `Supplement Facts` box do not need to be repeated in the external ingredient list, which instead contains excipients, fillers, artificial colors, artificial sweeteners, flavors, and binders.

---

### 2.2 Structural Grammar of an Ingredient Statement (§ 101.4)
Unlike a flat comma-separated list, an FDA-compliant ingredient statement is a **hierarchical string** with parenthetical sub-lists, conditional `"or"` clauses, and a non-ordered tail segment (plus optional asterisked disclaimers governed by [Section 5.1](#51-ingredient-list-asterisk-footnotes---1016010162---10167)). The Swift tokenizer must parse three structural patterns:

1. **Primary Descending-Weight Sequence (§ 101.4(a)(1)):**
   - All primary ingredients (`>2%` by weight) are listed by their specific common or usual name in strict descending order of predominance by weight.
   - **Reconstituted Ingredients & Water (§ 101.4(c)):** If water is added to reconstitute a class-named ingredient, its position in the weight order is based on the single-strength reconstituted weight; any excess water added beyond single strength must be declared separately as `"water"`.
2. **The `<= 2%` Quantifying Tail Clause (§ 101.4(a)(2)):**
   - Descending weight order stops when the parser encounters a quantifying threshold phrase at the end of the ingredient statement, such as `"Contains __ percent or less of ______"` or `"Less than __ percent of ______"`.
   - **Valid Threshold Constants:** The percentage in the quantifying phrase is restricted to four legal values: `2%`, `1.5%`, `1.0%`, or `0.5%` (written as `"percent"` or `"%"`). All ingredients following this delimiter are present at or below that threshold in arbitrary order.
3. **Nested Parenthetical Sub-Ingredients & Qualifiers (§ 101.4(b)(2), (d), (e), (h)):**
   - The tokenizer must not split blindly on commas inside parentheses `(...)`, as parentheses serve five distinct legal roles in `§ 101.4`:
     - **Compound Ingredient Expansion (§ 101.4(b)(2)(i)):** A multi-component ingredient may state its common name followed by a parenthetical list of its sub-ingredients in descending order of weight (e.g., `"enriched flour (wheat flour, niacin, reduced iron, thiamin mononitrate, riboflavin, folic acid)"`).
     - **Variable Blend Clauses (§ 101.4(b)(14)–(19), (23)):** Inside parentheses for fats/oils, leavening, yeast nutrients, dough conditioners, firming agents, and fish protein, the sub-list may include non-deterministic indicator phrases: `"or"`, `"and/or"`, or `"contains one or more of the following:"`.
     - **Percentage Weight Declarations (§ 101.4(e)):** If an ingredient's weight percentage is declared, it appears in parentheses right after the ingredient name rounded to the nearest `1%`.
     - **Allergen / Source Disclaimers (§ 101.4(d)):** On foods labeled `"nondairy"`, any caseinate ingredient must be followed by a parenthetical source qualifier such as `"(a milk derivative)"`.
     - **Botanical Latin Binomials & Plant Parts (§ 101.4(h)):** On dietary supplements containing botanicals, fungi, or algae, parentheses after the common name may hold the **plant part** in English (e.g., `"Garlic (bulb)"`, `"flower"`, `"root"`, `"leaves"`) and/or the **Latin binomial name** and author designation.

---

### 2.3 Collective Class Names & Variable Blend Rules (§ 101.4(b))
To normalize ingredients into structured categories in the iOS app, the parser should recognize these FDA-mandated collective wrappers and class aliases:

- **6 Collective Wrapper Categories (Parenthetical Expansion Required):**
  1. **Fats & Oils (§ 101.4(b)(14)):** Individual fats/oils are declared by specific name (`"beef fat"`, `"cottonseed oil"`), or grouped under `"______ shortening"` or `"blend of ______ oils"` (where the blank is `"vegetable"`, `"animal"`, `"marine"`, or a combination) followed by parenthetical individual oils. If completely or partially hydrogenated, the terms `"hydrogenated"` or `"partially hydrogenated"` must precede either the individual oil or the blend name (e.g., `"hydrogenated vegetable oil (soybean, cottonseed, and palm oils)"`).
  2. **Leavening Agents (§ 101.4(b)(16)):** Declared as `"leavening"` followed by parenthetical agents (e.g., `"leavening (baking soda, monocalcium phosphate, and calcium carbonate)"`).
  3. **Yeast Nutrients (§ 101.4(b)(17)):** Declared as `"yeast nutrients"` followed by parenthetical nutrients (e.g., `"yeast nutrients (calcium sulfate and ammonium phosphate)"`).
  4. **Dough Conditioners (§ 101.4(b)(18)):** Declared as `"dough conditioners"` (or `"dough conditioner"`) followed by parenthetical conditioners (e.g., `"dough conditioners (L-cysteine, ammonium sulfate)"`).
  5. **Firming Agents (§ 101.4(b)(19)):** Declared as `"firming agents"` followed by parenthetical salts.
  6. **Fish Protein (§ 101.4(b)(23)):** Declared as `"fish protein"` followed by parenthetical species (e.g., `"fish protein (contains one or more of the following: Pollock, cod, and/or pacific whiting)"`).
- **Standardized Dairy, Egg, Flour, & Sugar Aliases (§ 101.4(b)(3)–(12), (15), (20), (22)):**
  - *Dairy:* Concentrated, reconstituted, or dried forms normalize to `"skim milk"` / `"nonfat milk"`, `"milk"`, `"buttermilk"`, `"whey"`, `"cream"`, or `"butterfat"`. Bacterial cultures are declared as `"cultured [substrate]"` (e.g., `"cultured skim milk"`).
  - *Eggs:* Dried, frozen, or liquid forms normalize to `"eggs"`, `"egg whites"`, or `"egg yolks"`.
  - *Wheat Flours:* Must end with `"flour"`, specifically `"flour"`, `"white flour"`, `"wheat flour"`, `"plain flour"`, `"durum flour"`, `"whole wheat flour"`, `"graham flour"`, `"entire wheat flour"`, or `"whole durum wheat flour"`.
  - *Sugar:* The standalone token `"sugar"` legally designates sucrose derived from sugar cane or sugar beets.
  - *Fresh Produce Wax/Resin Coatings:* Declared via collective phrases `"coated with food-grade animal-based wax, to maintain freshness"` or `"coated with food-grade vegetable-, petroleum-, beeswax-, and/or shellac-based [or lac-resin] wax or resin, to maintain freshness"`.

---

### 2.4 Spices, Flavorings, Colorings, & Chemical Preservatives (§ 101.22)
Section 101.22 defines how additives are tokenized inside the ingredient statement (for front-of-pack characterizing flavor declarations under `§ 101.22(i)`, see [Section 6.2](#62-statement-of-identity-product-form--characterizing-flavor-metadata--1013--10113--10118---10122i)):

1. **Chemical Preservatives (Mandatory Name + Function Pair) (§ 101.22(a)(5) & (j)):**
   - Whenever a chemical preservative is present, the ingredient list must declare **both** the specific chemical name **and** a separate description of its function—such as `"preservative"`, `"to retard spoilage"`, `"a mold inhibitor"`, `"to help protect flavor"`, or `"to promote color retention"` (for example, `"sodium benzoate (to preserve freshness)"` or `"BHT (a preservative)"`).
   - *Exclusions:* Salt, sugars, vinegars, spices, spice oils, and direct wood smoke are not classified as chemical preservatives.
2. **Color Additives (§ 101.22(a)(2) & (k)):**
   - **Certified Colors (§ 101.22(k)(1)):** Declared by the color name and number **without** `"FD&C"` or `"No."`, plus `"Lake"` if applicable (e.g., `"Yellow 6"`, `"Red 40"`, `"Blue 1 Lake"`), optionally followed by a parenthetical alternative name.
   - **Uncertified Colors (§ 101.22(k)(2)):** Declared generically as `"Artificial Color"`, `"Artificial Color Added"`, `"Color Added"`, or specifically as `"Colored with [name]"` or `"[name] color"`.
   - **Spices That Are Also Colors (§ 101.22(a)(2)):** `Paprika`, `turmeric`, and `saffron` must be declared either by their specific name or as `"spice and coloring"`.
3. **Flavorings & Spices (§ 101.22(a)(1)–(3) & (h)):**
   - **Collective Tokens (§ 101.22(h)(1), (6)):** May be grouped as `"spice"`, `"natural flavor"`, `"artificial flavor"`, `"artificial smoke flavor"`, or combinations thereof.
   - **Mandatory Specific-Name Exceptions (§ 101.22(h)(3)–(5), (7)):**
     - Processed vegetable/meat tissues (`"powdered or granulated onions"`, `"garlic powder"`, `"celery powder"`) must be declared by their common food name, never as `"spice"` or `"natural flavor"`.
     - Sodium chloride must be declared as `"salt"`.
     - MSG must be declared as `"monosodium glutamate"`.
     - Protein hydrolysates (e.g., hydrolyzed soy protein) must be declared by their specific name, never as `"flavor"` or `"natural flavor"`.
   - **Enumerated Spice Lexicon (§ 101.22(a)(2)):** `Allspice`, `Anise`, `Basil`, `Bay leaves`, `Caraway seed`, `Cardamon`, `Celery seed`, `Chervil`, `Cinnamon`, `Cloves`, `Coriander`, `Cumin seed`, `Dill seed`, `Fennel seed`, `Fenugreek`, `Ginger`, `Horseradish`, `Mace`, `Marjoram`, `Mustard flour`, `Nutmeg`, `Oregano`, `Paprika`, `Parsley`, `Pepper, black`, `Pepper, white`, `Pepper, red`, `Rosemary`, `Saffron`, `Sage`, `Savory`, `Star aniseed`, `Tarragon`, `Thyme`, and `Turmeric`.

---

## Part 3: Subpart C — Dietary Supplements (`Supplement Facts`) Specification (§ 101.36)
When the Vision classifier detects the title `"Supplement Facts"` instead of `"Nutrition Facts"`, it must switch to the `§ 101.36` parsing rules below:

### 3.1 Header, Serving Size, & Column Heading Variations (§ 101.36(b)(1)–(2) & (e))
- **Title & Serving Subheadings (§ 101.36(b)(1) & (e)(1)):**
  - The title `"Supplement Facts"` is bolded at full width in a type size larger than all other print on the label.
  - `"Serving Size"` is aligned on the left beneath `"Supplement Facts"` and expressed in dosage-form units such as `"tablets"`, `"capsules"`, `"packets"`, `"caplets"`, or `"teaspoonfuls"`.
  - `"Servings Per Container"` is aligned on the left beneath `"Serving Size"`, or omitted entirely if already stated in the net quantity of contents declaration on the package.
  - A heavy bar separates `"Servings Per Container"` (or `"Serving Size"`, if servings per container is omitted) from the column headings below.
- **Dynamic Column Headings (§ 101.36(b)(2)(i)(A) & (b)(2)(iii)(A)):**
  - Unlike conventional foods, `"Amount Per Serving"` may be replaced by a dosage-specific heading such as `"Each Tablet Contains"` or `"Amount Per 2 Tablets"` (or substituting `"capsule"`, `"packet"`, or `"teaspoonful"`).
  - The right-hand column heading `"% Daily Value"` (which may be abbreviated as `"% Daily Value (DV)"`, `"% DV"`, `"Percent Daily Value"`, or `"Percent DV"`) sits on the same horizontal line as `"Amount Per Serving"`, underlined by a light bar.
  - **Complete Omission of the `% DV` Column (§ 101.36(b)(2)(iii)(G)):** If a supplement declares only calories/calories from saturated fat, or declares only non-RDI/DRV `"other dietary ingredients"`, the entire `"% DV"` column may be omitted from the table.

---

### 3.2 Two-Tiered Ingredient Partitioning & Modified Nutrient Order (§ 101.36(b)(2)–(3) & (e)(6))
A `Supplement Facts` table is vertically divided by a **heavy bar** into two distinct regulatory zones:

1. **Upper Tier — `(b)(2)-Dietary Ingredients` (Nutrients with Established RDIs or DRVs):**
   - **Strict Zero-Omission Rule (§ 101.36(b)(2)(i)):** Any core nutrient or vitamin/mineral that is absent or present in an amount legally declared as zero in [Section 1.2](#12-canonical-nutrient-hierarchy-nomenclature-units--rounding--1019c--d) (including `<2% RDI` for vitamins and minerals) **must not be listed** on a `Supplement Facts` panel. Furthermore, `"Protein"` must never be declared on products containing only individual amino acids.
   - **Modified Vitamin & Mineral Sequence (§ 101.36(b)(2)(i)(B)):** Macronutrients follow standard `§ 101.9(c)` order and indentation (`"Calories"` first, with optional indented `"Calories from saturated fat"`), **except** that `calcium` and `iron` are moved after `choline`, and `sodium` and `potassium` are moved after `chloride`. The parser must expect this exact 29-item micronutrient sequence:
     `Vitamin A` → `vitamin C` → `vitamin D` → `vitamin E` → `vitamin K` → `thiamin` → `riboflavin` → `niacin` → `vitamin B6` → `folate and folic acid` → `vitamin B12` → `biotin` → `pantothenic acid` → `choline` → `calcium` → `iron` → `phosphorus` → `iodine` → `magnesium` → `zinc` → `selenium` → `copper` → `manganese` → `chromium` → `molybdenum` → `chloride` → `sodium` → `potassium` → `fluoride`.
   - **Synonyms & Nested Beta-Carotene Syntax (§ 101.36(b)(2)(i)(B)(2)–(3) & (ii)(B)):**
     - Permitted parenthetical synonyms: `"Vitamin C (ascorbic acid)"`, `"thiamin (vitamin B1)"`, `"riboflavin (vitamin B2)"`, and `"calories (energy)"` (plus optional parenthetical kilojoules `kJ`).
     - Beta-carotene is declared as a whole percentage adjacent to or beneath `Vitamin A`, optionally with its microgram weight in nested parentheses: `"Vitamin A (90% as beta-carotene)"` or `"Vitamin A (90% (810 mcg) as beta-carotene)"`.
     - `Vitamin D` must be declared in `mcg` and may include parenthetical international units `(IU)` immediately after.
   - **Same-Column vs. Separate-Column Weights (§ 101.36(b)(2)(ii)):** Quantitative weights per serving (representing the weight of the active dietary ingredient itself, not the chemical source compound) may either sit in a separate column to the right of the ingredient names **or** immediately follow the ingredient name inside the same column. Trailing zeros after decimal points may be dropped, and lower amounts may add decimal places (e.g., tenths of a `mg` for zinc).
   - **`% DV` Calculation Basis, Rounding, & Footnote Triggers (§ 101.36(b)(2)(iii)(B)–(F)):**
     - *Unrounded vs. Rounded Calculation Basis:* Calculated by dividing the quantitative amount by weight by the RDI or DRV in [Section 1.5](#15-mathematical-cross-validation-constants-drv-rdi--atwater) and multiplying by `100` using the **unrounded** amount, *except* that for `total fat`, `saturated fat`, `cholesterol`, `sodium`, `potassium`, `total carbohydrate`, and `dietary fiber`, the **rounded** label amount may be used.
     - Expressed to the nearest whole percent, except that DRV nutrients present in a declarable weight whose `% DV` rounds to `0%` must be printed as `"Less than 1%"` or `"<1%"`.
     - Whenever `% DV` is declared for `total fat`, `saturated fat`, `total carbohydrate`, `dietary fiber`, `protein`, or `added sugars`, a footnote symbol must follow the percentage value pointing to `"Percent Daily Values are based on a 2,000 calorie diet"` (or `"1,000 calorie diet"` for children 1–3 years) below the bottom heavy bar.
     - Subcomponents without an established DRV/RDI (such as `total sugars`) carry a symbol in the `% DV` column pointing to `"Daily Value not established"` (or `"Daily Value (DV) not established"` if `"DV"` was used unexplained in the header).
2. **Lower Tier — `(b)(3)` "Other Dietary Ingredients" & Proprietary Blends (§ 101.36(b)(3) & (c)):**
   - Separated from the upper `(b)(2)` tier by a **heavy bar** (or placed directly under `"Amount Per Serving"` if no `(b)(2)` nutrients exist in the product).
   - **Column vs. Linear Display (§ 101.36(b)(3)(i)–(iii)):** Other dietary ingredients (botanicals, amino acids, enzymes, etc.) and their metric weights may be arrayed vertically in a column or horizontally in a **linear display** beneath the heavy bar, provided sub-constituents are not listed. If constituents of an ingredient are declared, they are indented beneath the parent ingredient (in a column or linear string) with their metric weights.
   - **Liquid Extract Ratio & Solvent Syntax (§ 101.36(b)(3)(ii)(B)):** Liquid extracts where the solvent is not removed declare total volume/weight (`mL` or `mg`), starting material state (`fresh` or `dried`), concentration ratio `(y:z)`, and solvent percentage, e.g., `"fresh dandelion root extract, x (y:z) in 70% ethanol"`.
   - **Proprietary Blends (§ 101.36(c)):** Identified by `"Proprietary Blend"` (or a fanciful/descriptive name, optionally bolded) with the **total combined metric weight** of the blend aligned to the right on the same line. The individual `(b)(3)` ingredients in the blend are indented underneath in descending order of weight (in a column or linear list) without individual weights required.
   - **Mandatory Symbol (§ 101.36(b)(3)(iv) & (c)(3)):** Every `(b)(3)` ingredient and `"Proprietary Blend"` total weight must display a symbol in the `"% Daily Value"` column (or immediately after the weight if the `% DV` column is omitted) pointing to the footer `"Daily Value not established"`.

---

### 3.3 Inline Source Compound Declarations (§ 101.36(d))
- Unlike conventional food labels, a `Supplement Facts` table may declare the chemical or botanical source of a nutrient directly inside the table in parentheses immediately following or indented beneath the nutrient name, prefaced by `"as"` or `"from"` (e.g., `"Calcium (as calcium carbonate)"` or `"Calcium (as calcium carbonate USP)"`).
- If two or more sources supply a single nutrient, they are listed inside the parentheses in descending order by weight. Botanical sources must include the English plant part (see [Section 2.2](#22-structural-grammar-of-an-ingredient-statement--1014)).
- When sources are declared inside the table, they are omitted from the external ingredient list, which is then prefixed by `"Other ingredients"` instead of `"Ingredients"` (see [Section 2.1](#21-spatial-location--header-anchor-tokens--1012---1014)).

---

### 3.4 Multi-Column, Split-Continuation, & Small-Package Topologies (§ 101.36(b)(2)(iii)(E), (e)(8)–(12), (i)(2))
- **Multi-Demographic `% DV` Columns (§ 101.36(b)(2)(iii)(E)):** Products intended for multiple age/physiological groups declare separate `% DV` columns side-by-side with explicit group headers (`infants through 12 months`, `children 1 through 3 years`, `adults and children 4 or more years`, `pregnant and lactating women`).
- **Aggregate Supplement Display (§ 101.36(e)(8)):** Products containing two or more distinct supplement packets (e.g., AM packet and PM packet) may use a single aggregate table with separate weight and `% DV` columns for each packet.
- **"Per Unit" and "Per Day" Columns & Multipliers (§ 101.36(e)(9)):**
  - May include additional columns to the right of the `"per serving"` columns headed `"Per Unit"` or `"Per Day"` (followed parenthetically by the daily count, e.g., `"Per Day (3 Caplets)"`).
  - Alternatively (or additionally), the `"Serving Size"` line may contain a parenthetical multiplier instruction: `"Serving Size: 1 Caplet (Multiply amounts by 3 for total daily amount)"` or `"Serving Size: 1 Caplet (Total daily amount: 3 caplets per day)"`.
- **Right-Hand Continuation Split (§ 101.36(e)(12)):** When vertical space is insufficient, the ingredient list inside the box splits and continues in a parallel grid to the right with repeated column headings, separated by a vertical divider line.
- **Small-Package All-Caps & Dot-Leader Rows (§ 101.36(e)(3)(iii) & (i)(2)):**
  - Small packages (`<12` sq. in.) may print all text in **ALL UPPERCASE** letters and shrink font size to `4.5 point` (or `6 point` / `4.5 point` on intermediate 12–40 sq. in. packages).
  - **Dot-Leader Replacement for Hairlines (§ 101.36(i)(2)(v)):** When `4.5 pt` text cannot fit with horizontal hairline rules, manufacturers may omit the hairlines and connect the dietary ingredient name to its quantitative weight and `% DV` using a **row of dots (`.....`)**. The Swift tokenizer must strip dot-leader runs (`\.{2,}`) when splitting cell transcripts.

---

## Part 4: Raw Produce & Fish Point-of-Purchase Variations (§§ 101.42–101.45)
When scanning a label or point-of-purchase sign for raw fruit, vegetables, or fish under `§ 101.45`, the nutrition panel follows `§ 101.9` ([Part 1](#part-1-conventional-food-nutrition-labeling--1019)) with three structural exceptions:
1. `"Servings per container"` is optional and typically omitted.
2. The footnote may be shortened to a single sentence: `"Percent Daily Values are based on a 2,000 calorie diet."`
3. Multi-item charts or labels may omit `saturated fat`, `trans fat`, and `cholesterol` on fruits/vegetables (replacing them with the footnote `"Most fruits and vegetables provide negligible amounts of saturated fat, trans fat, and cholesterol; avocados provide 0.5 g of saturated fat per ounce"`), or omit `trans fat`, `dietary fiber`, and `sugars` on fish (with the footnote `"Fish provide negligible amounts of trans fat, dietary fiber, and sugars."`).

---

## Part 5: Subpart D — How Nutrient Content Claims Alter Panel & Ingredient Text (§§ 101.54–101.67)
Subpart D mandates three text patterns inside or immediately adjacent to the Nutrition Facts and Ingredient panels that the Vision parser must handle defensively:

### 5.1 Ingredient List Asterisk Footnotes (`*`) (§§ 101.60–101.62 & § 101.67)
- **Trivial-Amount Ingredient Disclaimers:** When a package bears a `"sugar free"` (`§ 101.60(c)(1)(ii)`), `"sodium free"` (`§ 101.61(b)(1)(ii)`), `"fat free"` (`§ 101.62(b)(1)(ii)`), `"saturated fat free"` (`§ 101.62(c)(1)(ii)`), or `"cholesterol free"` (`§ 101.62(d)(1)(i)(B)`) claim, any ingredient in the ingredient list ([Part 2](#part-2-ingredient-list-parsing-specification--1012--1014---10122)) that consumers associate with that nutrient must be tagged with an **asterisk (`*`)** pointing to a statement **immediately below the list of ingredients**:
  - `"*adds a trivial amount of [sugar / sodium / fat / saturated fat / cholesterol]"`
  - `"*adds a negligible amount of [sugar / sodium / fat / saturated fat / cholesterol]"`
  - `"*adds a dietarily insignificant amount of [sugar / sodium / fat / saturated fat / cholesterol]"`
- **Modified Butter Ingredient Footnote (§ 101.67(c)(2)):** On modified butter products bearing a nutrient claim, added texturizers, flavorings, or water in the ingredient statement carry an asterisk (`*`) followed immediately by `"*Ingredients not in regular butter"`.
- **Parser Rule:** The ingredient tokenizer must strip trailing asterisks (`*`) from individual ingredient names and exclude trailing `"*adds a trivial/negligible/dietarily insignificant amount..."` and `"*Ingredients not in regular butter"` clauses from the parsed ingredient array.

---

### 5.2 Decoy Nutrient Strings Placed Adjacent to the Nutrition Box (§§ 101.54–101.62)
- **Relative Claim Quantitative Comparisons:** Whenever a package makes a relative claim (`"more"`, `"fortified"`, `"enriched"`, `"light"` / `"lite"`, `"reduced"`, `"less"`, `"fewer"`, `"lower"`), FDA regulations require a quantitative comparison statement comparing the nutrient level per serving in the labeled product against the reference food—and explicitly specify that this statement be placed **adjacent to the nutrition label** (or on the information panel).
  - *Examples from Subpart D:*
    - `"Fiber content of white bread is 1 gram (g) per serving; (this product) 3.5 g per serving"` (`§ 101.54(e)(1)(iii)(B)`)
    - `"lite cheesecake—200 calories, 4 grams (g) fat per serving; regular cheesecake—300 calories, 8 g fat per serving"` (`§ 101.56(b)(3)(ii)`)
    - `"Calorie content has been reduced from 150 to 100 calories per serving."` (`§ 101.60(b)(4)(ii)(B)`)
    - `"Sugar content has been lowered from 8 g to 6 g per serving."` (`§ 101.60(c)(5)(ii)(B)`)
    - `"Sodium content has been lowered from 300 to 150 mg per serving."` (`§ 101.61(b)(6)(ii)(B)`)
    - `"Fat content has been reduced from 8 g to 4 g per serving."` (`§ 101.62(b)(4)(ii)(B)`)
    - `"Cholesterol lowered from 30 mg to 5 mg per serving; contains 13 g of fat per serving."` (`§ 101.62(d)(2)(iii)(E)(2)`)
- **Adjacent Sodium Disclaimers (§ 101.56(g) & § 101.61(c)(2)(iii)):** Products labeled `"lightly salted"`, `"unsalted"`, `"without added salt"`, or `"no salt added"` that are not low/free in sodium must print `"not a low sodium food"`, `"not a sodium free food"`, or `"not for control of sodium in the diet"` **adjacent to the nutrition label**.
- **Parser Rule:** Because these strings sit right next to the nutrition box and contain exact nutrient names (`Calories`, `Fat`, `Saturated fat`, `Cholesterol`, `Sodium`, `Sugar`, `Fiber`) plus gram/milligram weights, a spatial fallback parser can accidentally ingest the *reference food's* nutrient weight (e.g., reading `300 mg` sodium instead of `150 mg`). Filter out prose sentences containing comparative keywords (`"reduced from"`, `"lowered from"`, `"compared with"`, `"per 3 oz"`, `"regular"`, `"not a low"`, `"not a sodium free"`).

---

### 5.3 Claim-to-Label Mathematical Invariants (Optional OCR Sanity Check)
If the scanner also reads front/information panel claims, Subpart D provides mathematical bounds on the Nutrition Facts values per reference amount/serving (cross-referenced with [Section 1.5](#15-mathematical-cross-validation-constants-drv-rdi--atwater)):
- **Micronutrient / Positive Claims (§ 101.54):** `"High"` / `"Rich in"` / `"Excellent source of"` `>= 20% DV`; `"Good source"` / `"Contains"` / `"Provides"` `= 10%–19% DV`; `"High potency"` `>= 100% RDI`.
- **Calorie & Sugar Claims (§ 101.60):** `"Calorie free"` `< 5 cal`; `"Low calorie"` `<= 40 cal` (`<= 120 cal/100g` for meals/main dishes); `"Sugar free"` `< 0.5 g` sugars.
- **Sodium Claims (§ 101.61):** `"Sodium free"` / `"Salt free"` `< 5 mg`; `"Very low sodium"` `<= 35 mg`; `"Low sodium"` `<= 140 mg`.
- **Fat & Cholesterol Claims (§ 101.62):** `"Fat free"` / `"Skim"` `< 0.5 g` fat; `"Low fat"` `<= 3 g` fat; `"Saturated fat free"` `< 0.5 g` sat fat and `< 0.5 g` trans fat; `"Low saturated fat"` `<= 1 g` sat fat; `"Cholesterol free"` `< 2 mg` cholesterol and `<= 2 g` sat fat; `"Low cholesterol"` `<= 20 mg` cholesterol and `<= 2 g` sat fat; `"Lean"` `< 10 g` fat, `<= 4.5 g` sat fat, and `< 95 mg` cholesterol; `"Extra lean"` `< 5 g` fat, `< 2 g` sat fat, and `< 95 mg` cholesterol.

---

## Part 6: Front-of-Pack (PDP), Package Metadata, & Boxed Warnings Specification (§§ 101.1–101.7, 101.13, 101.15, 101.17, 101.18, & 101.22(i))
For camera scans targeting front-of-pack product identity, brand/manufacturer metadata, net weight, or multi-panel capture, the following regulations govern spatial placement, bounding-box height ratios, and text grammar:

### 6.1 Principal Display Panel (PDP) & Information Panel Geometry (§§ 101.1, 101.2, & 101.15)
- **Principal Display Panel (PDP) Definition & Surface Area (§ 101.1):**
  - The PDP is the part of a label most likely to be displayed, presented, shown, or examined under customary retail conditions. If a package has alternate PDPs, all mandatory PDP statements must be duplicated on each PDP.
  - **PDP Area Calculation (governs minimum font heights in [Section 6.4](#64-net-quantity-of-contents-declaration--1017)):**
    - *Rectangular package:* `height × width` of the entire PDP side.
    - *Cylindrical or nearly cylindrical container:* `40%` of `height × circumference` (all required PDP text must appear within that `40%` of the circumference most likely to be displayed at retail).
    - *Other shapes:* `40%` of total container surface area, unless the package has an obvious PDP such as the top of a circular or triangular cheese package, in which case the PDP area is the entire top surface. Exclude tops, bottoms, flanges at tops/bottoms of cans, and shoulders/necks of bottles or jars.
- **Information Panel Location & Continuity (§ 101.2):**
  - The Information Panel is the panel immediately contiguous and to the **right** of the PDP as observed facing the PDP (or the next panel to the right if the immediate right panel is too small or unusable due to folded flaps or can ends; if the top is the PDP, any panel adjacent to the top).
  - All required Information Panel statements must appear in one place without intervening material, at a minimum character height of `1/16 inch` (reduced to `1/32 inch` on individual restaurant/institutional packets `<= 3 sq. in.` or on certain soft-drink bottle closures where priority order is: `1. Ingredients`, `2. Manufacturer/packer/distributor name & address`, `3. Statement of identity`).
  - **Two-Piece Lid/Body Split (§ 101.2(d)(2)):** On containers with a separate lid and body where the lid serves as the PDP, manufacturer/distributor business info (`§ 101.5`) may appear on the lid while nutrition (`§ 101.9`) and ingredient (`§ 101.4`) statements appear on the body.
- **Prominence & Foreign Language Duplication (§ 101.15):**
  - Mandatory statements must appear in lines generally parallel to the package base on a clear, contrasting background.
  - All required label statements must appear in English (except products distributed solely in Puerto Rico or a U.S. territory where another language predominates). If the label contains *any* representation in a foreign language, all mandatory label statements must be repeated in that foreign language (except individual restaurant/institutional packages `<= 1.5 oz` or `<= 1.5 fl oz` where only the food name is in a foreign language).

---

### 6.2 Statement of Identity, Product Form, & Characterizing Flavor Metadata (§ 101.3, § 101.13, § 101.18, & § 101.22(i))
- **Statement of Identity Placement & Prominence (§ 101.3(a)–(d)):**
  - Must appear as a principal feature on the PDP in **bold type**, in a font size reasonably related to the most prominent printed matter on the PDP, and in lines generally parallel to the package base.
  - **Hierarchy of Identity Names:** `(1)` Name required by Federal law/regulation; `(2)` common or usual name of the food; or `(3)` appropriately descriptive term, or fanciful name commonly used by the public when the food's nature is obvious.
  - **Optional Product Forms (§ 101.3(c)):** When a food is marketed in various optional forms (`"whole"`, `"slices"`, `"diced"`, `"halves"`, etc.), the specific form is a mandatory part of the statement of identity in type size reasonably related to the main identity text (unless the form is visible through a clear container or depicted by vignette).
  - **Dietary Supplement Identity (§ 101.3(g)):** Must include `"dietary supplement"` as part of the statement of identity, or replace `"dietary"` with the ingredient name or category (e.g., `"calcium supplement"`, `"herbal supplement with vitamins"`).
- **Imitation, Modified, & Weight-Control Identity Qualifiers (§ 101.3(e), § 101.9(b)(2), & § 101.13(k)):**
  - *Imitation Foods (§ 101.3(e)):* A substitute food that is nutritionally inferior (`>= 2%` DRV/RDI reduction in any essential nutrient other than calories or fat) must bear the word `"imitation"` followed immediately by the name of the food imitated, in uniform type size and prominence.
  - *Modified Nutrient Identity (§ 101.13(k)):* A food bearing a relative claim may use `"modified"` in the statement of identity followed immediately by the altered nutrient (e.g., `"Modified fat cheesecake"`), which must be immediately followed by the comparative statement (`"Contains 35 percent less fat than ______"`).
  - *Weight-Control Program Statement (§ 101.9(b)(2)):* Foods intended for weight control and available only through a weight-control program must print `"for sale only through the ______ program"` on the PDP.
- **Characterizing Flavor Modifiers & Bounding-Box Height Ratios (§ 101.22(i)):**
  - Whenever words, vignettes (e.g., fruit illustrations), or branding on the label represent a primary recognizable flavor, the characterizing flavor must accompany the statement of identity on the PDP using strict font-height ratios:
    1. *No Simulating Artificial Flavor (§ 101.22(i)(1)):* Declared by the common name of the characterizing flavor (e.g., `"vanilla"`) in letters **`>= 1/2` the height** of the letters in the food name.
    2. *Natural Flavor Insufficient to Independently Characterize (§ 101.22(i)(1)(i)):* Optionally preceded by `"natural"` and mandatorily followed by `"flavored"` (e.g., `"natural strawberry flavored shortcake"` or `"strawberry flavored shortcake"`) in letters **`>= 1/2` the height** of the characterizing flavor name.
    3. *Reinforced with Other Natural Flavors (§ 101.22(i)(1)(iii)):* Followed immediately by `"with other natural flavor"` in letters **`>= 1/2` the height** of the characterizing flavor name.
    4. *Simulating Artificial Flavor (§ 101.22(i)(2)):* Accompanied by `"artificial"` or `"artificially flavored"` (e.g., `"artificial vanilla"`, `"artificially flavored strawberry"`, `"grape artificially flavored"`, or a generic blend term for 3+ flavors like `"artificially flavored fruit punch"`) in letters **`>= 1/2` the height** of the characterizing flavor name.
    5. *Adjacency Rule (§ 101.22(i)(3)):* Required flavor qualifier words must immediately precede or follow the characterizing flavor name without intervening material (except associated trademark/brand elements).
- **Front-of-Pack Claim Font Cap & Disclosure Triggers (§ 101.13(d), (f), (h), (i)):**
  - *Type-Size Ceiling (§ 101.13(f)):* A nutrient content claim on the label may never exceed **`2x` the type size** of the statement of identity.
  - *Mandatory Referral Disclosure Statement (§ 101.13(h)):* If a food bearing a nutrient content claim exceeds disqualifying levels per RACC or labeled serving (or per `50 g` if RACC `<= 30 g` or `<= 2 tbsp`): `> 13.0 g` total fat, `> 4.0 g` saturated fat, `> 60 mg` cholesterol, or `> 480 mg` sodium (meal products: `26 g` / `8.0 g` / `120 mg` / `960 mg`; main dishes: `19.5 g` / `6.0 g` / `90 mg` / `720 mg`), it must print `"See nutrition information for ______ content"` in boldface immediately adjacent to the largest claim on every panel (except the panel bearing the nutrition label).
  - *Substitute Performance Disclaimer (§ 101.13(d)):* If a substitute food has a material performance limitation compared to the regular food, a disclaimer must appear adjacent to the most prominent claim (`>= 1/2` claim size, floor `1/16 in`), e.g., `"not recommended for frying"` or `"not recommended for baking purposes"` (`§ 101.67(b)`).
- **Misbranding & Geographic Origin Rules (§ 101.18):**
  - Designating a multi-ingredient food by a name that includes or suggests only one or some of its ingredients is prohibited. Geographic origin representations are restricted to truthful origins, long-established non-deceptive trademarks, legally required names, or terms understood to denote a generic class/style of food.

---

### 6.3 Manufacturer, Packer, or Distributor Metadata (§ 101.5)
- **Entity Name (§ 101.5(a)–(b)):** Must conspicuously specify the actual corporate name (optionally preceded or followed by a corporate division name), or the business name for an individual, partnership, or association.
- **Relationship Qualifier Phrases (§ 101.5(c)):** If the named entity is not the actual manufacturer, the corporate name must be qualified by a phrase revealing the connection, such as `"Manufactured for ______"`, `"Distributed by ______"`, or equivalent wording.
- **Place of Business Address Grammar (§ 101.5(d)–(e)):** Must include the street address (which may be omitted if the entity is listed in a current city or telephone directory), city, State, and ZIP code. The principal place of business may be stated in lieu of the actual manufacturing/packing plant address.

---

### 6.4 Net Quantity of Contents Declaration (§ 101.7)
- **Spatial Location & Clear-Space Margins (§ 101.7(e)–(f)):**
  - Must appear as a distinct item on the PDP within the **bottom `30%`** of the PDP area (the bottom `30%` rule is waived if the PDP area is `<= 5 sq. in.`), in lines generally parallel to the package base.
  - **Mandatory Whitespace Buffer:** Separated from printed text above and below by a space `>= 1x` the letter height of the net quantity declaration, and from printed text to the left and right by a space `>= 2x` the width of the letter `"N"`.
- **Typography & Area-Scaled Minimum Heights (§ 101.7(h)–(i)):**
  - Printed in boldface, high-contrast type where letters are never more than `3x` as high as they are wide (`<= 3:1` aspect ratio, measured on uppercase letters or lowercase `"o"`, with fraction numerals `>= 1/2` minimum height).
  - **Minimum Type Height by PDP Surface Area:**
    - PDP `<= 5 sq. in.`: `>= 1/16 inch`
    - PDP `> 5` to `<= 25 sq. in.`: `>= 1/8 inch`
    - PDP `> 25` to `<= 100 sq. in.`: `>= 3/16 inch`
    - PDP `> 100` to `<= 400 sq. in.`: `>= 1/4 inch`
    - PDP `> 400 sq. in.`: `>= 1/2 inch`
    - *(Increase minimum height by `1/16 inch` if blown, embossed, or molded onto glass or plastic).*
- **Token Grammar, Units, & Dual Declarations (§ 101.7(a)–(d), (j)–(s)):**
  - *Unit Basis:* Fluid measure (`gal`, `qt`, `pt`, `fl oz`) for liquids; avoirdupois weight (`lb`, `oz`) for solids, semisolids, viscous products, or solid/liquid mixtures (pickles/relishes in `gal`/`qt`/`pt`/`fl oz`); dry measure (`bushel`, `peck`, `dry qt`, `dry pt`) for fresh fruits/vegetables; or numerical count combined with weight/measure.
  - *Packages Under `4 lb` or `1 gal` (§ 101.7(j) & (m)):* Declared first in total ounces (`oz` or `fl oz`), followed in parentheses (if `>= 1 lb` or `>= 1 pt`) by the largest whole unit (`lb`, `qt`, `pt`) and remainder in ounces or common (`1/2`, `1/4`, `1/8`, `1/16`, `1/32`) or decimal (max 2 decimal places) fractions:
    - Weight examples: `"Net Wt. 24 oz (1 lb 8 oz)"`, `"Net Wt. 24 oz (1 1/2 lb)"`, `"Net Wt. 24 oz (1.5 lb)"`, `"Net Wt. 12 oz"`, or `"6 oz Net wt."` (Random-weight packages may use decimal pounds, e.g., `"Net Wt. .75 lb"`).
    - Fluid examples: `"Net 32 fl oz (1 qt)"`, `"Net contents 56 fluid ounces (1 quart 1 1/2 pints)"`, `"Net 56 fluid oz (1 qt 1 pt 8 oz)"`, or `"6 fl oz"`.
  - *Packages `4 lb` or `1 gal` and Above (§ 101.7(k) & (m)(6)):* Declared directly in the largest whole unit (`lb` or `gal`) followed by remainder (e.g., `"Net contents 2 1/2 gallons"`, `"Net contents 2.5 gallons"`, or `"Net contents 2 gallons 2 quarts"`).
  - *Multiunit Retail Packages (§ 101.7(s)):* Declares unit count, individual unit quantity, and parenthetical total ounces: `"6-16 oz bottles—(96 fl oz)"` or `"3-16 oz cans—(net wt. 48 oz)"`.
  - *Prefixes, Abbreviations, & Metric Statements (§ 101.7(j)(3), (n), (o), (p)):* The term `"net weight"` (or `"Net wt."`) is mandatory for weight declarations; `"Net"` or `"Net contents"` is optional for fluid or count declarations. Only the abbreviations `wt`, `oz`, `lb`, `gal`, `pt`, `qt`, and `fl` (periods and plurals optional) are permitted; exaggerating qualifiers (`"jumbo quart"`, `"full gallon"`) are prohibited. A separate metric statement (`g`, `kg`, `mL`, `L`) may appear on the PDP or other panels.

---

### 6.5 Mandatory Boxed Warnings & Safe-Handling Statements (§ 101.17)
Several mandatory `§ 101.17` warning statements are enclosed in **hairline boxes** on the Information Panel or PDP. The Vision pipeline must filter out these canonical warning blocks so `RecognizeDocumentsRequest` does not misclassify a hairline-boxed warning as a Nutrition Facts or Supplement Facts table:

1. **Dietary Supplements Containing Iron in Solid Oral Dosage Form (§ 101.17(e)):**
   - **Enclosed in a hairline box** on the Information Panel:
     `"WARNING: Accidental overdose of iron-containing products is a leading cause of fatal poisoning in children under 6. Keep this product out of reach of children. In case of accidental overdose, call a doctor or poison control center immediately."`
2. **Unpasteurized Fruit/Vegetable Juices (§ 101.17(g)):**
   - **Enclosed in a hairline box** on the Information Panel or PDP with `"WARNING"` bolded in all caps:
     `"WARNING: This product has not been pasteurized and, therefore, may contain harmful bacteria that can cause serious illness in children, the elderly, and persons with weakened immune systems."`
3. **Shell Eggs Safe Handling Instructions (§ 101.17(h)):**
   - **Enclosed in a hairline box** on the PDP, Information Panel, or inside the egg carton lid (with `"Keep Refrigerated"` on the outer panel) and `"SAFE HANDLING INSTRUCTIONS"` in bold:
     `"SAFE HANDLING INSTRUCTIONS: To prevent illness from bacteria: keep eggs refrigerated, cook eggs until yolks are firm, and cook foods containing eggs thoroughly."`
4. **Self-Pressurized Containers & Propellants (§ 101.17(a)–(b)):**
   - `"WARNING—Avoid spraying in eyes. Contents under pressure. Do not puncture [or break] or incinerate. Do not store at temperature above 120 °F. Keep out of reach of children [except under adult supervision]."`
   - With halocarbon/hydrocarbon propellants: `"WARNING—Use only as directed. Intentional misuse by deliberately concentrating and inhaling the contents can be harmful or fatal."`
5. **High-Protein (`>50%` Caloric Value) Weight-Reduction & Supplement Products (§ 101.17(d)):**
   - On the PDP and labeling:
     - Very-low-calorie weight reduction: `"WARNING: Very low calorie protein diets (below 400 Calories per day) may cause serious illness or death. Do Not Use for Weight Reduction in Such Diets Without Medical Supervision. Not for use by infants, children, or pregnant or nursing women."`
     - Balanced diet plan (`>= 400 cal/day`): `"Notice: For weight reduction, use only as directed in the accompanying diet plan. Do not use in diets supplying less than 400 Calories per day without medical supervision."`
     - Non-weight-reduction protein supplements: `"Notice: Use this product as a food supplement only. Do not use for weight reduction."`
6. **Dry or Incompletely Hydrated Psyllium Husk Foods (§ 101.17(f)):**
   - On the Information Panel or PDP, preceded by `"NOTICE"` in capital letters:
     `"NOTICE: This food should be eaten with at least a full glass of liquid. Eating this product without enough liquid may cause choking. Do not eat this product if you have difficulty in swallowing."`