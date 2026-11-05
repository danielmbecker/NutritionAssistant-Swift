import AVFoundation
import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var brandName: String = "Unbranded"
    @State private var isUnbranded: Bool = true
    @FocusState private var isBrandNameFocused: Bool

    @State private var name: String = ""
    @State private var processingLevel: String = "Whole"
    @State private var servingSize: Double?
    @State private var servingUnit: String = "g"
    @State private var calories: Int?

    @State private var fat: Double?
    @State private var saturatedFat: Double?
    @State private var transFat: Double?
    @State private var protein: Double?
    @State private var carb: Double?
    @State private var dietaryFiber: Double?
    @State private var addedSugar: Double?
    @State private var category: String?
    @Query private var customCategories: [UserFoodCategory]
    @State private var showingAddCategoryAlert = false
    @State private var newCategoryName = ""
    @State private var foodVariationGroup: String = ""
    @State private var householdMeasurement: String?
    @State private var householdAmount: Double?
    @State private var isSupplement: Bool? = nil
    @State private var pendingAdjustment: HouseholdMeasurementAdjustment?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCameraPicker = false
    @State private var isScanningLabel = false
    @State private var scanErrorMessage: String?
    @State private var showingScanErrorAlert = false
    @State private var lastScannedPayload: ScannedNutritionPayload?
    @State private var lastScanDiagnostics: ScanDiagnosticsSnapshot?

    var existingFood: FoodItem?

    init(existingFood: FoodItem? = nil) {
        self.existingFood = existingFood
        if let food = existingFood {
            _brandName = State(initialValue: food.brandName)
            _isUnbranded = State(initialValue: food.brandName == "Unbranded")
            _name = State(initialValue: food.name)
            _processingLevel = State(initialValue: food.processingLevel)
            _servingSize = State(initialValue: food.servingSize)
            _servingUnit = State(initialValue: food.servingUnit)
            _calories = State(initialValue: food.calories)
            _fat = State(initialValue: food.fat)
            _saturatedFat = State(initialValue: food.saturatedFat)
            _transFat = State(initialValue: food.transFat)
            _protein = State(initialValue: food.protein)
            _carb = State(initialValue: food.carb)
            _dietaryFiber = State(initialValue: food.dietaryFiber)
            _addedSugar = State(initialValue: food.addedSugar)
            _category = State(initialValue: food.category)
            _foodVariationGroup = State(initialValue: food.foodVariationGroup ?? "")
            _householdMeasurement = State(initialValue: food.commonHouseholdMeasurement)
            _householdAmount = State(initialValue: food.commonHouseholdMeasurementAmount)
            _isSupplement = State(initialValue: food.isSupplement)
        }
    }

    private var isFormValid: Bool {
        !brandName.isEmpty && !name.isEmpty && servingSize != nil && calories != nil
            && category != nil
            && FoodItem.isValidHouseholdPair(name: householdMeasurement, amount: householdAmount)
    }

    private var calculatedCalories: String {
        let currentFat = fat ?? 0.0
        let currentProtein = protein ?? 0.0
        let currentCarb = carb ?? 0.0
        let currentFiber = dietaryFiber ?? 0.0

        let fatCalories = currentFat * 9.0
        let proteinCalories = currentProtein * 4.0

        let netCarbs = max(0.0, currentCarb - currentFiber)
        let netCarbCalories = netCarbs * 4.0

        let baseCalories = fatCalories + proteinCalories + netCarbCalories

        let minCalories = Int(round(baseCalories))
        let maxCalories = Int(round(baseCalories + (currentFiber * 4.0)))

        if minCalories == maxCalories {
            return "\(minCalories)"
        } else {
            return "\(minCalories) - \(maxCalories)"
        }
    }

    // MARK: - func calculatedCaloriesColor

    private var calculatedCaloriesColor: Color {
        // Returns gray if all primary macros are entirely empty
        if fat == nil && protein == nil && carb == nil {
            return .gray
        }

        guard let inputKcal = calories else { return .red }

        let currentFat = fat ?? 0.0
        let currentProtein = protein ?? 0.0
        let currentCarb = carb ?? 0.0
        let currentFiber = dietaryFiber ?? 0.0

        let netCarbs = max(0.0, currentCarb - currentFiber)
        let baseCalories = (currentFat * 9.0) + (currentProtein * 4.0) + (netCarbs * 4.0)

        let minCalculated = baseCalories
        let maxCalculated = baseCalories + (currentFiber * 4.0)

        let lowerBound = Double(inputKcal) * 0.90
        let upperBound = Double(inputKcal) * 1.10

        if maxCalculated >= lowerBound && minCalculated <= upperBound {
            return .green
        } else {
            return .red
        }
    }

    let unitOptions = ["g", "oz", "ml", "unit"]
    let processingOptions = ["Engineered", "Processed", "Prepared", "Whole"]

    // MARK: - View Body
    var body: some View {
        List {
            Section(header: Text(existingFood != nil ? "Edit Food Template" : "Create New Food Template")) {
                scannerHeaderRow
                brandAndIdentityRows
                categorySelectorRow
                servingAndMacroRows
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .overlay {
            if let adjustment = pendingAdjustment {
                HouseholdAdjustmentPromptView(
                    adjustment: adjustment,
                    onUpdate: {
                        pendingAdjustment = nil
                        addItem(householdAmountOverride: adjustment.newAmount)
                    },
                    onKeep: {
                        pendingAdjustment = nil
                        addItem()
                    },
                    onDismiss: {
                        withAnimation { pendingAdjustment = nil }
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.15), value: pendingAdjustment?.id)
        .alert("New Category", isPresented: $showingAddCategoryAlert) {
            TextField("Category Name", text: $newCategoryName)
            Button("Cancel", role: .cancel) { newCategoryName = "" }
            Button("Add") {
                if !newCategoryName.isEmpty {
                    let newCat = UserFoodCategory(name: newCategoryName)
                    modelContext.insert(newCat)
                    category = newCategoryName
                    newCategoryName = ""
                }
            }
            .disabled(newCategoryName.isEmpty)
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
    }

    // MARK: - Form Subviews

    @ViewBuilder
    private var scannerHeaderRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    handleScanWithCameraTapped()
                } label: {
                    Label("Scan with Camera", systemImage: "camera.viewfinder")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanningLabel)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .disabled(isScanningLabel)
            }

            if isScanningLabel {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning FDA label with Vision...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let isSupp = isSupplement {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text(isSupp ? "Scanned: Supplement Facts (§ 101.36)" : "Scanned: Nutrition Facts (§ 101.9)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    if let payload = lastScannedPayload, !payload.healedNutrients.isEmpty {
                        Text("• \(payload.healedNutrients.count) %DV-healed")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var brandAndIdentityRows: some View {
        HStack {
            Text("Brand Name")

            Button(action: {
                isUnbranded.toggle()
                if isUnbranded {
                    brandName = "Unbranded"
                    isBrandNameFocused = false
                } else if brandName == "Unbranded" {
                    brandName = ""
                }
            }) {
                Text("Unbranded")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isUnbranded ? Color.accentColor : Color.gray.opacity(0.2))
                    .foregroundColor(isUnbranded ? .white : .primary)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Spacer()

            TextField("e.g. Chiquita", text: $brandName)
                .multilineTextAlignment(.trailing)
                .focused($isBrandNameFocused)
                .onChange(of: isBrandNameFocused) { _, isFocused in
                    if isFocused && brandName == "Unbranded" {
                        brandName = ""
                        isUnbranded = false
                    }
                }
        }

        HStack {
            Text("Food Name")
            Spacer()
            TextField("e.g. Banana", text: $name)
                .multilineTextAlignment(.trailing)
        }

        HStack {
            Text("Variation Group")
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
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var categorySelectorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                let allCategories = FoodCategoryList.defaultCategories + customCategories.map { $0.name }

                ForEach(allCategories, id: \.self) { foodCategory in
                    Button(action: {
                        withAnimation {
                            category = foodCategory
                        }
                    }) {
                        Text(foodCategory)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .fontWeight(.medium)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                category == foodCategory ? Color.accentColor : Color.gray.opacity(0.15)
                            )
                            .foregroundColor(category == foodCategory ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }

                Button(action: {
                    showingAddCategoryAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Category")
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .fontWeight(.medium)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var servingAndMacroRows: some View {
        HStack {
            Text("Serving Size")
            Spacer()

            Picker("", selection: $servingUnit) {
                ForEach(unitOptions, id: \.self) { unit in
                    Text(unit)
                }
            }
            .pickerStyle(.menu)

            TextField("0", value: $servingSize, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .keyboardType(.decimalPad)
        }

        HouseholdMeasurementRow(measurement: $householdMeasurement, amount: $householdAmount)

        HStack {
            Text("Calories")
            Spacer()
            TextField("0", value: $calories, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
        }

        HStack {
            Text("Calculated Calories")
                .foregroundColor(.secondary)
            Spacer()
            Text(calculatedCalories)
                .foregroundColor(calculatedCaloriesColor)
                .fontWeight(.semibold)
        }
        .padding(.bottom, 4)

        HStack {
            Text("Fat (g)")
            Spacer()
            TextField("0", value: $fat, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .onChange(of: fat) { _, newValue in
                    if newValue == 0.0 {
                        saturatedFat = 0.0
                        transFat = 0.0
                    }
                }
        }

        HStack {
            Text("Saturated Fat (g)")
                .padding(.leading, 20)
                .foregroundColor(saturatedFat == nil ? .gray : .primary)
            Spacer()
            TextField("0", value: $saturatedFat, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }

        HStack {
            Text("Trans Fat (g)")
                .padding(.leading, 20)
                .foregroundColor(transFat == nil ? .gray : .primary)
            Spacer()
            TextField("0", value: $transFat, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }

        HStack {
            Text("Carbs (g)")
            Spacer()
            TextField("0", value: $carb, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }

        HStack {
            Text("Dietary Fiber (g)")
                .padding(.leading, 20)
                .foregroundColor(dietaryFiber == nil ? .gray : .primary)
            Spacer()
            TextField("0", value: $dietaryFiber, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }

        HStack {
            Text("Added Sugar (g)")
                .padding(.leading, 20)
                .foregroundColor(addedSugar == nil ? .gray : .primary)
            Spacer()
            TextField("0", value: $addedSugar, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }

        HStack {
            Text("Protein (g)")
            Spacer()
            TextField("0", value: $protein, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }

        Button("Save to Database") {
            attemptSave()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isFormValid)
    }

    /// Edit mode only: if the serving size changed on a food with a household measure, propose a proportional
    /// household update first. Otherwise save immediately.
    private func attemptSave() {
        if let existing = existingFood,
           let adjustment = HouseholdMeasurementAdjuster.adjustment(
               originalSize: existing.servingSize,
               originalUnit: existing.servingUnit,
               originalMeasurement: existing.commonHouseholdMeasurement,
               originalAmount: existing.commonHouseholdMeasurementAmount,
               currentSize: servingSize,
               currentUnit: servingUnit,
               currentMeasurement: householdMeasurement,
               currentAmount: householdAmount
           ) {
            withAnimation { pendingAdjustment = adjustment }
        } else {
            addItem()
        }
    }

    private func addItem(householdAmountOverride: Double? = nil) {
        let amountToSave = householdAmountOverride ?? householdAmount
        guard let selectedCategory = category else { return }
        withAnimation {
            if let existing = existingFood {
                existing.brandName = brandName
                existing.name = name
                existing.processingLevel = processingLevel
                existing.servingSize = servingSize ?? 1.0
                existing.servingUnit = servingUnit
                existing.calories = calories ?? 0
                existing.fat = fat ?? 0.0
                existing.saturatedFat = saturatedFat ?? 0.0
                existing.transFat = transFat ?? 0.0
                existing.protein = protein ?? 0.0
                existing.carb = carb ?? 0.0
                existing.dietaryFiber = dietaryFiber ?? 0.0
                existing.addedSugar = addedSugar ?? 0.0
                existing.category = selectedCategory
                existing.foodVariationGroup = foodVariationGroup.isEmpty ? nil : foodVariationGroup
                existing.commonHouseholdMeasurement = householdMeasurement
                existing.commonHouseholdMeasurementAmount = amountToSave
                existing.isSupplement = isSupplement
            } else {
                let newItem = FoodItem(
                    timestamp: Date(),
                    brandName: brandName,
                    name: name,
                    processingLevel: processingLevel,
                    servingSize: servingSize ?? 1.0,
                    servingUnit: servingUnit,
                    calories: calories ?? 0,
                    fat: fat ?? 0.0,
                    saturatedFat: saturatedFat ?? 0.0,
                    transFat: transFat ?? 0.0,
                    protein: protein ?? 0.0,
                    carb: carb ?? 0.0,
                    dietaryFiber: dietaryFiber ?? 0.0,
                    addedSugar: addedSugar ?? 0.0,
                    category: selectedCategory,
                    foodVariationGroup: foodVariationGroup.isEmpty ? nil : foodVariationGroup,
                    commonHouseholdMeasurement: householdMeasurement,
                    commonHouseholdMeasurementAmount: amountToSave,
                    isSupplement: isSupplement
                )
                modelContext.insert(newItem)
            }
            dismiss()
        }
    }

    /// Auto-populates nutrition and serving fields from a validated FDA scan payload while leaving manual metadata untouched.
    func applyScannedPayload(_ payload: ScannedNutritionPayload) {
        isSupplement = payload.isSupplement
        servingSize = payload.servingSize > 0 ? payload.servingSize : 1.0

        let normalizedUnit = FDALexicalNormalizer.normalizeServingMetricUnit(payload.servingUnit)
            ?? payload.servingUnit.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        if normalizedUnit == "ml" {
            servingUnit = "ml"
        } else if normalizedUnit == "g" {
            servingUnit = "g"
        } else if unitOptions.contains(normalizedUnit) {
            servingUnit = normalizedUnit
        } else {
            servingUnit = "g"
        }

        if FoodItem.isValidHouseholdPair(
            name: payload.commonHouseholdMeasurement,
            amount: payload.commonHouseholdMeasurementAmount
        ) {
            householdMeasurement = payload.commonHouseholdMeasurement
            householdAmount = payload.commonHouseholdMeasurementAmount
        } else {
            householdMeasurement = nil
            householdAmount = nil
        }

        // Populate explicit numeric 0 / 0.0 values so TextFields render "0" instead of "" and satisfy Save validation.
        calories = max(0, payload.calories)
        fat = max(0.0, payload.fat)
        saturatedFat = max(0.0, payload.saturatedFat)
        transFat = max(0.0, payload.transFat)
        carb = max(0.0, payload.carb)
        dietaryFiber = max(0.0, payload.dietaryFiber)
        addedSugar = max(0.0, payload.addedSugar)
        protein = max(0.0, payload.protein)
        lastScannedPayload = payload
    }

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
            lastScanDiagnostics = evaluation.diagnostics
            applyScannedPayload(evaluation.payload)
        } catch {
            scanErrorMessage = error.localizedDescription
            showingScanErrorAlert = true
        }
    }
}

// MARK: - Camera Image Picker Wrapper

struct NutritionLabelCameraPicker: UIViewControllerRepresentable {
    var captureLosslessPNG: Bool = false
    var onImageDataCaptured: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// Normalizes a `UIImage` into an upright `.up` orientation bitmap and encodes it as 100% lossless PNG `Data`
    /// so initial test runs and all subsequent re-runs execute on identical uncompressed pixel buffers.
    static func losslessNormalizedPNGData(from image: UIImage) -> Data? {
        let uprightImage: UIImage
        if image.imageOrientation == .up {
            uprightImage = image
        } else {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            let pixelSize = CGSize(
                width: image.size.width * image.scale,
                height: image.size.height * image.scale
            )
            let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
            uprightImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: pixelSize))
            }
        }
        return uprightImage.pngData() ?? image.pngData()
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: NutritionLabelCameraPicker

        init(parent: NutritionLabelCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                if parent.captureLosslessPNG,
                   let pngData = NutritionLabelCameraPicker.losslessNormalizedPNGData(from: image) {
                    parent.onImageDataCaptured(pngData)
                } else if let jpegData = image.jpegData(compressionQuality: 0.95) {
                    parent.onImageDataCaptured(jpegData)
                }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: [FoodItem.self, UserFoodCategory.self, UserMeasurementUnit.self], inMemory: true)
}
