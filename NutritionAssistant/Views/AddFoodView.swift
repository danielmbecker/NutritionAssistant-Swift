import SwiftData
import SwiftUI

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
    @State private var category: FoodCategory?

    private var isFormValid: Bool {
        !brandName.isEmpty && !name.isEmpty && servingSize != nil && calories != nil
            && category != nil
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
            Section(header: Text("Create New Food Template")) {

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
                        .onChange(of: isBrandNameFocused) { oldValue, isFocused in
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

                Picker("Processing Level", selection: $processingLevel) {
                    ForEach(processingOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)

                // Category chip selector — drives the FoodCategory? binding directly
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FoodCategory.allCases, id: \.self) { foodCategory in
                            Button(action: {
                                withAnimation {
                                    category = foodCategory
                                }
                            }) {
                                Text(foodCategory.rawValue)
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
                    }
                    .padding(.horizontal)
                }

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
                        .onChange(of: fat) { oldValue, newValue in
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
                    addItem()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
            }
        }
    }

    private func addItem() {
        guard let selectedCategory = category else { return }
        withAnimation {
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
                category: selectedCategory
            )

            modelContext.insert(newItem)
            dismiss()
        }
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: [FoodItem.self], inMemory: true)
}
