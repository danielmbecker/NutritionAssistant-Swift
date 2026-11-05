//
//  FDADigitalLabelView.swift
//  NutritionAssistant
//
//  Milestone 6.3: Dynamic Digital FDA Label Replica
//  Renders an interactive, authentic FDA Nutrition Facts (§ 101.9) or Supplement Facts (§ 101.36)
//  digital label that automatically matches the scanned topology:
//  - Vertical Standard / Voluntary / Simplified (Topologies B, C, J, & Example M)
//  - Vertical with Side-by-Side Micronutrients (Topology D)
//  - Supplement Facts 2-Tier (21 CFR § 101.36)
//  - Horizontal Tabular Overflow (Topologies A & K via ScrollView(.horizontal))
//  - Unified Multi-Column Matrix (Topologies E, F, G, H, I with ✓ Include checkboxes,
//    editable column titles, and Active Column Highlighting)
//  - Linear Display (Topology L)
//

import SwiftUI

// MARK: - 1. Per-Column Editable Draft Model

/// Editable state for a single product/serving column inside `FDADigitalLabelView` and `ScannedAddFoodView`.
struct FDADigitalLabelColumnDraft: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: UUID
    var columnIndex: Int
    var headerTitle: String
    var isIncluded: Bool
    var servingSize: Double
    var servingUnit: String
    var commonHouseholdMeasurementAmount: Double?
    var commonHouseholdMeasurement: String?
    var servingsPerContainer: Double?
    var servingsPerContainerModifier: String?
    var perDayMultiplier: Int?
    var nutrition: NutritionProfile

    init(
        id: UUID = UUID(),
        columnIndex: Int = 0,
        headerTitle: String = "Per Serving",
        isIncluded: Bool = true,
        servingSize: Double = 100.0,
        servingUnit: String = "g",
        commonHouseholdMeasurementAmount: Double? = nil,
        commonHouseholdMeasurement: String? = nil,
        servingsPerContainer: Double? = nil,
        servingsPerContainerModifier: String? = nil,
        perDayMultiplier: Int? = nil,
        nutrition: NutritionProfile = NutritionProfile()
    ) {
        self.id = id
        self.columnIndex = columnIndex
        self.headerTitle = headerTitle
        self.isIncluded = isIncluded
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.commonHouseholdMeasurementAmount = commonHouseholdMeasurementAmount
        self.commonHouseholdMeasurement = commonHouseholdMeasurement
        self.servingsPerContainer = servingsPerContainer
        self.servingsPerContainerModifier = servingsPerContainerModifier
        self.perDayMultiplier = perDayMultiplier
        self.nutrition = nutrition
    }

    init(
        from payload: ScannedNutritionPayload,
        id: UUID = UUID(),
        columnIndex: Int = 0,
        headerTitle: String = "Per Serving",
        isIncluded: Bool = true
    ) {
        self.id = id
        self.columnIndex = columnIndex
        self.headerTitle = headerTitle
        self.isIncluded = isIncluded
        self.servingSize = payload.servingSize
        self.servingUnit = payload.servingUnit
        self.commonHouseholdMeasurementAmount = payload.commonHouseholdMeasurementAmount
        self.commonHouseholdMeasurement = payload.commonHouseholdMeasurement
        self.servingsPerContainer = payload.servingsPerContainer
        self.servingsPerContainerModifier = payload.servingsPerContainerModifier
        self.perDayMultiplier = payload.perDayMultiplier
        self.nutrition = NutritionProfile(from: payload)
    }

    init(from candidate: ScannedColumnCandidate) {
        let p = candidate.payload
        self.id = candidate.id
        self.columnIndex = candidate.columnIndex
        self.headerTitle = candidate.headerTitle
        self.isIncluded = candidate.isIncludedByDefault
        self.servingSize = p.servingSize
        self.servingUnit = p.servingUnit
        self.commonHouseholdMeasurementAmount = p.commonHouseholdMeasurementAmount
        self.commonHouseholdMeasurement = p.commonHouseholdMeasurement
        self.servingsPerContainer = p.servingsPerContainer
        self.servingsPerContainerModifier = p.servingsPerContainerModifier
        self.perDayMultiplier = p.perDayMultiplier
        self.nutrition = NutritionProfile(from: p)
    }

    @MainActor
    init(from item: ScannedFoodItem) {
        self.id = item.id
        self.columnIndex = 0
        self.headerTitle = item.columnHeaderTitle ?? "Per Serving"
        self.isIncluded = true
        self.servingSize = item.servingSize
        self.servingUnit = item.servingUnit
        self.commonHouseholdMeasurementAmount = item.commonHouseholdMeasurementAmount
        self.commonHouseholdMeasurement = item.commonHouseholdMeasurement
        self.servingsPerContainer = item.servingsPerContainer
        self.servingsPerContainerModifier = item.servingsPerContainerModifier
        self.perDayMultiplier = item.perDayMultiplier
        self.nutrition = item.nutrition
    }

    var formattedServingSummary: String {
        let metricStr = "\(FDADigitalLabelFormatting.formatDecimal(servingSize))\(servingUnit)"
        if let hhAmt = commonHouseholdMeasurementAmount,
           let hhUnit = commonHouseholdMeasurement,
           !hhUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(FDADigitalLabelFormatting.formatDecimal(hhAmt)) \(hhUnit) (\(metricStr))"
        }
        return metricStr
    }

    var formattedServingsPerContainerLine: String {
        guard let count = servingsPerContainer, count > 0 else {
            return "Servings per container: —"
        }
        let numStr = FDADigitalLabelFormatting.formatDecimal(count)
        let modPrefix: String
        if let mod = servingsPerContainerModifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !mod.isEmpty {
            modPrefix = "\(mod.capitalized) "
        } else {
            modPrefix = ""
        }
        let noun = (abs(count - 1.0) < 0.001) ? "serving" : "servings"
        return "\(modPrefix)\(numStr) \(noun) per container"
    }
}

enum FDADigitalLabelFormatting {
    static func formatDecimal(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.001 {
            return "\(Int(value.rounded()))"
        }
        let oneDec = (value * 10.0).rounded() / 10.0
        if abs(oneDec - value) < 0.01 {
            return String(format: "%.1f", oneDec)
        }
        return String(format: "%.2f", value)
    }

    static let canonicalFDASequence: [CanonicalNutrientID] = {
        var seen = Set<CanonicalNutrientID>()
        var list: [CanonicalNutrientID] = []
        let allOrdered = [.calories, .caloriesFromSaturatedFat, .caloriesFromFat]
            + NutritionProfile.orderedUpperMacroSequence
            + NutritionProfile.orderedConventionalMicronutrientSequence
            + CanonicalNutrientID.allCases
        for id in allOrdered where seen.insert(id).inserted {
            list.append(id)
        }
        return list
    }()

    static func sortIndex(for nutrient: CanonicalNutrientID) -> Int {
        canonicalFDASequence.firstIndex(of: nutrient) ?? 999
    }
}

// MARK: - 2. Dynamic FDA Digital Label View

struct FDADigitalLabelView: View {
    @Binding var columns: [FDADigitalLabelColumnDraft]
    var topology: FDALabelTopology
    var demographic: FDADemographicGroup = .adultsAndChildren4OrMoreYears
    var isSupplement: Bool = false
    @Binding var activeColumnIndex: Int?

    @State private var editingNutrientContext: NutrientEditContext?
    @State private var editingServingColumnIndex: Int?
    @State private var editingColumnTitleIndex: Int?
    @State private var showingAddNutrientSheet = false

    private struct NutrientEditContext: Identifiable {
        let id = UUID()
        let columnIndex: Int
        let nutrient: CanonicalNutrientID
        let tier2EntryID: UUID?
    }

    private var primaryColumn: FDADigitalLabelColumnDraft {
        columns.first ?? FDADigitalLabelColumnDraft()
    }

    private var isMultiColumnMatrix: Bool {
        columns.count >= 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            labelLayoutContent

            addNutrientBar
        }
        .sheet(item: $editingNutrientContext) { context in
            if context.columnIndex < columns.count {
                FDANutrientInlineEditorSheet(
                    column: $columns[context.columnIndex],
                    nutrient: context.nutrient,
                    tier2EntryID: context.tier2EntryID,
                    demographic: demographic,
                    isSupplement: isSupplement || topology == .supplementFacts,
                    isMultiColumn: columns.count >= 2,
                    onDismiss: {
                        editingNutrientContext = nil
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(
            isPresented: Binding(
                get: { editingServingColumnIndex != nil },
                set: { if !$0 { editingServingColumnIndex = nil } }
            )
        ) {
            if let colIdx = editingServingColumnIndex, colIdx < columns.count {
                FDAServingSizeEditorSheet(
                    column: $columns[colIdx],
                    isMultiColumn: columns.count >= 2
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(
            isPresented: Binding(
                get: { editingColumnTitleIndex != nil },
                set: { if !$0 { editingColumnTitleIndex = nil } }
            )
        ) {
            if let colIdx = editingColumnTitleIndex, colIdx < columns.count {
                FDAColumnTitleEditorSheet(column: $columns[colIdx])
                    .presentationDetents([.height(240)])
            }
        }
        .sheet(isPresented: $showingAddNutrientSheet) {
            FDAAddNutrientPickerSheet(
                columns: $columns,
                isSupplement: isSupplement || topology == .supplementFacts,
                demographic: demographic,
                onAddedNutrient: { addedNutrient, tier2ID in
                    let targetCol = min(activeColumnIndex ?? 0, max(0, columns.count - 1))
                    activeColumnIndex = targetCol
                    editingNutrientContext = NutrientEditContext(
                        columnIndex: targetCol,
                        nutrient: addedNutrient,
                        tier2EntryID: tier2ID
                    )
                }
            )
        }
    }

    // MARK: - Topology Dispatcher

    @ViewBuilder
    private var labelLayoutContent: some View {
        if isMultiColumnMatrix {
            multiColumnMatrixLabel
        } else if isSupplement || topology == .supplementFacts {
            supplementFactsLabel
        } else if topology == .tabularHorizontal || topology == .smallPackageTabular {
            horizontalTabularOverflowLabel
        } else if topology == .linearString {
            linearDisplayLabel
        } else if topology == .sideBySideMicronutrients {
            verticalStandardOrSideBySideLabel(useSideBySideMicros: true)
        } else {
            verticalStandardOrSideBySideLabel(useSideBySideMicros: false)
        }
    }

    // MARK: - Renderer 1 & 2: Vertical Standard (B, C, J, M) & Side-by-Side Micronutrients (D)

    private func verticalStandardOrSideBySideLabel(useSideBySideMicros: Bool) -> some View {
        let col = primaryColumn
        let upperRows = orderedVerticalUpperMacros(for: col.nutrition)
        let microRows = orderedVerticalMicronutrients(for: col.nutrition)

        return VStack(alignment: .leading, spacing: 0) {
            Text("Nutrition Facts")
                .font(.system(size: 28, weight: .black))
                .tracking(-0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)

            thinRule

            Button {
                activeColumnIndex = 0
                editingServingColumnIndex = 0
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(col.formattedServingsPerContainerLine)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.primary)

                    HStack(alignment: .firstTextBaseline) {
                        Text("Serving size")
                            .font(.system(size: 15, weight: .heavy))
                        Spacer()
                        HStack(spacing: 4) {
                            Text(col.formattedServingSummary)
                                .font(.system(size: 15, weight: .heavy))
                            Image(systemName: "pencil.line")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            thickRule(height: 8)

            Button {
                openNutrientEditor(columnIndex: 0, nutrient: .calories)
            } label: {
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Amount per serving")
                            .font(.system(size: 11, weight: .bold))
                        Text("Calories")
                            .font(.system(size: 22, weight: .black))
                    }
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(col.nutrition.calories)")
                            .font(.system(size: 32, weight: .black))
                        Image(systemName: "pencil.line")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            thickRule(height: 4)

            HStack {
                Spacer()
                Text("% Daily Value*")
                    .font(.system(size: 12, weight: .heavy))
            }
            .padding(.vertical, 3)

            ForEach(upperRows, id: \.nutrient) { entry in
                thinRule
                verticalSingleNutrientRow(entry: entry, columnIndex: 0)
            }

            if !microRows.isEmpty {
                thickRule(height: 8)

                if useSideBySideMicros {
                    sideBySideMicronutrientGrid(entries: microRows, columnIndex: 0)
                } else {
                    ForEach(Array(microRows.enumerated()), id: \.element.nutrient) { idx, entry in
                        if idx > 0 {
                            thinRule
                        }
                        verticalSingleNutrientRow(entry: entry, columnIndex: 0)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .stroke(Color.primary, lineWidth: 2)
        )
    }

    private func verticalSingleNutrientRow(
        entry: ScannedNutrientEntry,
        columnIndex: Int,
        compact: Bool = false
    ) -> some View {
        let indentLevel = entry.nutrient.indentationLevel
        let indentPoints: CGFloat = {
            switch indentLevel {
            case .level0: return 0
            case .level1: return 14
            case .level2: return 28
            }
        }()
        let isBoldRoot = entry.nutrient.isUpperMacronutrientSection && indentLevel == .level0
        let weightText = entry.formattedWeightToken(compact: compact)
        let dvText = entry.formattedPercentDVToken(demographic: demographic, isSupplement: false)
        let displayTitle = entry.customName ?? entry.nutrient.fdaLabelDisplayName

        return Button {
            openNutrientEditor(columnIndex: columnIndex, nutrient: entry.nutrient)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if entry.nutrient == .addedSugars {
                        Text(compact ? "Incl. \(weightText) Added Sugars" : "Includes \(weightText) Added Sugars")
                            .font(.system(size: compact ? 12 : 13.5, weight: .regular))
                    } else if entry.nutrient == .folicAcid {
                        Text("folic acid")
                            .font(.system(size: compact ? 12 : 13.5, weight: .regular))
                        Text(weightText)
                            .font(.system(size: compact ? 12 : 13.5, weight: .regular))
                    } else {
                        Text(compact ? entry.nutrient.fdaCompactDisplayName : displayTitle)
                            .font(.system(size: compact ? 12.5 : 14, weight: isBoldRoot ? .heavy : .regular))
                        if !weightText.isEmpty && !entry.derivedFromPercentDVOnly {
                            Text(weightText)
                                .font(.system(size: compact ? 12.5 : 14, weight: .regular))
                        } else if entry.derivedFromPercentDVOnly {
                            Text("(\(FDADigitalLabelFormatting.formatDecimal(entry.resolvedValue))\(entry.resolvedUnit.rawValue))")
                                .font(.system(size: 11.5, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Image(systemName: "pencil")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.secondary.opacity(0.75))
                }
                .padding(.leading, indentPoints)

                Spacer(minLength: 8)

                if !dvText.isEmpty {
                    Text(dvText)
                        .font(.system(size: compact ? 12.5 : 14, weight: isBoldRoot ? .heavy : .regular))
                        .foregroundStyle(.primary)
                }
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sideBySideMicronutrientGrid(
        entries: [ScannedNutrientEntry],
        columnIndex: Int
    ) -> some View {
        let pairCount = (entries.count + 1) / 2
        return VStack(spacing: 0) {
            ForEach(0..<pairCount, id: \.self) { rowIdx in
                if rowIdx > 0 {
                    thinRule
                }
                let leftEntry = entries[rowIdx * 2]
                let rightEntry: ScannedNutrientEntry? = (rowIdx * 2 + 1 < entries.count) ? entries[rowIdx * 2 + 1] : nil

                HStack(spacing: 8) {
                    sideBySideMicronutrientCell(entry: leftEntry, columnIndex: columnIndex)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 1)

                    if let rightEntry {
                        sideBySideMicronutrientCell(entry: rightEntry, columnIndex: columnIndex)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }

    private func sideBySideMicronutrientCell(
        entry: ScannedNutrientEntry,
        columnIndex: Int
    ) -> some View {
        let weightText = entry.formattedWeightToken(compact: true)
        let dvText = entry.formattedPercentDVToken(demographic: demographic, isSupplement: false)

        return Button {
            openNutrientEditor(columnIndex: columnIndex, nutrient: entry.nutrient)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(entry.nutrient.fdaCompactDisplayName)
                    .font(.system(size: 12.5, weight: .regular))
                if !weightText.isEmpty {
                    Text(weightText)
                        .font(.system(size: 12.5, weight: .regular))
                }
                Spacer(minLength: 2)
                if !dvText.isEmpty {
                    Text(dvText)
                        .font(.system(size: 12.5, weight: .regular))
                }
            }
            .foregroundStyle(.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Renderer 3: Supplement Facts 2-Tier (21 CFR § 101.36)

    private var supplementFactsLabel: some View {
        let col = primaryColumn
        let tier1Entries = orderedSupplementTier1Entries(for: col.nutrition)
        let tier2Entries = col.nutrition.supplementTier2Entries

        return VStack(alignment: .leading, spacing: 0) {
            Text("Supplement Facts")
                .font(.system(size: 26, weight: .black))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)

            Button {
                activeColumnIndex = 0
                editingServingColumnIndex = 0
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Serving Size \(col.formattedServingSummary)")
                            .font(.system(size: 13.5, weight: .bold))
                        Spacer()
                        Image(systemName: "pencil.line")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    if col.servingsPerContainer != nil {
                        Text(col.formattedServingsPerContainerLine)
                            .font(.system(size: 12.5, weight: .regular))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            thickRule(height: 6)

            HStack {
                Text("Amount Per Serving")
                    .font(.system(size: 11.5, weight: .bold))
                Spacer()
                Text("% Daily Value")
                    .font(.system(size: 11.5, weight: .bold))
            }
            .padding(.vertical, 3)

            thinRule

            ForEach(0..<tier1Entries.count, id: \.self) { idx in
                if idx > 0 {
                    thinRule
                }
                supplementNutrientRow(entry: tier1Entries[idx], columnIndex: 0, tier2ID: nil)
            }

            if !tier2Entries.isEmpty {
                thickRule(height: 6)

                ForEach(0..<tier2Entries.count, id: \.self) { idx in
                    if idx > 0 {
                        thinRule
                    }
                    let entry = tier2Entries[idx]
                    supplementNutrientRow(entry: entry, columnIndex: 0, tier2ID: entry.id)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .stroke(Color.primary, lineWidth: 2)
        )
    }

    private func supplementNutrientRow(
        entry: ScannedNutrientEntry,
        columnIndex: Int,
        tier2ID: UUID?
    ) -> some View {
        let weightText = entry.nutrient == .calories
            ? "\(Int(entry.resolvedValue.rounded()))"
            : entry.formattedWeightToken(compact: false)
        let dvText = entry.formattedPercentDVToken(demographic: demographic, isSupplement: true)
        let sourceText = entry.sourceCompoundDescription.map { " \($0)" } ?? ""
        let title = entry.customName ?? entry.nutrient.fdaLabelDisplayName

        return Button {
            openNutrientEditor(columnIndex: columnIndex, nutrient: entry.nutrient, tier2ID: tier2ID)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(title)\(sourceText)")
                    .font(.system(size: 13.5, weight: .regular))
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(weightText)
                        .font(.system(size: 13.5, weight: .medium))
                    Image(systemName: "pencil")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 68, alignment: .trailing)

                Text(dvText.isEmpty ? "†" : dvText)
                    .font(.system(size: 13.5, weight: .bold))
                    .frame(width: 48, alignment: .trailing)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Renderer 4: Horizontal Tabular Overflow (Topologies A & K)

    private var horizontalTabularOverflowLabel: some View {
        let col = primaryColumn
        let isCompactSmallPkg = (topology == .smallPackageTabular)
        let leftMacros = orderedTabularStackEntries(for: col.nutrition, isLeftStack: true)
        let rightMacros = orderedTabularStackEntries(for: col.nutrition, isLeftStack: false)
        let microRows = orderedVerticalMicronutrients(for: col.nutrition)
        let rowCount = max(leftMacros.count, rightMacros.count)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.and.right.square")
                    .font(.caption)
                Text("Horizontal Tabular Format — Scroll sideways to inspect both columns")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Left Sidebar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nutrition\nFacts")
                            .font(.system(size: 22, weight: .black))
                            .lineSpacing(-2)

                        thinRule

                        Button {
                            activeColumnIndex = 0
                            editingServingColumnIndex = 0
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(col.formattedServingsPerContainerLine)
                                    .font(.system(size: 11.5))
                                Text("Serving size")
                                    .font(.system(size: 12.5, weight: .heavy))
                                HStack(spacing: 3) {
                                    Text(col.formattedServingSummary)
                                        .font(.system(size: 12.5, weight: .heavy))
                                    Image(systemName: "pencil.line")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        thickRule(height: 5)

                        Button {
                            openNutrientEditor(columnIndex: 0, nutrient: .calories)
                        } label: {
                            HStack(alignment: .lastTextBaseline) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Calories")
                                        .font(.system(size: 15, weight: .black))
                                    Text("per serving")
                                        .font(.system(size: 10.5, weight: .bold))
                                }
                                Spacer()
                                Text("\(col.nutrition.calories)")
                                    .font(.system(size: 24, weight: .black))
                            }
                            .foregroundStyle(.primary)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 155, alignment: .leading)
                    .padding(.trailing, 8)

                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 1.5)

                    // Right Area: Parallel Left & Right Macro Stacks + Bottom Bullet Micronutrients
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            HStack {
                                Text("Amount/serving")
                                    .font(.system(size: 11, weight: .heavy))
                                Spacer()
                                Text("% DV*")
                                    .font(.system(size: 11, weight: .heavy))
                            }
                            .frame(width: 235)

                            HStack {
                                Text("Amount/serving")
                                    .font(.system(size: 11, weight: .heavy))
                                Spacer()
                                Text("% DV*")
                                    .font(.system(size: 11, weight: .heavy))
                            }
                            .frame(width: 245)
                        }
                        .padding(.bottom, 3)

                        thickRule(height: 5)

                        ForEach(0..<rowCount, id: \.self) { idx in
                            if idx > 0 {
                                thinRule
                            }
                            HStack(spacing: 12) {
                                Group {
                                    if idx < leftMacros.count {
                                        verticalSingleNutrientRow(
                                            entry: leftMacros[idx],
                                            columnIndex: 0,
                                            compact: isCompactSmallPkg
                                        )
                                    } else {
                                        Spacer()
                                    }
                                }
                                .frame(width: 235)

                                Rectangle()
                                    .fill(Color.primary.opacity(0.3))
                                    .frame(width: 1)

                                Group {
                                    if idx < rightMacros.count {
                                        verticalSingleNutrientRow(
                                            entry: rightMacros[idx],
                                            columnIndex: 0,
                                            compact: isCompactSmallPkg
                                        )
                                    } else {
                                        Spacer()
                                    }
                                }
                                .frame(width: 245)
                            }
                        }

                        if !microRows.isEmpty {
                            thickRule(height: 5)
                            tabularBulletMicronutrientFooter(entries: microRows, compact: isCompactSmallPkg)
                                .frame(width: 492, alignment: .leading)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .stroke(Color.primary, lineWidth: 2)
                )
            }
        }
    }

    private func tabularBulletMicronutrientFooter(
        entries: [ScannedNutrientEntry],
        compact: Bool
    ) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
            alignment: .leading,
            spacing: 4
        ) {
            ForEach(entries, id: \.nutrient) { entry in
                let wText = entry.formattedWeightToken(compact: compact)
                let dvText = entry.formattedPercentDVToken(demographic: demographic, isSupplement: false)
                let title = entry.customName ?? entry.nutrient.fdaLabelDisplayName
                Button {
                    openNutrientEditor(columnIndex: 0, nutrient: entry.nutrient)
                } label: {
                    HStack(spacing: 4) {
                        Text("•")
                            .font(.system(size: 12, weight: .bold))
                        Text(compact ? entry.nutrient.fdaCompactDisplayName : title)
                            .font(.system(size: 12))
                        if !wText.isEmpty {
                            Text(wText)
                                .font(.system(size: 12))
                        }
                        if !dvText.isEmpty {
                            Text(dvText)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Renderer 5: Unified Multi-Column Matrix (Topologies E, F, G, H, I)

    private var multiColumnMatrixLabel: some View {
        let unionNutrients = orderedUnionNutrientsAcrossColumns()
        let upperNutrients = unionNutrients.filter { $0.isUpperMacronutrientSection }
        let microNutrients = unionNutrients.filter { !$0.isUpperMacronutrientSection }
        let colWidth: CGFloat = columns.count >= 3 ? 132 : 142
        let labelColWidth: CGFloat = 152

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.rectangle.stack.fill")
                    .font(.caption)
                Text("Multi-Column Label — Check columns to batch-save, tap column headers to rename, or tap any cell to edit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    multiColumnHeaderBand(labelWidth: labelColWidth, columnWidth: colWidth)
                    thinRule
                    multiColumnServingRow(labelWidth: labelColWidth, columnWidth: colWidth)
                    thickRule(height: 7)
                    multiColumnCaloriesRow(labelWidth: labelColWidth, columnWidth: colWidth)
                    thickRule(height: 4)
                    multiColumnDVSubheaderRow(labelWidth: labelColWidth, columnWidth: colWidth)

                    ForEach(upperNutrients, id: \.self) { nutrient in
                        thinRule
                        multiColumnNutrientRow(
                            nutrient: nutrient,
                            labelWidth: labelColWidth,
                            columnWidth: colWidth
                        )
                    }

                    if !microNutrients.isEmpty {
                        thickRule(height: 7)

                        ForEach(0..<microNutrients.count, id: \.self) { idx in
                            if idx > 0 {
                                thinRule
                            }
                            multiColumnNutrientRow(
                                nutrient: microNutrients[idx],
                                labelWidth: labelColWidth,
                                columnWidth: colWidth
                            )
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .stroke(Color.primary, lineWidth: 2)
                )
            }
        }
    }

    private func multiColumnHeaderBand(labelWidth: CGFloat, columnWidth: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nutrition Facts")
                    .font(.system(size: 23, weight: .black))
                Text(primaryColumn.formattedServingsPerContainerLine)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            .frame(width: labelWidth, alignment: .leading)
            .padding(.trailing, 6)

            ForEach(0..<columns.count, id: \.self) { idx in
                multiColumnHeaderCell(column: columns[idx], index: idx, width: columnWidth)
            }
        }
        .padding(.bottom, 6)
    }

    private func multiColumnServingRow(labelWidth: CGFloat, columnWidth: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text("Serving size")
                .font(.system(size: 13.5, weight: .heavy))
                .frame(width: labelWidth, alignment: .leading)
                .padding(.trailing, 6)

            ForEach(0..<columns.count, id: \.self) { idx in
                let col = columns[idx]
                Button {
                    activeColumnIndex = idx
                    editingServingColumnIndex = idx
                } label: {
                    HStack(spacing: 3) {
                        Text(col.formattedServingSummary)
                            .font(.system(size: 12, weight: .bold))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                        Image(systemName: "pencil")
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: columnWidth, alignment: .trailing)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 4)
                    .background(columnHighlightBackground(for: idx))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func multiColumnCaloriesRow(labelWidth: CGFloat, columnWidth: CGFloat) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Amount per serving")
                    .font(.system(size: 10.5, weight: .bold))
                Text("Calories")
                    .font(.system(size: 19, weight: .black))
            }
            .frame(width: labelWidth, alignment: .leading)
            .padding(.trailing, 6)

            ForEach(0..<columns.count, id: \.self) { idx in
                let col = columns[idx]
                Button {
                    openNutrientEditor(columnIndex: idx, nutrient: .calories)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Spacer()
                        Text("\(col.nutrition.calories)")
                            .font(.system(size: 24, weight: .black))
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: columnWidth, alignment: .trailing)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .background(columnHighlightBackground(for: idx))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func multiColumnDVSubheaderRow(labelWidth: CGFloat, columnWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: labelWidth)
                .padding(.trailing, 6)

            ForEach(0..<columns.count, id: \.self) { idx in
                HStack {
                    Spacer()
                    Text("% DV*")
                        .font(.system(size: 11, weight: .heavy))
                }
                .frame(width: columnWidth)
                .padding(.vertical, 3)
                .padding(.horizontal, 4)
                .background(columnHighlightBackground(for: idx))
            }
        }
    }

    private func multiColumnHeaderCell(
        column: FDADigitalLabelColumnDraft,
        index: Int,
        width: CGFloat
    ) -> some View {
        let isActive = (activeColumnIndex == index)
        return VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Button {
                    columns[index].isIncluded.toggle()
                    activeColumnIndex = index
                } label: {
                    Image(systemName: column.isIncluded ? "checkmark.square.fill" : "square")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(column.isIncluded ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    activeColumnIndex = index
                    editingColumnTitleIndex = index
                } label: {
                    HStack(spacing: 3) {
                        Text(column.headerTitle)
                            .font(.system(size: 12, weight: .heavy))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                        Image(systemName: "pencil")
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(column.isIncluded ? .primary : .secondary)
        }
        .frame(width: width, alignment: .trailing)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }

    private func multiColumnNutrientRow(
        nutrient: CanonicalNutrientID,
        labelWidth: CGFloat,
        columnWidth: CGFloat
    ) -> some View {
        let indentPoints: CGFloat = {
            switch nutrient.indentationLevel {
            case .level0: return 0
            case .level1: return 12
            case .level2: return 22
            }
        }()
        let isBoldRoot = nutrient.isUpperMacronutrientSection && nutrient.indentationLevel == .level0

        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(nutrient == .addedSugars ? "Incl. Added Sugars" : nutrient.fdaLabelDisplayName)
                .font(.system(size: 13, weight: isBoldRoot ? .heavy : .regular))
                .padding(.leading, indentPoints)
                .frame(width: labelWidth, alignment: .leading)
                .padding(.trailing, 6)

            ForEach(0..<columns.count, id: \.self) { colIdx in
                let col = columns[colIdx]
                let entry = col.nutrition.entries[nutrient]
                let weightText: String = {
                    guard let entry else { return "0\(nutrient.primaryUnit.rawValue)" }
                    if entry.derivedFromPercentDVOnly {
                        return ""
                    }
                    return entry.formattedWeightToken(compact: true)
                }()
                let dvText = entry?.formattedPercentDVToken(demographic: demographic, isSupplement: false) ?? ""

                Button {
                    openNutrientEditor(columnIndex: colIdx, nutrient: nutrient)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(weightText)
                            .font(.system(size: 12.5, weight: .regular))
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        Text(dvText)
                            .font(.system(size: 12.5, weight: isBoldRoot ? .heavy : .regular))
                            .frame(width: 40, alignment: .trailing)
                    }
                    .foregroundStyle(col.isIncluded ? .primary : .secondary)
                    .frame(width: columnWidth)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .background(columnHighlightBackground(for: colIdx))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func columnHighlightBackground(for index: Int) -> Color {
        guard activeColumnIndex == index else {
            return .clear
        }
        return Color.accentColor.opacity(0.08)
    }

    // MARK: - Renderer 6: Linear Display (Topology L)

    private var linearDisplayLabel: some View {
        let col = primaryColumn
        let entries = orderedVerticalUpperMacros(for: col.nutrition) + orderedVerticalMicronutrients(for: col.nutrition)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Nutrition Facts")
                    .font(.system(size: 17, weight: .black))
                Button {
                    activeColumnIndex = 0
                    editingServingColumnIndex = 0
                } label: {
                    HStack(spacing: 3) {
                        Text("Serv. size: \(col.formattedServingSummary),")
                            .font(.system(size: 13.5, weight: .bold))
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                }
                .buttonStyle(.plain)

                Text("Amount per serving:")
                    .font(.system(size: 13.5, weight: .bold))
            }

            FlowLayoutWrap(spacing: 6) {
                Button {
                    openNutrientEditor(columnIndex: 0, nutrient: .calories)
                } label: {
                    Text("Calories \(col.nutrition.calories),")
                        .font(.system(size: 14, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)

                ForEach(entries, id: \.nutrient) { entry in
                    let wText = entry.formattedWeightToken(compact: true)
                    let dvText = entry.formattedPercentDVToken(demographic: demographic, isSupplement: false)
                    let dvClause = dvText.isEmpty ? "" : " (\(dvText) DV)"

                    Button {
                        openNutrientEditor(columnIndex: 0, nutrient: entry.nutrient)
                    } label: {
                        Text("\(entry.nutrient.fdaCompactDisplayName) \(wText)\(dvClause),")
                            .font(.system(size: 13.5, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .stroke(Color.primary, lineWidth: 2)
        )
    }

    // MARK: - "+ Add Nutrient Line" Bar

    private var addNutrientBar: some View {
        Button {
            showingAddNutrientSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("Add Nutrient Line")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Inserts in exact FDA sequence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Divider Rules & Ordering Helpers

    private var thinRule: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.45))
            .frame(height: 1)
    }

    private func thickRule(height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.primary)
            .frame(height: height)
    }

    private func openNutrientEditor(
        columnIndex: Int,
        nutrient: CanonicalNutrientID,
        tier2ID: UUID? = nil
    ) {
        let safeIdx = min(max(0, columnIndex), max(0, columns.count - 1))
        activeColumnIndex = safeIdx
        editingNutrientContext = NutrientEditContext(
            columnIndex: safeIdx,
            nutrient: nutrient,
            tier2EntryID: tier2ID
        )
    }

    private func orderedVerticalUpperMacros(for profile: NutritionProfile) -> [ScannedNutrientEntry] {
        var list = profile.orderedPresentMacroEntries()
        if list.isEmpty {
            let coreDefaults: [CanonicalNutrientID] = [
                .totalFat, .saturatedFat, .transFat, .cholesterol, .sodium,
                .totalCarbohydrate, .dietaryFiber, .totalSugars, .addedSugars, .protein
            ]
            list = coreDefaults.map { id in
                profile.entries[id] ?? ScannedNutrientEntry(
                    nutrient: id,
                    amount: .explicitZero(unit: id.primaryUnit)
                )
            }
        }
        return list
    }

    private func orderedVerticalMicronutrients(for profile: NutritionProfile) -> [ScannedNutrientEntry] {
        profile.orderedPresentMicronutrientEntries(isSupplement: false)
    }

    private func orderedSupplementTier1Entries(for profile: NutritionProfile) -> [ScannedNutrientEntry] {
        NutritionProfile.orderedSupplementTier1Sequence.compactMap { profile.entry(for: $0) }
    }

    private func orderedTabularStackEntries(
        for profile: NutritionProfile,
        isLeftStack: Bool
    ) -> [ScannedNutrientEntry] {
        let upper = orderedVerticalUpperMacros(for: profile)
        if isLeftStack {
            return upper.filter { $0.nutrient.isTabularLeftStackNutrient }
        } else {
            return upper.filter { $0.nutrient.isTabularRightStackNutrient }
        }
    }

    private func orderedUnionNutrientsAcrossColumns() -> [CanonicalNutrientID] {
        var unionSet = Set<CanonicalNutrientID>()
        for col in columns {
            for key in col.nutrition.entries.keys where key != .calories && key != .proprietaryBlend {
                unionSet.insert(key)
            }
        }
        if unionSet.isEmpty {
            unionSet.formUnion([
                .totalFat, .saturatedFat, .transFat, .cholesterol, .sodium,
                .totalCarbohydrate, .dietaryFiber, .totalSugars, .addedSugars, .protein
            ])
        }
        return unionSet.sorted { (lhs: CanonicalNutrientID, rhs: CanonicalNutrientID) in
            FDADigitalLabelFormatting.sortIndex(for: lhs) < FDADigitalLabelFormatting.sortIndex(for: rhs)
        }
    }
}

// MARK: - 3. Simple Flow Wrap Layout for Linear Display (Topology L)

private struct FlowLayoutWrap: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - 4. Inline Nutrient Weight Editor Sheet (Read-Only % DV)

private struct FDANutrientInlineEditorSheet: View {
    @Binding var column: FDADigitalLabelColumnDraft
    let nutrient: CanonicalNutrientID
    let tier2EntryID: UUID?
    let demographic: FDADemographicGroup
    let isSupplement: Bool
    let isMultiColumn: Bool
    let onDismiss: () -> Void

    @State private var numericValueText: String = ""
    @State private var selectedUnit: NutrientUnit = .g
    @State private var customIngredientName: String = ""
    @State private var sourceCompoundText: String = ""
    @State private var folicAcidSecondaryText: String = ""

    private var previewPercentDVText: String {
        guard let val = Double(numericValueText), val >= 0 else {
            return "—"
        }
        let tempEntry = ScannedNutrientEntry(
            nutrient: nutrient,
            amount: val == 0 ? .explicitZero(unit: selectedUnit) : .exact(value: val, unit: selectedUnit),
            percentDV: .omitted
        )
        let token = tempEntry.formattedPercentDVToken(demographic: demographic, isSupplement: isSupplement)
        return token.isEmpty ? "Not Established / Omitted" : token
    }

    var body: some View {
        NavigationStack {
            Form {
                if isMultiColumn {
                    Section {
                        HStack {
                            Text("Editing Column")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(column.headerTitle)
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }

                Section("Nutrient Quantity") {
                    if tier2EntryID != nil {
                        TextField("Ingredient / Blend Name", text: $customIngredientName)
                    } else {
                        HStack {
                            Text("Nutrient")
                            Spacer()
                            Text(nutrient.fdaLabelDisplayName)
                                .fontWeight(.semibold)
                        }
                    }

                    HStack {
                        Text(nutrient == .calories ? "Calories" : "Amount")
                        Spacer()
                        TextField("0", text: $numericValueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                            .frame(width: 120)
                    }

                    if nutrient != .calories {
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(allowedUnits(for: nutrient), id: \.self) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                    }

                    HStack {
                        Text("% Daily Value (Read-Only)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(previewPercentDVText)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }

                if nutrient == .folate {
                    Section("Optional Folic Acid Sub-Declaration") {
                        HStack {
                            Text("Folic Acid (mcg)")
                            Spacer()
                            TextField("Optional mcg", text: $folicAcidSecondaryText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 130)
                        }
                    }
                }

                if isSupplement {
                    Section("Supplement Source Compound (Optional)") {
                        TextField("e.g. (as cholecalciferol)", text: $sourceCompoundText)
                    }
                }

                if nutrient != .calories {
                    Section {
                        Button(role: .destructive) {
                            removeNutrientEntry()
                            onDismiss()
                        } label: {
                            Label("Remove Line from Digital Label", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Edit \(nutrient.fdaLabelDisplayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyChanges()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadInitialValues)
        }
    }

    private func allowedUnits(for id: CanonicalNutrientID) -> [NutrientUnit] {
        switch id {
        case .vitaminA:
            return [.mcgRAE, .mcg, .iu]
        case .folate:
            return [.mcgDFE, .mcg]
        case .niacin:
            return [.mgNE, .mg]
        case .vitaminD, .vitaminE:
            return [id.primaryUnit, .iu, .mg, .mcg]
        default:
            let base = id.primaryUnit
            var list: [NutrientUnit] = [base]
            for fallback in [NutrientUnit.g, .mg, .mcg, .iu] where !list.contains(fallback) {
                list.append(fallback)
            }
            return list
        }
    }

    private func loadInitialValues() {
        if let tier2ID = tier2EntryID,
           let existingTier2 = column.nutrition.supplementTier2Entries.first(where: { $0.id == tier2ID }) {
            numericValueText = FDADigitalLabelFormatting.formatDecimal(existingTier2.resolvedValue)
            selectedUnit = existingTier2.resolvedUnit
            customIngredientName = existingTier2.customName ?? ""
            sourceCompoundText = existingTier2.sourceCompoundDescription ?? ""
            return
        }

        if let existing = column.nutrition.entries[nutrient] {
            numericValueText = FDADigitalLabelFormatting.formatDecimal(existing.resolvedValue)
            selectedUnit = existing.resolvedUnit
            sourceCompoundText = existing.sourceCompoundDescription ?? ""
            if nutrient == .folate {
                if case .exact(_, _, let secVal, _) = existing.amount, let secVal {
                    folicAcidSecondaryText = FDADigitalLabelFormatting.formatDecimal(secVal)
                } else if let standaloneFolic = column.nutrition.entries[.folicAcid]?.resolvedValue {
                    folicAcidSecondaryText = FDADigitalLabelFormatting.formatDecimal(standaloneFolic)
                }
            }
        } else {
            numericValueText = "0"
            selectedUnit = nutrient.primaryUnit
        }
    }

    private func applyChanges() {
        let parsedVal = max(0.0, Double(numericValueText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0)
        let cleanSource = sourceCompoundText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let tier2ID = tier2EntryID {
            if let idx = column.nutrition.supplementTier2Entries.firstIndex(where: { $0.id == tier2ID }) {
                let cleanCustom = customIngredientName.trimmingCharacters(in: .whitespacesAndNewlines)
                column.nutrition.supplementTier2Entries[idx].customName = cleanCustom.isEmpty ? "Dietary Ingredient" : cleanCustom
                column.nutrition.supplementTier2Entries[idx].sourceCompoundDescription = cleanSource.isEmpty ? nil : cleanSource
                column.nutrition.supplementTier2Entries[idx].amount = parsedVal == 0
                    ? .explicitZero(unit: selectedUnit)
                    : .exact(value: parsedVal, unit: selectedUnit)
            }
            return
        }

        column.nutrition.setExactValue(
            parsedVal,
            unit: selectedUnit,
            for: nutrient,
            demographic: demographic,
            isSupplement: isSupplement
        )
        if var updated = column.nutrition.entries[nutrient] {
            updated.sourceCompoundDescription = cleanSource.isEmpty ? nil : cleanSource
            column.nutrition.entries[nutrient] = updated
        }

        if nutrient == .folate {
            let trimmedFolic = folicAcidSecondaryText.trimmingCharacters(in: .whitespacesAndNewlines)
            if let folicVal = Double(trimmedFolic), folicVal > 0 {
                column.nutrition.setExactValue(
                    folicVal,
                    unit: .mcg,
                    for: .folicAcid,
                    demographic: demographic,
                    isSupplement: isSupplement
                )
            }
        }
    }

    private func removeNutrientEntry() {
        if let tier2ID = tier2EntryID {
            column.nutrition.supplementTier2Entries.removeAll { $0.id == tier2ID }
        } else {
            column.nutrition.removeNutrient(nutrient)
        }
    }
}

// MARK: - 5. Inline Serving Size & Container Editor Sheet

private struct FDAServingSizeEditorSheet: View {
    @Binding var column: FDADigitalLabelColumnDraft
    let isMultiColumn: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var metricAmountText: String = ""
    @State private var metricUnit: String = "g"
    @State private var householdAmountText: String = ""
    @State private var householdUnitText: String = ""
    @State private var servingsPerContainerText: String = ""
    @State private var servingsModifier: String = ""

    var body: some View {
        NavigationStack {
            Form {
                if isMultiColumn {
                    Section {
                        HStack {
                            Text("Column")
                            Spacer()
                            Text(column.headerTitle)
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section("Metric Serving Weight / Volume") {
                    HStack {
                        Text("Metric Quantity")
                        Spacer()
                        TextField("100", text: $metricAmountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 110)
                    }
                    Picker("Metric Unit", selection: $metricUnit) {
                        Text("g").tag("g")
                        Text("ml").tag("ml")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Common Household Measure (e.g. 2/3 cup, 1 box)") {
                    HStack {
                        Text("Household Amount")
                        Spacer()
                        TextField("Optional (e.g. 1)", text: $householdAmountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 130)
                    }
                    HStack {
                        Text("Household Unit")
                        Spacer()
                        TextField("Optional (e.g. cup, box, tbsp)", text: $householdUnitText)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Servings Per Container") {
                    HStack {
                        Text("Servings Count")
                        Spacer()
                        TextField("Optional (e.g. 8)", text: $servingsPerContainerText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 130)
                    }
                    Picker("Modifier", selection: $servingsModifier) {
                        Text("Exact").tag("")
                        Text("About").tag("about")
                        Text("Usually").tag("usually")
                        Text("Varied").tag("varied")
                    }
                }
            }
            .navigationTitle("Edit Serving Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if let mVal = Double(metricAmountText), mVal > 0 {
                            column.servingSize = mVal
                        }
                        column.servingUnit = metricUnit
                        column.commonHouseholdMeasurementAmount = Double(householdAmountText)
                        let cleanHH = householdUnitText.trimmingCharacters(in: .whitespacesAndNewlines)
                        column.commonHouseholdMeasurement = cleanHH.isEmpty ? nil : cleanHH
                        column.servingsPerContainer = Double(servingsPerContainerText)
                        column.servingsPerContainerModifier = servingsModifier.isEmpty ? nil : servingsModifier
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                metricAmountText = FDADigitalLabelFormatting.formatDecimal(column.servingSize)
                metricUnit = (column.servingUnit.lowercased() == "ml") ? "ml" : "g"
                if let hhAmt = column.commonHouseholdMeasurementAmount {
                    householdAmountText = FDADigitalLabelFormatting.formatDecimal(hhAmt)
                }
                householdUnitText = column.commonHouseholdMeasurement ?? ""
                if let spc = column.servingsPerContainer {
                    servingsPerContainerText = FDADigitalLabelFormatting.formatDecimal(spc)
                }
                servingsModifier = column.servingsPerContainerModifier?.lowercased() ?? ""
            }
        }
    }
}

// MARK: - 6. Multi-Column Header Title Editor Sheet

private struct FDAColumnTitleEditorSheet: View {
    @Binding var column: FDADigitalLabelColumnDraft
    @Environment(\.dismiss) private var dismiss
    @State private var titleText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Column Header / Item Variant Name") {
                    TextField("Column Name", text: $titleText)
                    Toggle("Include in Batch Save", isOn: $column.isIncluded)
                }
            }
            .navigationTitle("Edit Column Header")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let clean = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !clean.isEmpty {
                            column.headerTitle = clean
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                titleText = column.headerTitle
            }
        }
    }
}

// MARK: - 7. "+ Add Nutrient Line" Searchable Picker Sheet

private struct FDAAddNutrientPickerSheet: View {
    @Binding var columns: [FDADigitalLabelColumnDraft]
    let isSupplement: Bool
    let demographic: FDADemographicGroup
    let onAddedNutrient: (CanonicalNutrientID, UUID?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var availableNutrients: [CanonicalNutrientID] {
        let all = FDADigitalLabelFormatting.canonicalFDASequence
            .filter { $0 != .calories && $0 != .proprietaryBlend && $0 != .otherDietaryIngredient }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return all
        }
        let q = searchText.lowercased()
        return all.filter {
            $0.fdaLabelDisplayName.lowercased().contains(q)
                || $0.rawValue.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if isSupplement {
                    Section("Supplement Tier-2 Non-DV Ingredient (§ 101.36(b)(3))") {
                        Button {
                            let newEntry = ScannedNutrientEntry(
                                nutrient: .proprietaryBlend,
                                amount: .exact(value: 100, unit: .mg),
                                percentDV: .notEstablished(symbol: "†"),
                                customName: "Dietary Ingredient"
                            )
                            for idx in columns.indices {
                                columns[idx].nutrition.supplementTier2Entries.append(newEntry)
                            }
                            dismiss()
                            onAddedNutrient(.proprietaryBlend, newEntry.id)
                        } label: {
                            Label("Add Custom Supplement Ingredient / Blend", systemImage: "leaf.fill")
                        }
                    }
                }

                Section("Macronutrients & Sub-Fractions") {
                    ForEach(availableNutrients.filter { $0.isUpperMacronutrientSection }, id: \.self) { nutrient in
                        nutrientRowButton(for: nutrient)
                    }
                }

                Section("Vitamins & Minerals (FDA RDI Spectrum)") {
                    ForEach(availableNutrients.filter { !$0.isUpperMacronutrientSection }, id: \.self) { nutrient in
                        nutrientRowButton(for: nutrient)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search 58 FDA nutrients (e.g. Zinc, Thiamin, Sugar Alcohol)")
            .navigationTitle("Add Nutrient Line")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func nutrientRowButton(for nutrient: CanonicalNutrientID) -> some View {
        let alreadyPresent = columns.first?.nutrition.entries[nutrient] != nil
        return Button {
            for idx in columns.indices {
                if columns[idx].nutrition.entries[nutrient] == nil {
                    columns[idx].nutrition.setExactValue(
                        0.0,
                        unit: nutrient.primaryUnit,
                        for: nutrient,
                        demographic: demographic,
                        isSupplement: isSupplement
                    )
                }
            }
            dismiss()
            onAddedNutrient(nutrient, nil)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(nutrient.fdaLabelDisplayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("Default unit: \(nutrient.primaryUnit.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if alreadyPresent {
                    Text("On Label")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}
