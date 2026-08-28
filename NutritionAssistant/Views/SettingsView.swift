import SwiftUI
import SwiftData
import Foundation
import TabularData // Apple's built-in framework
import UniformTypeIdentifiers


struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userSettingsList: [UserSettings]
    
    @State private var viewModel = SettingsViewModel()
    
    @State private var exportedCSVURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showFileImporter = false
    @State private var showUserSettingsImporter = false
    @State private var showDeleteAllFoodsAlert = false
    
    // NEW: Recipe JSON Sharing state variables
    @State private var showRecipeExporter = false
    @State private var showRecipeImporter = false
    @State private var recipeExportDocument: AppSharingDocument?
    
    var body: some View {
        // NEW: This explicitly creates perfectly safe bindings for the compiler
        @Bindable var bindableViewModel = viewModel
        
        NavigationStack {
            List {
            Section(
                header: Text("Time Preferences"),
                footer: Text("Set the time your day resets. Any food logged before this time will be grouped with the previous day.")
            ) {
                Picker("Day Start Time", selection: Binding(
                    get: { userSettingsList.first?.dayStartHour ?? 0 },
                    set: { userSettingsList.first?.dayStartHour = $0 }
                )) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(timeString(for: hour)).tag(hour)
                    }
                }
                .tint(.accentColor)
                
                Toggle("HealthKit Data Reflects Selected Time", isOn: Binding(
                    get: { userSettingsList.first?.healthKitCustomDayWindow ?? false },
                    set: { newValue in
                        userSettingsList.first?.healthKitCustomDayWindow = newValue
                        try? modelContext.save()
                    }
                ))
            }
            
            Section(header: Text("UI Preferences")) {
                ColorPicker("Change Primary Color", selection: Binding(
                    get: {
                        Color(hex: userSettingsList.first?.userSelectedPrimaryColorHex ?? "#007AFF")
                    },
                    set: { newColor in
                        if let hex = newColor.toHex() {
                            userSettingsList.first?.userSelectedPrimaryColorHex = hex
                            try? modelContext.save()
                        }
                    }
                ))
            }
            
            Section(header: Text("Goal Values")) {
                
                CalorieAndMacroSectionView(
                    // We use the bindable variable for the inputs
                    calorieInput: $bindableViewModel.calorieInput,
                    fatInput: $bindableViewModel.fatInput,
                    carbInput: $bindableViewModel.carbInput,
                    proteinInput: $bindableViewModel.proteinInput,
                    
                    fatLock: $bindableViewModel.fatLock,
                    carbLock: $bindableViewModel.carbLock,
                    proteinLock: $bindableViewModel.proteinLock,
                    
                    // We use the standard variable for the function calls
                    onSaveCalories: { viewModel.saveCalorieAndMacros(settingsList: userSettingsList) },
                    onSaveMacros: { viewModel.saveMacroGoal(settingsList: userSettingsList) },
                    onLockChanged: { viewModel.saveLocks(settingsList: userSettingsList) }
                )
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional Nutrients")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    GoalRowView(title: "Saturated Fat", value: $bindableViewModel.satFatInput, suffix: "g") {
                        viewModel.saveSatFatGoal(settingsList: userSettingsList)
                    }
                    
                    GoalRowView(title: "Trans Fat", value: $bindableViewModel.transFatInput, suffix: "g") {
                        viewModel.saveTransFatGoal(settingsList: userSettingsList)
                    }
                    
                    GoalRowView(title: "Dietary Fiber", value: $bindableViewModel.fiberInput, suffix: "g") {
                        viewModel.saveFiberGoal(settingsList: userSettingsList)
                    }
                    
                    GoalRowView(title: "Added Sugar", value: $bindableViewModel.sugarInput, suffix: "g") {
                        viewModel.saveSugarGoal(settingsList: userSettingsList)
                    }
                }
                .padding(.vertical, 4)
            }
            
            
            Section(
                header: Text("Data"),
                footer: Text("Export NutriApp data as a .CSV file or import NutriApp date ")
            ) {
                HStack {
                    Button("Export User Settings") {
                        exportUserSettingsToCSV()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Import User Settings") {
                        showUserSettingsImporter = true
                    }
                    .buttonStyle(.bordered)
                    .fileImporter(
                        isPresented: $showUserSettingsImporter,
                        allowedContentTypes: [.commaSeparatedText]
                    ) { result in
                        importUserSettingsFromCSV(result: result)
                    }
                }
                HStack {
                    Button("Export Saved Foods") {
                        exportFoodItemsToCSV()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Import Saved Foods") {
                        showFileImporter = true
                    }
                    .buttonStyle(.bordered)
                    .fileImporter(
                        isPresented: $showFileImporter,
                        allowedContentTypes: [.commaSeparatedText]
                    ) { result in
                        importFoodItemsFromCSV(result: result)
                    }
                }
                
                HStack {
                    Button("Export Saved Recipes") {
                        exportRecipeItemsToJSON()
                    }
                    .buttonStyle(.bordered)
                    .fileExporter(
                        isPresented: $showRecipeExporter,
                        document: recipeExportDocument,
                        contentType: .json,
                        defaultFilename: "NutritionAssistant_Recipes"
                    ) { result in
                        switch result {
                        case .success(let url):
                            print("Successfully exported recipes to \(url)")
                        case .failure(let error):
                            print("Failed to export recipes: \(error.localizedDescription)")
                        }
                    }
                    
                    Spacer()
                    
                    Button("Import Saved Recipes") {
                        showRecipeImporter = true
                    }
                    .buttonStyle(.bordered)
                    .fileImporter(
                        isPresented: $showRecipeImporter,
                        allowedContentTypes: [.json]
                    ) { result in
                        importRecipeItemsFromJSON(result: result)
                    }
                }
            }
            
            Section(header: Text("Development")) {
                Button(role: .destructive, action: {
                    showDeleteAllFoodsAlert = true
                }) {
                    Text("Delete All Food Items")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.initializeSettingsIfNeeded(settingsList: userSettingsList, context: modelContext)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedCSVURL {
                ActivityViewController(activityItems: [url])
            }
        }
        .alert("Delete All Food Items?", isPresented: $showDeleteAllFoodsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllFoodItems()
            }
        } message: {
            Text("Are you sure you want to delete all saved food items? This action cannot be undone.")
        }
        }
    }
    
    // MARK: - View Helpers
    
    private func timeString(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func exportFoodItemsToCSV() {
        do {
            let descriptor = FetchDescriptor<FoodItem>()
            let allItems = try modelContext.fetch(descriptor)
            
            var timestampCol = Column<Date>(name: "Timestamp", capacity: allItems.count)
            var brandCol = Column<String>(name: "Brand", capacity: allItems.count)
            var nameCol = Column<String>(name: "Name", capacity: allItems.count)
            var processingCol = Column<String>(name: "Processing Level", capacity: allItems.count)
            var sizeCol = Column<Double>(name: "Serving Size", capacity: allItems.count)
            var unitCol = Column<String>(name: "Serving Unit", capacity: allItems.count)
            var caloriesCol = Column<Int>(name: "Calories", capacity: allItems.count)
            var fatCol = Column<Double>(name: "Fat", capacity: allItems.count)
            var satFatCol = Column<Double>(name: "Saturated Fat", capacity: allItems.count)
            var transFatCol = Column<Double>(name: "Trans Fat", capacity: allItems.count)
            var proteinCol = Column<Double>(name: "Protein", capacity: allItems.count)
            var carbCol = Column<Double>(name: "Carbs", capacity: allItems.count)
            var fiberCol = Column<Double>(name: "Dietary Fiber", capacity: allItems.count)
            var sugarCol = Column<Double>(name: "Added Sugar", capacity: allItems.count)
            var categoryCol = Column<String>(name: "Category", capacity: allItems.count)

            for item in allItems {
                timestampCol.append(item.timestamp)
                brandCol.append(item.brandName)
                nameCol.append(item.name)
                processingCol.append(item.processingLevel)
                sizeCol.append(item.servingSize)
                unitCol.append(item.servingUnit)
                caloriesCol.append(item.calories)
                fatCol.append(item.fat)
                satFatCol.append(item.saturatedFat)
                transFatCol.append(item.transFat)
                proteinCol.append(item.protein)
                carbCol.append(item.carb)
                fiberCol.append(item.dietaryFiber)
                sugarCol.append(item.addedSugar)
                categoryCol.append(item.category)
            }
            
            var dataFrame = DataFrame()
            dataFrame.append(column: timestampCol)
            dataFrame.append(column: brandCol)
            dataFrame.append(column: nameCol)
            dataFrame.append(column: processingCol)
            dataFrame.append(column: sizeCol)
            dataFrame.append(column: unitCol)
            dataFrame.append(column: caloriesCol)
            dataFrame.append(column: fatCol)
            dataFrame.append(column: satFatCol)
            dataFrame.append(column: transFatCol)
            dataFrame.append(column: proteinCol)
            dataFrame.append(column: carbCol)
            dataFrame.append(column: fiberCol)
            dataFrame.append(column: sugarCol)
            dataFrame.append(column: categoryCol)
            
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = docURL.appendingPathComponent("NutriApp_FoodItems.csv")
            
            let options = CSVWritingOptions(includesHeader: true, delimiter: ",")
            try dataFrame.writeCSV(to: fileURL, options: options)
            
            self.exportedCSVURL = fileURL
            self.showShareSheet = true
            
            print("Successfully exported \(allItems.count) food items to \(fileURL.path)")
        } catch {
            print("Failed to export food items to CSV: \(error.localizedDescription)")
        }
    }
    
    private func deleteAllFoodItems() {
        do {
            let descriptor = FetchDescriptor<FoodItem>()
            let allItems = try modelContext.fetch(descriptor)
            for item in allItems {
                modelContext.delete(item)
            }
            print("Successfully deleted \(allItems.count) food items.")
        } catch {
            print("Failed to fetch food items for deletion: \(error.localizedDescription)")
        }
    }
    
    private func importFoodItemsFromCSV(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let startAccess = url.startAccessingSecurityScopedResource()
            defer {
                if startAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let options = CSVReadingOptions(hasHeaderRow: true, delimiter: ",")
                let dataFrame = try DataFrame(contentsOfCSVFile: url, options: options)
                
                var importCount = 0
                for row in dataFrame.rows {
                    // Try parsing "Name" as String, or fallback to empty
                    let name = (row["Name"] as? String) ?? ""
                    if name.isEmpty { continue } // Skip if no name
                    
                    func extractDouble(columnName: String, fallback: Double) -> Double {
                        if let dVal = row[columnName] as? Double { return dVal }
                        if let iVal = row[columnName] as? Int { return Double(iVal) }
                        if let strVal = row[columnName] as? String, let parsed = Double(strVal) { return parsed }
                        return fallback
                    }
                    
                    // Parse Calories (could be inferred as Double or Int depending on the row data)
                    let calories: Int
                    if let calInt = row["Calories"] as? Int {
                        calories = calInt
                    } else if let calDouble = row["Calories"] as? Double {
                        calories = Int(calDouble)
                    } else if let strVal = row["Calories"] as? String, let calParsed = Int(strVal) {
                        calories = calParsed
                    } else {
                        calories = 0
                    }
                    
                    // Parse optional types
                    let timestamp = (row["Timestamp"] as? Date) ?? Date()
                    let brand = (row["Brand"] as? String) ?? ""
                    let processing = (row["Processing Level"] as? String) ?? ""
                    let servingSize = extractDouble(columnName: "Serving Size", fallback: 0.0)
                    let servingUnit = (row["Serving Unit"] as? String) ?? ""
                    let fat = extractDouble(columnName: "Fat", fallback: 0.0)
                    let satFat = extractDouble(columnName: "Saturated Fat", fallback: 0.0)
                    let transFat = extractDouble(columnName: "Trans Fat", fallback: 0.0)
                    let protein = extractDouble(columnName: "Protein", fallback: 0.0)
                    let carbs = extractDouble(columnName: "Carbs", fallback: 0.0)
                    let fiber = extractDouble(columnName: "Dietary Fiber", fallback: 0.0)
                    let sugar = extractDouble(columnName: "Added Sugar", fallback: 0.0)
                    let categoryString = (row["Category"] as? String) ?? "Prepared Foods"
                    let newItem = FoodItem(
                        timestamp: timestamp,
                        brandName: brand,
                        name: name,
                        processingLevel: processing,
                        servingSize: servingSize,
                        servingUnit: servingUnit,
                        calories: calories,
                        fat: fat,
                        saturatedFat: satFat,
                        transFat: transFat,
                        protein: protein,
                        carb: carbs,
                        dietaryFiber: fiber,
                        addedSugar: sugar,
                        category: categoryString
                    )
                    
                    modelContext.insert(newItem)
                    importCount += 1
                }
                
                print("Successfully imported \(importCount) food items from \(url.lastPathComponent)")
                
            } catch {
                print("Failed to parse CSV file: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            print("File selection cancelled or failed: \(error.localizedDescription)")
        }
    }
    
    private func exportUserSettingsToCSV() {
        do {
            let descriptor = FetchDescriptor<UserSettings>()
            let allSettings = try modelContext.fetch(descriptor)
            
            var calGoalCol = Column<Int>(name: "Calories Goal", capacity: allSettings.count)
            var calTypeCol = Column<String>(name: "Calories Goal Type", capacity: allSettings.count)
            var fatGoalCol = Column<Int>(name: "Fat Goal", capacity: allSettings.count)
            var fatTypeCol = Column<String>(name: "Fat Goal Type", capacity: allSettings.count)
            var satFatGoalCol = Column<Int>(name: "Saturated Fat Goal", capacity: allSettings.count)
            var satFatTypeCol = Column<String>(name: "Saturated Fat Goal Type", capacity: allSettings.count)
            var transFatGoalCol = Column<Int>(name: "Trans Fat Goal", capacity: allSettings.count)
            var transFatTypeCol = Column<String>(name: "Trans Fat Goal Type", capacity: allSettings.count)
            var proteinGoalCol = Column<Int>(name: "Protein Goal", capacity: allSettings.count)
            var proteinTypeCol = Column<String>(name: "Protein Goal Type", capacity: allSettings.count)
            var carbGoalCol = Column<Int>(name: "Carb Goal", capacity: allSettings.count)
            var carbTypeCol = Column<String>(name: "Carb Goal Type", capacity: allSettings.count)
            var fiberGoalCol = Column<Int>(name: "Dietary Fiber Goal", capacity: allSettings.count)
            var fiberTypeCol = Column<String>(name: "Dietary Fiber Goal Type", capacity: allSettings.count)
            var sugarGoalCol = Column<Int>(name: "Added Sugar Goal", capacity: allSettings.count)
            var sugarTypeCol = Column<String>(name: "Added Sugar Goal Type", capacity: allSettings.count)
            var dayStartHourCol = Column<Int>(name: "Day Start Hour", capacity: allSettings.count)
            var hkWindowCol = Column<Bool>(name: "HealthKit Custom Window", capacity: allSettings.count)
            var colorHexCol = Column<String>(name: "Primary Color Hex", capacity: allSettings.count)

            for setting in allSettings {
                calGoalCol.append(setting.userCaloriesGoal)
                calTypeCol.append(setting.userCaloriesGoalType.rawValue)
                fatGoalCol.append(setting.userFatGoal)
                fatTypeCol.append(setting.userFatGoalType.rawValue)
                satFatGoalCol.append(setting.userSaturatedFatGoal)
                satFatTypeCol.append(setting.userSaturatedFatGoalType.rawValue)
                transFatGoalCol.append(setting.userTransFatGoal)
                transFatTypeCol.append(setting.userTransFatGoalType.rawValue)
                proteinGoalCol.append(setting.userProteinGoal)
                proteinTypeCol.append(setting.userProteinGoalType.rawValue)
                carbGoalCol.append(setting.userCarbGoal)
                carbTypeCol.append(setting.userCarbGoalType.rawValue)
                fiberGoalCol.append(setting.userDietaryFiberGoal)
                fiberTypeCol.append(setting.userDietaryFiberGoalType.rawValue)
                sugarGoalCol.append(setting.userAddedSugarGoal)
                sugarTypeCol.append(setting.userAddedSugarGoalType.rawValue)
                dayStartHourCol.append(setting.dayStartHour)
                hkWindowCol.append(setting.healthKitCustomDayWindow)
                colorHexCol.append(setting.userSelectedPrimaryColorHex)
            }
            
            var dataFrame = DataFrame()
            dataFrame.append(column: calGoalCol)
            dataFrame.append(column: calTypeCol)
            dataFrame.append(column: fatGoalCol)
            dataFrame.append(column: fatTypeCol)
            dataFrame.append(column: satFatGoalCol)
            dataFrame.append(column: satFatTypeCol)
            dataFrame.append(column: transFatGoalCol)
            dataFrame.append(column: transFatTypeCol)
            dataFrame.append(column: proteinGoalCol)
            dataFrame.append(column: proteinTypeCol)
            dataFrame.append(column: carbGoalCol)
            dataFrame.append(column: carbTypeCol)
            dataFrame.append(column: fiberGoalCol)
            dataFrame.append(column: fiberTypeCol)
            dataFrame.append(column: sugarGoalCol)
            dataFrame.append(column: sugarTypeCol)
            dataFrame.append(column: dayStartHourCol)
            dataFrame.append(column: hkWindowCol)
            dataFrame.append(column: colorHexCol)
            
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = docURL.appendingPathComponent("NutriApp_UserSettings.csv")
            
            let options = CSVWritingOptions(includesHeader: true, delimiter: ",")
            try dataFrame.writeCSV(to: fileURL, options: options)
            
            self.exportedCSVURL = fileURL
            self.showShareSheet = true
            
            print("Successfully exported \(allSettings.count) user settings to \(fileURL.path)")
        } catch {
            print("Failed to export user settings to CSV: \(error.localizedDescription)")
        }
    }
    private func importUserSettingsFromCSV(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let startAccess = url.startAccessingSecurityScopedResource()
            defer {
                if startAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let options = CSVReadingOptions(hasHeaderRow: true, delimiter: ",")
                let dataFrame = try DataFrame(contentsOfCSVFile: url, options: options)
                
                let currentSettings: UserSettings
                if let existing = userSettingsList.first {
                    currentSettings = existing
                } else {
                    currentSettings = UserSettings()
                    modelContext.insert(currentSettings)
                }
                
                if let row = dataFrame.rows.first {
                    
                    func extractInt(columnName: String, fallback: Int) -> Int {
                        if let intVal = row[columnName] as? Int {
                            return intVal
                        } else if let doubleVal = row[columnName] as? Double {
                            return Int(doubleVal)
                        } else if let strVal = row[columnName] as? String, let parsed = Int(strVal) {
                            return parsed
                        }
                        return fallback
                    }
                    
                    func extractGoalType(columnName: String, fallback: GoalType) -> GoalType {
                        if let str = row[columnName] as? String, let type = GoalType(rawValue: str) {
                            return type
                        }
                        return fallback
                    }
                    
                    currentSettings.userCaloriesGoal = extractInt(columnName: "Calories Goal", fallback: currentSettings.userCaloriesGoal)
                    currentSettings.userCaloriesGoalType = extractGoalType(columnName: "Calories Goal Type", fallback: currentSettings.userCaloriesGoalType)
                    
                    currentSettings.userFatGoal = extractInt(columnName: "Fat Goal", fallback: currentSettings.userFatGoal)
                    currentSettings.userFatGoalType = extractGoalType(columnName: "Fat Goal Type", fallback: currentSettings.userFatGoalType)
                    
                    currentSettings.userSaturatedFatGoal = extractInt(columnName: "Saturated Fat Goal", fallback: currentSettings.userSaturatedFatGoal)
                    currentSettings.userSaturatedFatGoalType = extractGoalType(columnName: "Saturated Fat Goal Type", fallback: currentSettings.userSaturatedFatGoalType)
                    
                    currentSettings.userTransFatGoal = extractInt(columnName: "Trans Fat Goal", fallback: currentSettings.userTransFatGoal)
                    currentSettings.userTransFatGoalType = extractGoalType(columnName: "Trans Fat Goal Type", fallback: currentSettings.userTransFatGoalType)
                    
                    currentSettings.userProteinGoal = extractInt(columnName: "Protein Goal", fallback: currentSettings.userProteinGoal)
                    currentSettings.userProteinGoalType = extractGoalType(columnName: "Protein Goal Type", fallback: currentSettings.userProteinGoalType)
                    
                    currentSettings.userCarbGoal = extractInt(columnName: "Carb Goal", fallback: currentSettings.userCarbGoal)
                    currentSettings.userCarbGoalType = extractGoalType(columnName: "Carb Goal Type", fallback: currentSettings.userCarbGoalType)
                    
                    currentSettings.userDietaryFiberGoal = extractInt(columnName: "Dietary Fiber Goal", fallback: currentSettings.userDietaryFiberGoal)
                    currentSettings.userDietaryFiberGoalType = extractGoalType(columnName: "Dietary Fiber Goal Type", fallback: currentSettings.userDietaryFiberGoalType)
                    
                    currentSettings.userAddedSugarGoal = extractInt(columnName: "Added Sugar Goal", fallback: currentSettings.userAddedSugarGoal)
                    currentSettings.userAddedSugarGoalType = extractGoalType(columnName: "Added Sugar Goal Type", fallback: currentSettings.userAddedSugarGoalType)
                    
                    currentSettings.dayStartHour = extractInt(columnName: "Day Start Hour", fallback: currentSettings.dayStartHour)
                    
                    if let hkBool = row["HealthKit Custom Window"] as? Bool {
                        currentSettings.healthKitCustomDayWindow = hkBool
                    } else if let hkStr = row["HealthKit Custom Window"] as? String, hkStr.lowercased() == "true" {
                        currentSettings.healthKitCustomDayWindow = true
                    }
                    
                    if let hex = row["Primary Color Hex"] as? String, !hex.isEmpty {
                        currentSettings.userSelectedPrimaryColorHex = hex
                    }
                    
                    viewModel.calorieInput = currentSettings.userCaloriesGoal
                    viewModel.fatInput = currentSettings.userFatGoal
                    viewModel.carbInput = currentSettings.userCarbGoal
                    viewModel.proteinInput = currentSettings.userProteinGoal
                    viewModel.satFatInput = currentSettings.userSaturatedFatGoal
                    viewModel.transFatInput = currentSettings.userTransFatGoal
                    viewModel.fiberInput = currentSettings.userDietaryFiberGoal
                    viewModel.sugarInput = currentSettings.userAddedSugarGoal
                    
                    print("Successfully imported user settings from \(url.lastPathComponent)")
                } else {
                    print("CSV file is empty, no user settings imported.")
                }
                
            } catch {
                print("Failed to parse CSV file: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            print("File selection cancelled or failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recipe JSON Export/Import Logic
    
    private func exportRecipeItemsToJSON() {
        do {
            let descriptor = FetchDescriptor<RecipeItem>()
            let allRecipes = try modelContext.fetch(descriptor)
            
            let dtos = allRecipes.map { $0.toDTO() }
            recipeExportDocument = AppSharingDocument(recipes: dtos)
            showRecipeExporter = true
            
        } catch {
            print("Failed to fetch recipes for export: \(error.localizedDescription)")
        }
    }
    
    private func importRecipeItemsFromJSON(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource.")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                
                // Decode assuming it's our root DTO format
                // In SharingModels.swift we made `AppSharingDocumentDTO` private, so we can't use it directly here.
                // Wait! Let's decode directly if we can, or we can use AppSharingDocument's init(configuration:) via SwiftUI standard way.
                // Actually, the simplest way is to manually decode here since fileImporter just gives us a URL.
                // Let's decode using JSONSerialization to extract the "recipes" array safely, or we can use a local struct.
                struct TempDecode: Codable {
                    var recipes: [RecipeItemDTO]?
                }
                
                let decodedRoot = try decoder.decode(TempDecode.self, from: data)
                
                guard let incomingRecipes = decodedRoot.recipes else {
                    print("No recipes found in the JSON file.")
                    return
                }
                
                // Existing recipes
                let existingDescriptor = FetchDescriptor<RecipeItem>()
                let existingRecipes = try modelContext.fetch(existingDescriptor)
                let existingNames = Set(existingRecipes.map { $0.name.lowercased() })
                
                var importCount = 0
                for dto in incomingRecipes {
                    // Prevent duplicates by name
                    if !existingNames.contains(dto.name.lowercased()) {
                        let newRecipe = RecipeItem(from: dto)
                        modelContext.insert(newRecipe)
                        importCount += 1
                    }
                }
                
                try modelContext.save()
                print("Successfully imported \(importCount) recipes!")
                
            } catch {
                print("Failed to parse JSON file: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            print("File selection cancelled or failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - ActivityViewController
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserSettings.self, configurations: config)
        
        let settings = UserSettings()
        container.mainContext.insert(settings)
        
        return NavigationStack {
            SettingsView()
        }
        .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}
