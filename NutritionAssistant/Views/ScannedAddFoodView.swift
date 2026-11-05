//
//  ScannedAddFoodView.swift
//  NutritionAssistant
//
//  Milestone 6.4: Full-Spectrum ScannedFoodItem Creation, Editing, Multi-Column Batch Save & Copy-on-Edit Versioning
//  Integrates Camera / Photo Library scanning via NutritionScanCoordinator, package metadata entry,
//  the interactive FDADigitalLabelView, multi-column batch saving (Examples E, F, G, H, I),
//  and the 3-option Copy-on-Edit versioning prompt when editing an existing ScannedFoodItem.
//

import AVFoundation
import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ScannedAddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Package Identity & Classification State

    @State private var brandName: String = "Unbranded"
    @State private var isUnbranded: Bool = true
    @FocusState private var isBrandNameFocused: Bool

    @State private var name: String = ""
    @State private var processingLevel: String = "Processed"
    @State private var category: String? = "Prepared Foods"
    @State private var foodVariationGroup: String = ""

    @Query private var customCategories: [UserFoodCategory]
    @State private var showingAddCategoryAlert = false
    @State private var newCategoryName = ""

    // MARK: - Digital FDA Label & Multi-Column State

    @State private var columns: [FDADigitalLabelColumnDraft]
    @State private var topology: FDALabelTopology
    @State private var demographicGroup: FDADemographicGroup
    @State private var isSupplement: Bool
    @State private var activeColumnIndex: Int? = 0

    // MARK: - Scanner & Diagnostics State

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCameraPicker = false
    @State private var isScanningLabel = false
    @State private var scanErrorMessage: String?
    @State private var showingScanErrorAlert = false
    @State private var lastScanEvaluation: NutritionScanEvaluation?

    // MARK: - Copy-on-Edit Versioning Dialog State

    @State private var showingVersioningDialog = false

    let existingItem: ScannedFoodItem?
    private let processingOptions = ["Engineered", "Processed", "Prepared", "Whole"]

    @MainActor
    init(existingItem: ScannedFoodItem? = nil) {
        self.existingItem = existingItem
        if let item = existingItem {
            _brandName = State(initialValue: item.brandName)
            _isUnbranded = State(initialValue: item.brandName == "Unbranded")
            _name = State(initialValue: item.name)
            _processingLevel = State(initialValue: item.processingLevel)
            _category = State(initialValue: item.category)
            _foodVariationGroup = State(initialValue: item.foodVariationGroup ?? "")
            _columns = State(initialValue: [FDADigitalLabelColumnDraft(from: item)])
            _topology = State(initialValue: item.topology)
            _demographicGroup = State(initialValue: item.demographicGroup)
            _isSupplement = State(initialValue: item.isSupplement)
        } else {
            _columns = State(initialValue: [FDADigitalLabelColumnDraft()])
            _topology = State(initialValue: .standardVertical)
            _demographicGroup = State(initialValue: .adultsAndChildren4OrMoreYears)
            _isSupplement = State(initialValue: false)
        }
    }

    // MARK: - Computed Helpers

    private var includedColumns: [FDADigitalLabelColumnDraft] {
        if columns.count <= 1 {
            return columns
        }
        return columns.filter(\.isIncluded)
    }

    private var activeColumn: FDADigitalLabelColumnDraft {
        let idx = min(max(0, activeColumnIndex ?? 0), max(0, columns.count - 1))
        return columns.isEmpty ? FDADigitalLabelColumnDraft() : columns[idx]
    }

    private var isFormValid: Bool {
        let cleanBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBrand.isEmpty, category != nil, !includedColumns.isEmpty else {
            return false
        }
        let cleanBaseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if columns.count >= 2 {
            // In multi-column mode (e.g. Example E Variety Pack), each checked column must resolve to a non-empty name
            return includedColumns.allSatisfy { col in
                !resolvedItemName(for: col, baseName: cleanBaseName).isEmpty && col.servingSize > 0
            }
        }
        return !cleanBaseName.isEmpty && (columns.first?.servingSize ?? 0) > 0
    }

    private func resolvedItemName(for column: FDADigitalLabelColumnDraft, baseName: String) -> String {
        let cleanHeader = column.headerTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if columns.count <= 1 {
            return baseName
        }
        if baseName.isEmpty {
            return cleanHeader
        }
        if cleanHeader.isEmpty || cleanHeader.lowercased() == "per serving" {
            return baseName
        }
        if cleanHeader.lowercased().contains(baseName.lowercased()) {
            return cleanHeader
        }
        return "\(baseName) — \(cleanHeader)"
    }

    // MARK: - View Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scannerSectionCard

                identityAndCategoryCard

                digitalLabelCard

                atwaterAndTelemetryCard

                saveActionSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(existingItem != nil ? "Edit Scanned Food" : "Add Scanned Food")
        .navigationBarTitleDisplayMode(.inline)
        .alert("New Category", isPresented: $showingAddCategoryAlert) {
            TextField("Category Name", text: $newCategoryName)
            Button("Cancel", role: .cancel) { newCategoryName = "" }
            Button("Add") {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let newCat = UserFoodCategory(name: trimmed)
                    modelContext.insert(newCat)
                    category = trimmed
                    newCategoryName = ""
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                await handlePickedPhotoItem(item)
            }
        }
        .sheet(isPresented: $showingCameraPicker) {
            NutritionLabelCameraPicker { capturedImageData in
                Task {
                    await performNutritionScan(with: capturedImageData)
                }
            }
            .ignoresSafeArea()
        }
        .alert("Nutrition Label Scan", isPresented: $showingScanErrorAlert) {
            Button("OK", role: .cancel) {
                scanErrorMessage = nil
            }
        } message: {
            Text(scanErrorMessage ?? "Unable to scan the nutrition label.")
        }
        .confirmationDialog(
            "Save Edited Food Item",
            isPresented: $showingVersioningDialog,
            titleVisibility: .visible
        ) {
            Button("Update Existing Recipes") {
                saveSupersedingVersion(updateExistingRecipes: true)
            }
            Button("Keep Original in Existing Recipes") {
                saveSupersedingVersion(updateExistingRecipes: false)
            }
            Button("Typo Fix (Affects Recipes and Historical Logs)", role: .destructive) {
                saveInPlaceTypoFix()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Creating a new version preserves historical daily logs. Choose whether existing recipes should use this updated nutrition label or keep the original version, or apply a typo fix in-place.")
        }
    }

    // MARK: - 1. Scanner Header Card

    private var scannerSectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("FDA Label Scanner", systemImage: "doc.text.viewfinder")
                    .font(.headline)
                Spacer()
                if let eval = lastScanEvaluation {
                    Text(eval.payload.isSupplement ? "Supplement Label" : "Food Label")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.14))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 12) {
                Button {
                    handleScanWithCameraTapped()
                } label: {
                    Label("Scan with Camera", systemImage: "camera.viewfinder")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanningLabel)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.bordered)
                .disabled(isScanningLabel)
            }

            if isScanningLabel {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Extracting full FDA nutrient spectrum & layout topology...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let eval = lastScanEvaluation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Topology: \(topologyDisplayTitle(for: topology))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    if columns.count >= 2 {
                        Text("• \(columns.count) columns extracted")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    if !eval.payload.healedNutrients.isEmpty {
                        Text("• \(eval.payload.healedNutrients.count) %DV-healed")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 2. Package Identity & Category Card

    private var identityAndCategoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Package Identity")
                .font(.headline)

            HStack {
                Text("Brand Name")
                    .font(.subheadline)

                Button {
                    isUnbranded.toggle()
                    if isUnbranded {
                        brandName = "Unbranded"
                        isBrandNameFocused = false
                    } else if brandName == "Unbranded" {
                        brandName = ""
                    }
                } label: {
                    Text("Unbranded")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isUnbranded ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundStyle(isUnbranded ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Spacer()

                TextField("e.g. General Mills", text: $brandName)
                    .multilineTextAlignment(.trailing)
                    .focused($isBrandNameFocused)
                    .onChange(of: isBrandNameFocused) { _, focused in
                        if focused && brandName == "Unbranded" {
                            brandName = ""
                            isUnbranded = false
                        }
                    }
            }

            Divider()

            HStack {
                Text(columns.count >= 2 ? "Base Package Name" : "Food Name")
                    .font(.subheadline)
                Spacer()
                TextField(
                    columns.count >= 2 ? "Optional prefix (or use column headers)" : "e.g. Honey Nut Oats",
                    text: $name
                )
                .multilineTextAlignment(.trailing)
            }

            Divider()

            HStack {
                Text("Variation Group")
                    .font(.subheadline)
                Spacer()
                TextField("Optional", text: $foodVariationGroup)
                    .multilineTextAlignment(.trailing)
            }

            Picker("Processing Level", selection: $processingLevel) {
                ForEach(processingOptions, id: \.self) { option in
                    Text(option)
                }
            }
            .pickerStyle(.segmented)

            // Category Capsule Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    let allCategories = FoodCategoryList.defaultCategories + customCategories.map(\.name)
                    ForEach(allCategories, id: \.self) { foodCategory in
                        Button {
                            withAnimation {
                                category = foodCategory
                            }
                        } label: {
                            Text(foodCategory)
                                .font(.subheadline.weight(.medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(category == foodCategory ? Color.accentColor : Color.gray.opacity(0.15))
                                .foregroundStyle(category == foodCategory ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showingAddCategoryAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("New Category")
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 3. Interactive Digital FDA Label Card

    private var digitalLabelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Interactive Digital FDA Label")
                    .font(.headline)
                Spacer()
                Text("Tap any weight or serving to edit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FDADigitalLabelView(
                columns: $columns,
                topology: topology,
                demographic: demographicGroup,
                isSupplement: isSupplement,
                activeColumnIndex: $activeColumnIndex
            )
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 4. Atwater Calorie Check & Spectrum Summary Card

    private var atwaterAndTelemetryCard: some View {
        let col = activeColumn
        let expectedRange = col.nutrition.expectedAtwaterCalorieRange(isSupplement: isSupplement)
        let declaredCal = col.nutrition.calories
        let isWithinAtwater = expectedRange.contains(declaredCal)
        let extraCount = col.nutrition.additionalPopulatedNutrientCount

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    columns.count >= 2 ? "Atwater Check (\(col.headerTitle))" : "Atwater Calorie Cross-Check",
                    systemImage: isWithinAtwater ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isWithinAtwater ? .green : .orange)

                Spacer()

                Text("Expected: \(expectedRange.lowerBound)–\(expectedRange.upperBound) kcal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Extended Nutrients Populated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(col.nutrition.entries.count) canonical lines (+\(extraCount) beyond 4 core macros)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 5. Save / Batch Save Section

    private var saveActionSection: some View {
        let cleanBaseName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 10) {
            if columns.count >= 2 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Items Checked for Batch Save (\(includedColumns.count) of \(columns.count)):")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(includedColumns) { col in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                                .font(.caption)
                            Text(resolvedItemName(for: col, baseName: cleanBaseName))
                                .font(.caption.weight(.semibold))
                            Spacer()
                            Text("\(col.formattedServingSummary) • \(col.nutrition.calories) kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                handleSaveTapped()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text(saveButtonTitle)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid)
        }
    }

    private var saveButtonTitle: String {
        if existingItem != nil {
            return "Save Changes"
        }
        if columns.count >= 2 {
            let count = includedColumns.count
            return count == 1 ? "Save 1 Checked Item to Database" : "Batch Save \(count) Checked Items to Database"
        }
        return "Save to Scanned Food Bank"
    }

    // MARK: - Save & Copy-on-Edit Versioning Execution

    @MainActor
    private func handleSaveTapped() {
        guard isFormValid else { return }

        if existingItem != nil {
            showingVersioningDialog = true
        } else {
            performCreateNewItems()
        }
    }

    @MainActor
    private func performCreateNewItems() {
        guard let selectedCategory = category else { return }
        let cleanBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBaseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanVariation = foodVariationGroup.trimmingCharacters(in: .whitespacesAndNewlines)

        let effectiveTopology: FDALabelTopology = (columns.count >= 2 && topology.isMultiColumn)
            ? .standardVertical
            : topology

        for col in includedColumns {
            let finalName = resolvedItemName(for: col, baseName: cleanBaseName)
            let newItem = ScannedFoodItem(
                timestamp: Date(),
                brandName: cleanBrand,
                name: finalName,
                processingLevel: processingLevel,
                category: selectedCategory,
                foodVariationGroup: cleanVariation.isEmpty ? nil : cleanVariation,
                servingSize: col.servingSize,
                servingUnit: col.servingUnit,
                commonHouseholdMeasurement: col.commonHouseholdMeasurement,
                commonHouseholdMeasurementAmount: col.commonHouseholdMeasurementAmount,
                servingsPerContainer: col.servingsPerContainer,
                servingsPerContainerModifier: col.servingsPerContainerModifier,
                perDayMultiplier: col.perDayMultiplier,
                columnHeaderTitle: col.headerTitle,
                isSupplement: isSupplement,
                topology: effectiveTopology,
                demographicGroup: demographicGroup,
                nutrition: col.nutrition
            )
            modelContext.insert(newItem)
        }

        dismiss()
    }

    @MainActor
    private func saveSupersedingVersion(updateExistingRecipes: Bool) {
        guard let existing = existingItem,
              let selectedCategory = category,
              let col = columns.first else {
            return
        }
        let cleanBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanVariation = foodVariationGroup.trimmingCharacters(in: .whitespacesAndNewlines)

        let newVersion = existing.createSupersedingVersion(
            brandName: cleanBrand,
            name: cleanName,
            processingLevel: processingLevel,
            category: selectedCategory,
            foodVariationGroup: cleanVariation.isEmpty ? nil : cleanVariation,
            servingSize: col.servingSize,
            servingUnit: col.servingUnit,
            commonHouseholdMeasurement: col.commonHouseholdMeasurement,
            commonHouseholdMeasurementAmount: col.commonHouseholdMeasurementAmount,
            servingsPerContainer: col.servingsPerContainer,
            servingsPerContainerModifier: col.servingsPerContainerModifier,
            perDayMultiplier: col.perDayMultiplier,
            columnHeaderTitle: col.headerTitle,
            isSupplement: isSupplement,
            topology: topology,
            demographicGroup: demographicGroup,
            nutrition: col.nutrition
        )
        modelContext.insert(newVersion)
        // Note: Stage 2 recipe migration will inspect `updateExistingRecipes` to re-point `RecipeIngredient` references when true.
        _ = updateExistingRecipes
        dismiss()
    }

    @MainActor
    private func saveInPlaceTypoFix() {
        guard let existing = existingItem,
              let selectedCategory = category,
              let col = columns.first else {
            return
        }
        let cleanBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanVariation = foodVariationGroup.trimmingCharacters(in: .whitespacesAndNewlines)

        existing.applyInPlaceUpdate(
            brandName: cleanBrand,
            name: cleanName,
            processingLevel: processingLevel,
            category: selectedCategory,
            foodVariationGroup: cleanVariation.isEmpty ? nil : cleanVariation,
            servingSize: col.servingSize,
            servingUnit: col.servingUnit,
            commonHouseholdMeasurement: col.commonHouseholdMeasurement,
            commonHouseholdMeasurementAmount: col.commonHouseholdMeasurementAmount,
            servingsPerContainer: col.servingsPerContainer,
            servingsPerContainerModifier: col.servingsPerContainerModifier,
            perDayMultiplier: col.perDayMultiplier,
            columnHeaderTitle: col.headerTitle,
            isSupplement: isSupplement,
            topology: topology,
            demographicGroup: demographicGroup,
            nutrition: col.nutrition
        )
        dismiss()
    }

    // MARK: - Camera & Photo Scan Handlers

    @MainActor
    private func handleScanWithCameraTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            scanErrorMessage = "Camera capture is unavailable on this device or simulator. Use Photo Library to scan a nutrition label image."
            showingScanErrorAlert = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCameraPicker = true
        case .notDetermined:
            Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    showingCameraPicker = true
                } else {
                    scanErrorMessage = "Camera access is required to scan labels. You can enable Camera access in Settings > Privacy & Security > Camera."
                    showingScanErrorAlert = true
                }
            }
        case .denied, .restricted:
            scanErrorMessage = "Camera access is disabled for NutritionAssistant. Please enable it in Settings > Privacy & Security > Camera, or use Photo Library."
            showingScanErrorAlert = true
        @unknown default:
            scanErrorMessage = "Unable to verify camera permissions."
            showingScanErrorAlert = true
        }
    }

    @MainActor
    private func handlePickedPhotoItem(_ item: PhotosPickerItem) async {
        defer { selectedPhotoItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), !data.isEmpty else {
                scanErrorMessage = "Could not load image data from the selected photo."
                showingScanErrorAlert = true
                return
            }
            await performNutritionScan(with: data)
        } catch {
            scanErrorMessage = error.localizedDescription
            showingScanErrorAlert = true
        }
    }

    @MainActor
    private func performNutritionScan(with imageData: Data) async {
        isScanningLabel = true
        defer { isScanningLabel = false }

        do {
            let evaluation = try await NutritionScanCoordinator.scanWithDiagnostics(imageData: imageData)
            applyScanEvaluation(evaluation)
        } catch {
            scanErrorMessage = error.localizedDescription
            showingScanErrorAlert = true
        }
    }

    @MainActor
    func applyScanEvaluation(_ evaluation: NutritionScanEvaluation) {
        lastScanEvaluation = evaluation
        topology = evaluation.payload.topology
        isSupplement = evaluation.payload.isSupplement
        demographicGroup = evaluation.payload.demographicGroup
        activeColumnIndex = 0

        if !evaluation.columnCandidates.isEmpty {
            columns = evaluation.columnCandidates.map { FDADigitalLabelColumnDraft(from: $0) }
        } else {
            let singleCandidate = ScannedColumnCandidate(
                columnIndex: 0,
                headerTitle: "Per Serving",
                servingSizeText: nil,
                isIncludedByDefault: true,
                payload: evaluation.payload
            )
            columns = [FDADigitalLabelColumnDraft(from: singleCandidate)]
        }
    }

    private func topologyDisplayTitle(for topology: FDALabelTopology) -> String {
        switch topology {
        case .standardVertical: return "Standard Vertical"
        case .sideBySideMicronutrients: return "Side-by-Side Micronutrients"
        case .tabularHorizontal: return "Horizontal Tabular"
        case .smallPackageTabular: return "Small-Package Horizontal Tabular"
        case .tabularDualColumn: return "Tabular Dual-Column"
        case .dualColumnSameFood: return "Dual-Column (Two Forms)"
        case .dualColumnPerContainer: return "Dual-Column (Per Serving & Container)"
        case .dualColumnPerUnit: return "Dual-Column (Per Serving & Unit)"
        case .aggregateVariety: return "Aggregate Variety Pack"
        case .simplified: return "Simplified Vertical"
        case .linearString: return "Linear Display"
        case .supplementFacts: return "Supplement Facts (§ 101.36)"
        }
    }
}

#Preview {
    NavigationStack {
        ScannedAddFoodView()
    }
    .modelContainer(for: [ScannedFoodItem.self, UserFoodCategory.self, UserMeasurementUnit.self], inMemory: true)
}
