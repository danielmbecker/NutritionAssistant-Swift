import SwiftData
import SwiftUI

/// Form row for `FoodItem.commonHouseholdMeasurement` + `commonHouseholdMeasurementAmount`.
/// Independent of the serving size/unit. Handles the "Add New Unit…" flow, including on-device category suggestion
/// that the user must confirm before anything is saved.
struct HouseholdMeasurementRow: View {
    @Binding var measurement: String?
    @Binding var amount: Double?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserMeasurementUnit.name) private var userUnits: [UserMeasurementUnit]

    @State private var showingNewUnitAlert = false
    @State private var newUnitName = ""
    @State private var pendingUnitName = ""
    @State private var suggestedCategory: MeasurementCategory?
    @State private var showingCategoryDialog = false
    @State private var isSuggesting = false

    private let suggester = CompositeCategorySuggester()

    private var isPairValid: Bool {
        FoodItem.isValidHouseholdPair(name: measurement, amount: amount)
    }

    private var menuLabel: String {
        guard let measurement else { return "None" }
        return MeasurementUnitFormatter.display(name: measurement, quantity: amount ?? 1, userUnits: userUnits)
    }

    /// Suggested category first, then the rest in declaration order.
    private var orderedCategories: [MeasurementCategory] {
        guard let suggestedCategory else { return MeasurementCategory.allCases }
        return [suggestedCategory] + MeasurementCategory.allCases.filter { $0 != suggestedCategory }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Household Measure")
                Spacer()

                TextField("0", value: $amount, format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .keyboardType(.decimalPad)

                if isSuggesting {
                    ProgressView()
                }

                unitMenu
            }

            Text(isPairValid
                 ? "How much of this measure equals one serving (e.g. 2 tbsp)."
                 : "Enter both an amount greater than 0 and a measure, or clear both.")
                .font(.caption)
                .foregroundStyle(isPairValid ? Color.secondary : Color.red)
        }
        .alert("New Measure", isPresented: $showingNewUnitAlert) {
            TextField("Singular name, e.g. stick", text: $newUnitName)
                .textInputAutocapitalization(.never)
            Button("Cancel", role: .cancel) { newUnitName = "" }
            Button("Add") { beginAddingUnit() }
        } message: {
            Text("Use the singular form. Plurals are handled automatically.")
        }
        .confirmationDialog(
            "Category for \u{201C}\(pendingUnitName)\u{201D}",
            isPresented: $showingCategoryDialog,
            titleVisibility: .visible
        ) {
            ForEach(orderedCategories) { category in
                Button(category == suggestedCategory ? "\(category.displayName) (Suggested)" : category.displayName) {
                    saveNewUnit(in: category)
                }
            }
            Button("Cancel", role: .cancel) { pendingUnitName = "" }
        } message: {
            Text(suggestedCategory == nil ? "Choose the category that fits best." : "Confirm the suggested category or choose another.")
        }
    }

    private var unitMenu: some View {
        Menu {
            Button {
                measurement = nil
            } label: {
                if measurement == nil { Label("None", systemImage: "checkmark") } else { Text("None") }
            }

            ForEach(MeasurementUnitCatalog.grouped(userUnits: userUnits), id: \.category) { group in
                Section(group.category.displayName) {
                    ForEach(group.units) { unit in
                        Button {
                            measurement = unit.name
                        } label: {
                            if measurement?.lowercased() == unit.name.lowercased() {
                                Label(unit.name, systemImage: "checkmark")
                            } else {
                                Text(unit.name)
                            }
                        }
                    }
                }
            }

            Divider()
            Button {
                showingNewUnitAlert = true
            } label: {
                Label("Add New Measure…", systemImage: "plus")
            }
        } label: {
            Text(menuLabel).lineLimit(1)
        }
    }

    // MARK: - Add new unit flow

    private func beginAddingUnit() {
        let trimmed = newUnitName.trimmingCharacters(in: .whitespacesAndNewlines)
        newUnitName = ""
        guard !trimmed.isEmpty else { return }

        // Already known (built-in, user-added, or a plural form of one): just select it.
        if let existing = MeasurementUnitCatalog.definition(for: trimmed, userUnits: userUnits) {
            measurement = existing.name
            return
        }

        pendingUnitName = trimmed
        suggestedCategory = nil
        isSuggesting = true
        Task {
            let suggestion = await suggester.suggest(for: trimmed)
            suggestedCategory = suggestion
            isSuggesting = false
            // Let the alert finish dismissing before presenting the dialog.
            try? await Task.sleep(for: .milliseconds(300))
            showingCategoryDialog = true
        }
    }

    private func saveNewUnit(in category: MeasurementCategory) {
        let name = pendingUnitName
        guard !name.isEmpty else { return }
        modelContext.insert(UserMeasurementUnit(name: name, category: category))
        measurement = name
        pendingUnitName = ""
    }
}
