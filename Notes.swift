//
//  Notes.swift
//  NutritionAssistant
//
//  Created by Daniel Becker on 8/6/26.
//

//recognizeDocumentRequest from a round container could prove ineffective
//lock status of macro goals in settings is not saved in user settings but it should be to ensure values are locked over time
// dont forget cookware saver
// damn... with document request we might be able to analyze a screen shot of a recipe and retreive the data from it
    //copy and paste ingredient text
    //link website as recipe source
    



//Recipemodel, addeduntracked weight - might need to refactor / rewrite to allow users to eliminate weight without cooking in rare instances where desired: remove shells / revome crust ... but crust would change nutrient value... while shells would not


//recipe model needs categories 


//download usda foods as always present


//press and hold food item ; Offer a "Define Raw and Cooked Version"
//maybe needs some kind of subtype or details to have that work
//Variation groups has solved this need

//when editing the ingredients values of a recipeItem in TodayView the RecipeWeightsHalfSheetsSelector displays, but if a weight is updated, this state change does not get passed to the RadialHalfSheetSelector.


//HealthKit to determine user Active and Passive calories, and their weight ? nah they dont record that
// Healthkit should be an option. many people dont have their phone and watch on all the time . 

///
///
///
///
///Breakpoint
///
///Create Healthkit API to retrieve activity data
///Refactor Goals to accomodate a set caloric value as defined by Apple Health -> This maybe should be a toggle setting, such that users can choose - not everyone uses a watch or phone when excercising
///Imput a BMR + TDEE calculator, and a Calorie supplementation or decifit functionality.
///
///
///RecognizeDocumentsRequest
///
///
///Today view reorganization
///Mini history view on TodayView, with graphic chart, maybe weekly metrics
///
/// beautiful , thank you

//We added a method for a user to add a potential category to assign to RecipieItems when creating them in AddRecipeView. Lets add a comprable functionality in AddFoodView, such that a user can create a new food category
///
///
///
///
///
///There is a mix of tooling that ensures compatibility with iOS versions as far back as 16, but that is unneeded 

//DONE: AddFoodView household measurement inputs (HouseholdMeasurementRow). Remaining: optionally show household measure in Food Bank / Today views via MeasurementUnitFormatter.

//NON-ESSENTIAL TEST REMARKS (2026-10-29) — household measurement feature
// Owner decision: manual testing performed so far is sufficient; the items below were NOT run and are non-essential. Revisit only if related issues appear.
// PASSED on device: #1-#12 (create/edit/clear, pairing rule, keyboard, menu categories, suggestion quality, override, cancel paths, duplicates, persistence) and #14 (dialog timing).
//   #14 observation: on iOS 26 the category confirmationDialog renders as a popover anchored to the row with NO visible Cancel button; tapping outside cancels (nothing saved).
//   Optional future: replace with a custom sheet that has an explicit Cancel and a styled "Suggested" tag.
// NOT RUN (non-essential):
// - #13 Fallback with Apple Intelligence unavailable (no Apple Intelligence setting found on the test iPhone). Try a simulator without it, or force SystemLanguageModel availability off. Dialog must still appear and never freeze.
// - #15 Upgrade check: install previous build, add foods, run this build over it; expect no crash and old foods intact (lightweight migration of new optional props + UserMeasurementUnit).
// - #16 CSV round-trip re-test after the share-sheet fix (.sheet(item:)): export foods, delete one, re-import; also an older CSV without household columns and rows with only a name or only an amount.
// - Re-test of this session's UI changes: serving-size change prompt (Yes / No / tap outside) and category chip text no longer truncated ("Spreads & Sauces", "Imported Foods").
//
//OPEN DESIGN QUESTIONS: none outstanding (serving-size prompt and chip truncation were implemented 2026-10-29).

//FUTURE (2026-10-29): FoodItem.commonHouseholdMeasurement and FoodItem.commonHouseholdMeasurementAmount are NOT yet copied when FoodItems are adopted into RecipeItems
// (RecipeIngredient, built via RecipeIngredient.init(from: FoodItem, recipeWeight:)) nor into ConsumedItem (created from FoodItem in FoodBankView / TodayView).
// This will be necessary in the future, but is not needed at this moment. When done: add optional fields (decode-safe, see RecipeIngredient Codable note), copy them at creation,
// and keep the both-set-or-both-nil rule (FoodItem.isValidHouseholdPair). Consider JSON recipe export/import (RecipeItemDTO) compatibility.

//FUTURE (style): In HouseholdMeasurementRow's category confirmation dialog, the "(Suggested)" tag is plain text appended to the title.
// Differentiate it stylistically (e.g. icon/sparkle, bold, or separate section). Note confirmationDialog buttons have limited styling — may need a custom sheet.
//FUTURE: serving UNIT changes (g -> oz/ml/unit) do not trigger the household-adjustment prompt (only serving SIZE changes within the same unit do). Consider g<->oz conversion.
//DONE (2026-10-29): serving-size change prompt (HouseholdAdjustmentPromptView), category chip truncation fix, Export Saved Foods share-sheet fix (.sheet(item:)).
// Original note: AddFoodView had no inputs for FoodItem.commonHouseholdMeasurement / commonHouseholdMeasurementAmount.
// Add a grouped category/unit picker (MeasurementUnitCatalog.grouped) with "Add new unit…" (UserMeasurementUnit),
// confirm category suggested by CompositeCategorySuggester, a numeric amount field (both set together, amount > 0),
// and write them in the edit-mode save path. Optionally display via MeasurementUnitFormatter.


