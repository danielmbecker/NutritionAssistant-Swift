//
//  LabelScanningTestsView.swift
//  NutritionAssistant
//
//  Milestone 5.5: LabelScanningTests UI, Sequential Multi-Run Inspector & Transfer Controls
//  Provides camera & photo library lossless test capture, "Re-Run Previous Test" fixture selection,
//  explicit per-parameter Correct / Incorrect manual verification with typed correction inputs and
//  Run #2+ ground-truth suggestions, read-only display of all 5 optical metrics + internal pipeline
//  telemetry, sequential multi-run comparison, and JSON suite export/import.
//

import AVFoundation
import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct LabelScanningTestsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScannerTestItem.createdAt, order: .reverse) private var testItems: [ScannerTestItem]

    @State private var navigationPath: [UUID] = []
    @State private var showingCameraPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPreviousTestSheet = false
    @State private var isRunningScan = false
    @State private var statusBannerMessage: String?

    @State private var alertTitle = "Label Scanning Tests"
    @State private var alertMessage: String?
    @State private var showingAlert = false

    @State private var exportDocument: ScannerTestSuiteDocument?
    @State private var showingFileExporter = false
    @State private var showingFileImporter = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                actionControlsSection
                suiteSummarySection
                savedTestsSection
            }
            .navigationTitle("Label Scanning Tests")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    transferMenu
                }
            }
            .navigationDestination(for: UUID.self) { itemID in
                if let item = testItems.first(where: { $0.id == itemID }) {
                    ScannerTestItemDetailView(
                        testItem: item,
                        onReRunRequested: { targetItem in
                            Task {
                                await reRunTest(for: targetItem)
                            }
                        }
                    )
                } else {
                    ContentUnavailableView("Test Item Not Found", systemImage: "exclamationmark.triangle")
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    await handlePickedPhoto(item)
                }
            }
            .sheet(isPresented: $showingCameraPicker) {
                NutritionLabelCameraPicker(captureLosslessPNG: true) { capturedData in
                    Task {
                        await createNewTestFromImageData(capturedData)
                    }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingPreviousTestSheet) {
                PreviousTestSelectorSheet(
                    testItems: testItems,
                    isRunningScan: isRunningScan,
                    onSelectSingleItem: { selectedItem in
                        showingPreviousTestSheet = false
                        Task {
                            await reRunTest(for: selectedItem)
                        }
                    },
                    onReRunAllItems: {
                        showingPreviousTestSheet = false
                        Task {
                            await reRunAllSavedTests()
                        }
                    }
                )
            }
            .fileExporter(
                isPresented: $showingFileExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: ScannerTestSuiteTransferManager.defaultExportFilename()
            ) { result in
                switch result {
                case .success:
                    presentAlert(
                        title: "Export Complete",
                        message: "Successfully exported \(testItems.count) test fixture(s) and their run histories."
                    )
                case .failure(let error):
                    presentAlert(title: "Export Failed", message: error.localizedDescription)
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImportResult(result)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    alertMessage = nil
                }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - Dashboard Sections

    @ViewBuilder
    private var actionControlsSection: some View {
        Section(header: Text("Capture & Regression Controls")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        handleAddCameraTestTapped()
                    } label: {
                        Label("Add Test Data", systemImage: "camera.viewfinder")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunningScan)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunningScan)
                }

                Button {
                    showingPreviousTestSheet = true
                } label: {
                    Label("Re-Run Previous Test", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .disabled(isRunningScan || testItems.isEmpty)

                if isRunningScan {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(statusBannerMessage ?? "Running Vision & Optical Telemetry Pipeline...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var suiteSummarySection: some View {
        if !testItems.isEmpty {
            Section(header: Text("Corpus Overview")) {
                let totalRuns = testItems.reduce(0) { $0 + $1.runs.count }
                let latestRatios = testItems.compactMap { $0.latestRun?.accuracyRatio }
                let avgAccuracyText: String = {
                    guard !latestRatios.isEmpty else { return "Pending Manual Review" }
                    let mean = latestRatios.reduce(0.0, +) / Double(latestRatios.count)
                    return "\(Int((mean * 100.0).rounded()))% across \(latestRatios.count) verified item(s)"
                }()

                HStack {
                    Label("Saved Fixtures", systemImage: "photo.stack")
                    Spacer()
                    Text("\(testItems.count) image(s) • \(totalRuns) run(s)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Label("Latest Run Accuracy", systemImage: "chart.bar.xaxis")
                    Spacer()
                    Text(avgAccuracyText)
                        .fontWeight(.medium)
                        .foregroundColor(latestRatios.isEmpty ? .secondary : .primary)
                }
            }
        }
    }

    @ViewBuilder
    private var savedTestsSection: some View {
        Section(header: Text("Saved Label Scan Tests (\(testItems.count))")) {
            if testItems.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "viewfinder.rectangular")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Label Scan Tests Yet")
                        .font(.headline)
                    Text("Tap \"Add Test Data\" to capture a lossless nutrition or supplement label image and verify each extracted parameter.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(testItems) { item in
                    NavigationLink(value: item.id) {
                        ScannerTestItemRowView(testItem: item)
                    }
                }
                .onDelete(perform: deleteTestItems)
            }
        }
    }

    private var transferMenu: some View {
        Menu {
            Button {
                prepareAndShowExport()
            } label: {
                Label("Export Test Suite (.json)", systemImage: "square.and.arrow.up")
            }
            .disabled(testItems.isEmpty || isRunningScan)

            Button {
                showingFileImporter = true
            } label: {
                Label("Import Test Suite (.json)", systemImage: "square.and.arrow.down")
            }
            .disabled(isRunningScan)
        } label: {
            Label("Import / Export", systemImage: "arrow.up.arrow.down.circle")
        }
    }

    // MARK: - Actions & Pipeline Execution

    @MainActor
    private func handleAddCameraTestTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentAlert(
                title: "Camera Unavailable",
                message: "Camera capture is unavailable on this simulator or device. Use Photo Library to add a test image."
            )
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
                    presentAlert(
                        title: "Camera Permission Required",
                        message: "Please enable Camera access in Settings > Privacy & Security > Camera."
                    )
                }
            }
        case .denied, .restricted:
            presentAlert(
                title: "Camera Permission Disabled",
                message: "Camera access is disabled. Please enable it in Settings > Privacy & Security > Camera."
            )
        @unknown default:
            presentAlert(title: "Camera Error", message: "Unable to verify camera authorization status.")
        }
    }

    @MainActor
    private func handlePickedPhoto(_ item: PhotosPickerItem) async {
        defer { selectedPhotoItem = nil }
        do {
            guard let rawData = try await item.loadTransferable(type: Data.self), !rawData.isEmpty else {
                presentAlert(title: "Photo Load Error", message: "Could not load image data from the selected photo.")
                return
            }
            let losslessData: Data
            if let uiImage = UIImage(data: rawData),
               let pngData = NutritionLabelCameraPicker.losslessNormalizedPNGData(from: uiImage) {
                losslessData = pngData
            } else {
                losslessData = rawData
            }
            await createNewTestFromImageData(losslessData)
        } catch {
            presentAlert(title: "Photo Load Error", message: error.localizedDescription)
        }
    }

    @MainActor
    private func createNewTestFromImageData(_ imageData: Data) async {
        isRunningScan = true
        statusBannerMessage = "Scanning label & computing 5 optical metrics..."
        defer {
            isRunningScan = false
            statusBannerMessage = nil
        }

        do {
            let evaluation = try await NutritionScanCoordinator.scanWithDiagnostics(imageData: imageData)
            let newItem = ScannerTestItem(
                createdAt: Date(),
                labelTitle: "",
                originalImageData: imageData
            )
            let firstRun = ScannerTestRun(
                runNumber: 1,
                timestamp: Date(),
                payload: evaluation.payload,
                columnCandidates: evaluation.columnCandidates,
                diagnostics: evaluation.diagnostics
            )
            firstRun.testItem = newItem
            newItem.runs.append(firstRun)

            modelContext.insert(newItem)
            modelContext.insert(firstRun)
            try? modelContext.save()

            navigationPath.append(newItem.id)
        } catch {
            presentAlert(title: "Label Scan Failed", message: error.localizedDescription)
        }
    }

    @MainActor
    private func reRunTest(for item: ScannerTestItem) async {
        isRunningScan = true
        let nextNum = item.nextRunNumber
        statusBannerMessage = "Executing Run #\(nextNum) on lossless image..."
        defer {
            isRunningScan = false
            statusBannerMessage = nil
        }

        do {
            let evaluation = try await NutritionScanCoordinator.scanWithDiagnostics(
                imageData: item.originalImageData
            )
            let newRun = ScannerTestRun(
                runNumber: nextNum,
                timestamp: Date(),
                payload: evaluation.payload,
                columnCandidates: evaluation.columnCandidates,
                diagnostics: evaluation.diagnostics
            )
            newRun.testItem = item
            item.runs.append(newRun)
            modelContext.insert(newRun)
            try? modelContext.save()

            if navigationPath.last != item.id {
                navigationPath.append(item.id)
            }
        } catch {
            presentAlert(title: "Re-Run Failed", message: error.localizedDescription)
        }
    }

    @MainActor
    private func reRunAllSavedTests() async {
        guard !testItems.isEmpty else { return }
        isRunningScan = true
        defer {
            isRunningScan = false
            statusBannerMessage = nil
        }

        var successCount = 0
        var failureCount = 0

        for (index, item) in testItems.enumerated() {
            statusBannerMessage = "Re-running test \(index + 1) of \(testItems.count)..."
            do {
                let evaluation = try await NutritionScanCoordinator.scanWithDiagnostics(
                    imageData: item.originalImageData
                )
                let newRun = ScannerTestRun(
                    runNumber: item.nextRunNumber,
                    timestamp: Date(),
                    payload: evaluation.payload,
                    columnCandidates: evaluation.columnCandidates,
                    diagnostics: evaluation.diagnostics
                )
                newRun.testItem = item
                item.runs.append(newRun)
                modelContext.insert(newRun)
                successCount += 1
            } catch {
                failureCount += 1
            }
        }

        try? modelContext.save()
        presentAlert(
            title: "Batch Re-Run Complete",
            message: "Completed \(successCount) new test run(s) (\(failureCount) failed). Select each item to manually verify the new run's output."
        )
    }

    private func deleteTestItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(testItems[index])
        }
        try? modelContext.save()
    }

    private func prepareAndShowExport() {
        do {
            exportDocument = try ScannerTestSuiteTransferManager.makeExportDocument(from: testItems)
            showingFileExporter = true
        } catch {
            presentAlert(title: "Export Error", message: error.localizedDescription)
        }
    }

    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let firstURL = urls.first else { return }
            do {
                let summary = try ScannerTestSuiteTransferManager.importArchive(
                    from: firstURL,
                    into: modelContext,
                    existingItems: testItems
                )
                presentAlert(title: "Import Successful", message: summary.summaryMessage)
            } catch {
                presentAlert(title: "Import Failed", message: error.localizedDescription)
            }
        case .failure(let error):
            presentAlert(title: "Import Cancelled / Failed", message: error.localizedDescription)
        }
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - List Row Subview (ScannerTestItemRowView)

private struct ScannerTestItemRowView: View {
    let testItem: ScannerTestItem

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(testItem.effectiveTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text("\(testItem.runs.count) Run\(testItem.runs.count == 1 ? "" : "s")")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }

                Text(testItem.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let noteText = testItem.notes ?? testItem.latestRun?.runNotes,
                   !noteText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                    Text(noteText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                runProgressionLine
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbData = testItem.thumbnailData,
           let uiImage = UIImage(data: thumbData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "doc.viewfinder")
                        .foregroundColor(.secondary)
                }
        }
    }

    @ViewBuilder
    private var runProgressionLine: some View {
        let sorted = testItem.sortedRuns
        if sorted.count >= 2,
           let firstRun = sorted.first,
           let latestRun = sorted.last {
            HStack(spacing: 6) {
                Text("R#\(firstRun.runNumber): \(shortAccuracy(for: firstRun))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("R#\(latestRun.runNumber): \(shortAccuracy(for: latestRun))")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(accuracyColor(for: latestRun))
            }
        } else if let latest = testItem.latestRun {
            HStack(spacing: 6) {
                Circle()
                    .fill(accuracyColor(for: latest))
                    .frame(width: 7, height: 7)
                Text("Accuracy: \(latest.accuracyPercentageString)")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func shortAccuracy(for run: ScannerTestRun) -> String {
        guard let ratio = run.accuracyRatio else {
            return "Unverified"
        }
        return "\(Int((ratio * 100.0).rounded()))%"
    }

    private func accuracyColor(for run: ScannerTestRun) -> Color {
        guard let ratio = run.accuracyRatio else { return .orange }
        if ratio >= 0.95 { return .green }
        if ratio >= 0.75 { return .yellow }
        return .red
    }
}

// MARK: - "Re-Run Previous Test" Picker Sheet

private struct PreviousTestSelectorSheet: View {
    let testItems: [ScannerTestItem]
    let isRunningScan: Bool
    let onSelectSingleItem: (ScannerTestItem) -> Void
    let onReRunAllItems: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if testItems.count > 1 {
                    Section {
                        Button {
                            onReRunAllItems()
                        } label: {
                            Label("Re-Run All Saved Tests (\(testItems.count))", systemImage: "bolt.horizontal.circle.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .disabled(isRunningScan)
                    } footer: {
                        Text("Executes the current Vision scanner on every saved lossless image and appends a new unverified test run to each fixture.")
                    }
                }

                Section(header: Text("Select a Previous Test Image to Re-Run")) {
                    ForEach(testItems) { item in
                        Button {
                            onSelectSingleItem(item)
                        } label: {
                            HStack(spacing: 12) {
                                ScannerTestItemRowView(testItem: item)
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isRunningScan)
                    }
                }
            }
            .navigationTitle("Re-Run Previous Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Detail View: Single-Run Verification & Multi-Run Comparison Inspector

struct ScannerTestItemDetailView: View {
    @Bindable var testItem: ScannerTestItem
    var onReRunRequested: (ScannerTestItem) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var selectedRunID: UUID?
    @State private var showingComparisonMatrix = false
    @State private var showingFullScreenImage = false
    @State private var activeColumnIndex: Int? = 0
    @State private var isExactMatchesExpanded = false
    @State private var cachedPreviewImage: UIImage?

    private var sortedRuns: [ScannerTestRun] {
        testItem.sortedRuns
    }

    private var activeRun: ScannerTestRun? {
        if let id = selectedRunID,
           let matched = sortedRuns.first(where: { $0.id == id }) {
            return matched
        }
        return sortedRuns.last
    }

    var body: some View {
        List {
            fixtureHeaderSection
            capturedImageSection

            if sortedRuns.count > 1 {
                modeToggleSection
            }

            if showingComparisonMatrix && sortedRuns.count > 1 {
                ScannerMultiRunComparisonSectionView(
                    testItem: testItem,
                    runs: sortedRuns,
                    onSelectRun: { chosenRun in
                        selectedRunID = chosenRun.id
                        showingComparisonMatrix = false
                    }
                )
            } else if let currentRun = activeRun {
                runStatusSummarySection(for: currentRun)
                digitalLabelVerificationSection(for: currentRun)
                fullSpectrumDiffBreakdownSection(for: currentRun)
                ScannerRunDiagnosticsSectionView(diagnostics: currentRun.diagnosticsSnapshot)
            }
        }
        .navigationTitle(testItem.effectiveTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedRunID == nil {
                selectedRunID = testItem.latestRun?.id
            }
            if cachedPreviewImage == nil {
                cachedPreviewImage = UIImage(data: testItem.originalImageData)
            }
        }
        .onChange(of: testItem.id) { _, _ in
            cachedPreviewImage = UIImage(data: testItem.originalImageData)
        }
        .onChange(of: testItem.runs.count) { _, _ in
            selectedRunID = testItem.latestRun?.id
        }
        .sheet(isPresented: $showingFullScreenImage) {
            FullScreenLabelImageSheet(imageData: testItem.originalImageData, title: testItem.effectiveTitle)
        }
    }

    @ViewBuilder
    private var fixtureHeaderSection: some View {
        Section(header: Text("Test Fixture & Run History")) {
            ScannerFixtureMetadataInputRows(
                itemID: testItem.id,
                initialTitle: testItem.labelTitle,
                initialNotes: testItem.notes ?? "",
                onCommit: { newTitle, newNotes in
                    var changed = false
                    if testItem.labelTitle != newTitle {
                        testItem.labelTitle = newTitle
                        changed = true
                    }
                    let normalizedNotes = newNotes.isEmpty ? nil : newNotes
                    if testItem.notes != normalizedNotes {
                        testItem.notes = normalizedNotes
                        changed = true
                    }
                    if changed {
                        try? modelContext.save()
                    }
                }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sortedRuns) { run in
                        let isSelected = (activeRun?.id == run.id) && !showingComparisonMatrix
                        Button {
                            selectedRunID = run.id
                            showingComparisonMatrix = false
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Run #\(run.runNumber)")
                                    .font(.caption.weight(.bold))
                                Text(run.accuracyPercentageString)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.16))
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        onReRunRequested(testItem)
                    } label: {
                        Label("New Re-Run (#\(testItem.nextRunNumber))", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private var capturedImageSection: some View {
        Section(header: Text("Captured Lossless Label Image")) {
            if let uiImage = cachedPreviewImage ?? UIImage(data: testItem.originalImageData) {
                VStack(spacing: 8) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            showingFullScreenImage = true
                        }

                    Button {
                        showingFullScreenImage = true
                    } label: {
                        Label("Tap to Zoom Full-Resolution Image", systemImage: "magnifyingglass.circle")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } else {
                Text("Unable to decode captured image data.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var modeToggleSection: some View {
        Section {
            Picker("Inspection Mode", selection: $showingComparisonMatrix) {
                Text("Verify Run #\(activeRun?.runNumber ?? 1)").tag(false)
                Text("Compare All \(sortedRuns.count) Runs").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private func runStatusSummarySection(for run: ScannerTestRun) -> some View {
        let snapshot = run.fullSpectrumSnapshot
        let diffs = run.fullSpectrumFieldDiffs
        let discrepanciesCount = diffs.filter { $0.diffKind != .exactMatch }.count

        Section(header: Text("Run #\(run.runNumber) Verification Progress")) {
            HStack {
                Text("Run Timestamp")
                Spacer()
                Text(run.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Evaluated Label Parameters")
                Spacer()
                Text("\(run.verifiedRequiredCount) / \(run.totalRequiredCount) verified")
                    .fontWeight(.semibold)
                    .foregroundColor(run.isFullyVerified ? .green : .orange)
            }

            HStack {
                Text("Full-Spectrum Scan Accuracy")
                Spacer()
                Text(run.accuracyPercentageString)
                    .fontWeight(.bold)
                    .foregroundColor(run.isFullyVerified ? .primary : .secondary)
            }

            if run.runNumber > 1,
               let priorRun = testItem.previousVerifiedFullSpectrumRun(beforeRunNumber: run.runNumber) {
                Button {
                    var updated = snapshot
                    updated.applyVerifiedGroundTruth(from: priorRun.fullSpectrumSnapshot)
                    run.updateFullSpectrumSnapshot(updated)
                    try? modelContext.save()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Auto-Grade Using Verified Ground Truth from Run #\(priorRun.runNumber)")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }

            HStack(spacing: 10) {
                Button {
                    var updated = snapshot
                    updated.isVerifiedComplete.toggle()
                    run.updateFullSpectrumSnapshot(updated)
                    try? modelContext.save()
                } label: {
                    Label(
                        snapshot.isVerifiedComplete
                            ? "Verified Complete (Tap to Re-Open)"
                            : "Confirm Digital Label & Complete Verification",
                        systemImage: snapshot.isVerifiedComplete ? "checkmark.seal.fill" : "checkmark.circle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(snapshot.isVerifiedComplete ? .green : .accentColor)

                if discrepanciesCount > 0 || snapshot.isVerifiedComplete || !snapshot.manuallyVerifiedFieldIDs.isEmpty {
                    Button(role: .destructive) {
                        var updated = snapshot
                        updated.resetToScannedOutput()
                        run.updateFullSpectrumSnapshot(updated)
                        try? modelContext.save()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    @ViewBuilder
    private func digitalLabelVerificationSection(for run: ScannerTestRun) -> some View {
        let snapshot = run.fullSpectrumSnapshot

        Section(
            header: Text("Interactive Digital FDA Label — Run #\(run.runNumber)"),
            footer: Text("Tap any value, serving size, or column header on the digital label to enter its ground-truth correction, or use \"+ Add Nutrient Line\" if the scanner missed a printed row. Then tap \"Confirm Digital Label & Complete Verification\" above.")
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Label Topology")
                            .font(.caption.weight(.semibold))
                        Text("Scanned: \(snapshot.scannedTopology.displayTitle)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker(
                        "Topology",
                        selection: Binding(
                            get: { snapshot.effectiveTopology },
                            set: { newTopo in
                                var updated = run.fullSpectrumSnapshot
                                updated.correctedTopology = (newTopo == updated.scannedTopology) ? nil : newTopo
                                run.updateFullSpectrumSnapshot(updated)
                                try? modelContext.save()
                            }
                        )
                    ) {
                        ForEach(FDALabelTopology.allCases, id: \.self) { topo in
                            Text(topo.displayTitle).tag(topo)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider()

                HStack {
                    Text("FDA Reference Demographic")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Picker(
                        "Demographic",
                        selection: Binding(
                            get: { snapshot.effectiveDemographic },
                            set: { newDemo in
                                var updated = run.fullSpectrumSnapshot
                                updated.correctedDemographic = (newDemo == updated.scannedDemographic) ? nil : newDemo
                                run.updateFullSpectrumSnapshot(updated)
                                try? modelContext.save()
                            }
                        )
                    ) {
                        Text("Adults & Children ≥4 yrs").tag(FDADemographicGroup.adultsAndChildren4OrMoreYears)
                        Text("Infants through 12 mos").tag(FDADemographicGroup.infantsThrough12Months)
                        Text("Children 1–3 yrs").tag(FDADemographicGroup.children1Through3Years)
                        Text("Pregnant & Lactating").tag(FDADemographicGroup.pregnantAndLactatingWomen)
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(.vertical, 4)

            FDADigitalLabelView(
                columns: Binding(
                    get: { run.fullSpectrumSnapshot.editedColumns },
                    set: { newCols in
                        var updated = run.fullSpectrumSnapshot
                        updated.editedColumns = newCols
                        run.updateFullSpectrumSnapshot(updated)
                        try? modelContext.save()
                    }
                ),
                topology: snapshot.effectiveTopology,
                demographic: snapshot.effectiveDemographic,
                isSupplement: snapshot.effectiveTopology == .supplementFacts,
                activeColumnIndex: $activeColumnIndex
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        }
    }

    @ViewBuilder
    private func fullSpectrumDiffBreakdownSection(for run: ScannerTestRun) -> some View {
        let diffs = run.fullSpectrumFieldDiffs
        let discrepancies = diffs.filter { $0.diffKind != .exactMatch }
        let exactMatches = diffs.filter { $0.diffKind == .exactMatch }

        Section(header: Text("Full-Spectrum Grading Breakdown (\(diffs.count) Fields)")) {
            if !discrepancies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        "\(discrepancies.count) Discrepanc\(discrepancies.count == 1 ? "y" : "ies") Recorded (Incorrect / Missed)",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundColor(.red)

                    ForEach(discrepancies) { item in
                        FullSpectrumDiffRowView(
                            item: item,
                            onToggleManualVerification: nil
                        )
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("No discrepancies recorded on the digital label.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }

            DisclosureGroup(
                isExpanded: $isExactMatchesExpanded,
                content: {
                    ForEach(exactMatches) { item in
                        FullSpectrumDiffRowView(
                            item: item,
                            onToggleManualVerification: {
                                var updated = run.fullSpectrumSnapshot
                                if updated.manuallyVerifiedFieldIDs.contains(item.id) {
                                    updated.manuallyVerifiedFieldIDs.remove(item.id)
                                } else {
                                    updated.manuallyVerifiedFieldIDs.insert(item.id)
                                }
                                run.updateFullSpectrumSnapshot(updated)
                                try? modelContext.save()
                            }
                        )
                    }
                },
                label: {
                    HStack {
                        Text("Exact Scanned Matches (\(exactMatches.count))")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        let verifiedCount = exactMatches.filter { $0.verificationStatus == .verifiedCorrect }.count
                        Text("\(verifiedCount)/\(exactMatches.count) verified")
                            .font(.caption)
                            .foregroundColor(verifiedCount == exactMatches.count ? .green : .secondary)
                    }
                }
            )
        }
    }
}

// MARK: - Full-Spectrum Field Diff Row View (Milestone 6.7)

private struct FullSpectrumDiffRowView: View {
    let item: FullSpectrumFieldDiffItem
    let onToggleManualVerification: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            statusIcon

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.fieldTitle)
                        .font(.caption.weight(.semibold))
                    diffBadge
                }

                if item.diffKind == .exactMatch {
                    Text("Scanned: \(item.scannedDisplayValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Text("Scanned: \(item.scannedDisplayValue)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("Truth: \(item.groundTruthDisplayValue)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.primary)
                    }
                }
            }

            Spacer()

            if let toggleAction = onToggleManualVerification {
                Button {
                    toggleAction()
                } label: {
                    Text(item.verificationStatus == .verifiedCorrect ? "Verified" : "Verify")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            item.verificationStatus == .verifiedCorrect
                                ? Color.green.opacity(0.18)
                                : Color.gray.opacity(0.15)
                        )
                        .foregroundColor(item.verificationStatus == .verifiedCorrect ? .green : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.verificationStatus {
        case .verifiedCorrect:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)
        case .verifiedIncorrect:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.subheadline)
        case .unverified:
            Image(systemName: "circle.dashed")
                .foregroundColor(.orange)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private var diffBadge: some View {
        if item.diffKind != .exactMatch {
            Text(item.diffKind.badgeTitle)
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.14))
                .foregroundColor(.red)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Read-Only Optical & Internal Pipeline Telemetry Section

private struct ScannerRunDiagnosticsSectionView: View {
    let diagnostics: ScanDiagnosticsSnapshot

    var body: some View {
        Section(header: Text("Optical & Physical Capture Telemetry (Read-Only)")) {
            telemetryRow(
                title: "labelResolution",
                value: diagnostics.opticalTelemetry.resolutionSummary,
                isWarning: diagnostics.opticalTelemetry.medianLinePixelHeight > 0
                    && diagnostics.opticalTelemetry.medianLinePixelHeight < 13.0
            )
            telemetryRow(
                title: "labelLighting",
                value: diagnostics.opticalTelemetry.lightingSummary,
                isWarning: diagnostics.opticalTelemetry.lightingClassification != .balanced
            )
            telemetryRow(
                title: "photoAngle",
                value: diagnostics.opticalTelemetry.photoAngleSummary,
                isWarning: diagnostics.opticalTelemetry.estimatedPerspectiveAngleDegrees > 25.0
            )
            telemetryRow(
                title: "labelSharpness",
                value: diagnostics.opticalTelemetry.sharpnessSummary,
                isWarning: diagnostics.opticalTelemetry.isLikelyBlurred
            )
            telemetryRow(
                title: "labelCurvature",
                value: diagnostics.opticalTelemetry.curvatureSummary,
                isWarning: diagnostics.opticalTelemetry.isCurvedSurfaceLikely
            )
        }

        Section(header: Text("Internal Vision & Validator Pipeline Telemetry")) {
            telemetryRow(
                title: "estimatedAccuracy (Combined)",
                value: "\(Int((diagnostics.estimatedAccuracy * 100.0).rounded()))%"
            )
            telemetryRow(
                title: "Vision OCR Confidence",
                value: String(format: "%.1f%%", diagnostics.visionConfidence * 100.0)
            )
            telemetryRow(
                title: "FDA Validator Confidence",
                value: String(format: "%.1f%%", diagnostics.validatorConfidence * 100.0)
            )
            telemetryRow(
                title: "labelPhotoSkew",
                value: String(format: "%.2f° (slope %.4f)", diagnostics.labelSkewDegrees, diagnostics.labelSkewSlope),
                isWarning: abs(diagnostics.labelSkewDegrees) > 8.0
            )
            telemetryRow(
                title: "Extraction Path",
                value: diagnostics.extractionPath.rawValue
            )
            telemetryRow(
                title: "Resolved Topology",
                value: diagnostics.resolvedTopology.displayTitle
            )
            telemetryRow(
                title: "Structural / Lexical Topology",
                value: "\(diagnostics.structuralTopology.rawValue) / \(diagnostics.lexicalTopology.rawValue)"
            )
            telemetryRow(
                title: "Atwater Calorie Check",
                value: diagnostics.atwaterCalorieCheckPassed
                    ? "Passed (\(diagnostics.expectedAtwaterMinCalories)–\(diagnostics.expectedAtwaterMaxCalories) kcal)"
                    : "Mismatch (Expected \(diagnostics.expectedAtwaterMinCalories)–\(diagnostics.expectedAtwaterMaxCalories) kcal)",
                isWarning: !diagnostics.atwaterCalorieCheckPassed
            )
            telemetryRow(
                title: "% DV Healed Nutrients",
                value: diagnostics.healedNutrients.isEmpty
                    ? "None"
                    : diagnostics.healedNutrients.map(\.rawValue).joined(separator: ", ")
            )
            telemetryRow(
                title: "Filtered Warnings / Decoys",
                value: "\(diagnostics.discardedWarningCount) warning box(es), \(diagnostics.discardedDecoyCount) decoy string(s)"
            )

            if !diagnostics.diagnostics.isEmpty {
                DisclosureGroup("Validator Diagnostics (\(diagnostics.diagnostics.count))") {
                    ForEach(Array(diagnostics.diagnostics.enumerated()), id: \.offset) { _, diag in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("[\(diag.severity.rawValue.uppercased())] \(diag.code)")
                                .font(.caption2.weight(.bold))
                            Text(diag.message)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .font(.caption)
            }

            DisclosureGroup("Extracted Nutrition Rows (\(diagnostics.extractedRowLines.count))") {
                if diagnostics.extractedRowLines.isEmpty {
                    Text("No isolated nutrition rows recorded.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(diagnostics.extractedRowLines.enumerated()), id: \.offset) { idx, rowLine in
                        Text("\(idx + 1). \(rowLine)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
            }
            .font(.caption)

            DisclosureGroup("Raw Scanned OCR Lines (\(diagnostics.rawLabelLines.count))") {
                ForEach(Array(diagnostics.rawLabelLines.enumerated()), id: \.offset) { idx, line in
                    Text("\(idx + 1). \(line)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
        }
    }

    @ViewBuilder
    private func telemetryRow(title: String, value: String, isWarning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(isWarning ? .orange : .primary)
        }
        .padding(.vertical, 1)
    }
}

// MARK: - Sequential Multi-Run Comparison Matrix Section

private struct ScannerMultiRunComparisonSectionView: View {
    let testItem: ScannerTestItem
    let runs: [ScannerTestRun]
    let onSelectRun: (ScannerTestRun) -> Void

    private struct ComparisonFieldDescriptor: Identifiable {
        let id: String
        let title: String
        let targetTruth: String?
    }

    private var comparisonFields: [ComparisonFieldDescriptor] {
        var seen: Set<String> = []
        var ordered: [ComparisonFieldDescriptor] = []

        let verifiedPriorRun = testItem.previousVerifiedFullSpectrumRun(beforeRunNumber: Int.max)
        let priorTruthByID: [String: String] = {
            guard let vr = verifiedPriorRun else { return [:] }
            var map: [String: String] = [:]
            for diff in vr.fullSpectrumFieldDiffs where diff.verificationStatus.isVerified {
                map[diff.id] = diff.groundTruthDisplayValue
            }
            return map
        }()

        for run in runs.reversed() {
            for diff in run.fullSpectrumFieldDiffs {
                if seen.insert(diff.id).inserted {
                    ordered.append(
                        ComparisonFieldDescriptor(
                            id: diff.id,
                            title: diff.fieldTitle,
                            targetTruth: priorTruthByID[diff.id]
                        )
                    )
                }
            }
        }
        return ordered
    }

    var body: some View {
        Section(header: Text("Sequential Run Accuracy Summary")) {
            ForEach(runs) { run in
                Button {
                    onSelectRun(run)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Run #\(run.runNumber)")
                                .font(.subheadline.weight(.semibold))
                            Text(run.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(run.accuracyPercentageString)
                            .font(.caption.weight(.bold))
                            .foregroundColor(run.isFullyVerified ? .primary : .orange)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }

        Section(header: Text("Full-Spectrum Parameter Sequential Comparison")) {
            ForEach(comparisonFields) { descriptor in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(descriptor.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if let groundTruth = descriptor.targetTruth {
                            Text("Target: \(groundTruth)")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(runs) { run in
                                let matchedDiff = run.fullSpectrumFieldDiffs.first(where: { $0.id == descriptor.id })
                                let st = matchedDiff?.verificationStatus ?? .unverified
                                let scannedText = matchedDiff?.scannedDisplayValue ?? "—"
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("R#\(run.runNumber)")
                                            .font(.caption2.weight(.bold))
                                        statusBadge(for: st)
                                    }
                                    Text(scannedText)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(badgeBackgroundColor(for: st))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for status: ParameterVerificationStatus) -> some View {
        switch status {
        case .unverified:
            Image(systemName: "questionmark.circle")
                .font(.caption2)
                .foregroundColor(.orange)
        case .verifiedCorrect:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.green)
        case .verifiedIncorrect:
            Image(systemName: "xmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.red)
        }
    }

    private func badgeBackgroundColor(for status: ParameterVerificationStatus) -> Color {
        switch status {
        case .unverified:
            return Color.orange.opacity(0.12)
        case .verifiedCorrect:
            return Color.green.opacity(0.12)
        case .verifiedIncorrect:
            return Color.red.opacity(0.12)
        }
    }
}

// MARK: - Full-Screen Pinch-to-Zoom Label Image Sheet

private struct FullScreenLabelImageSheet: View {
    let imageData: Data
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var currentZoom: CGFloat = 1.0
    @State private var totalZoom: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: geo.size.width * max(1.0, totalZoom * currentZoom),
                                height: geo.size.height * max(1.0, totalZoom * currentZoom)
                            )
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        currentZoom = value.magnification
                                    }
                                    .onEnded { value in
                                        totalZoom = min(max(1.0, totalZoom * value.magnification), 5.0)
                                        currentZoom = 1.0
                                    }
                            )
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset Zoom") {
                        totalZoom = 1.0
                        currentZoom = 1.0
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Debounced Fixture Title & Notes Input Rows

private struct ScannerFixtureMetadataInputRows: View {
    let itemID: UUID
    let initialTitle: String
    let initialNotes: String
    var onCommit: (String, String) -> Void

    @State private var draftTitle: String = ""
    @State private var draftNotes: String = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case notes
    }

    var body: some View {
        Group {
            HStack {
                Text("Fixture Title")
                Spacer()
                TextField("e.g. Chobani Greek Yogurt", text: $draftTitle)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .title)
                    .onSubmit {
                        onCommit(draftTitle, draftNotes)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField(
                    "Add notes specific and pertinent to this scan...",
                    text: $draftNotes,
                    axis: .vertical
                )
                .font(.subheadline)
                .lineLimit(2...5)
                .focused($focusedField, equals: .notes)
            }
        }
        .onAppear {
            draftTitle = initialTitle
            draftNotes = initialNotes
        }
        .onChange(of: itemID) { _, _ in
            draftTitle = initialTitle
            draftNotes = initialNotes
        }
        .onChange(of: focusedField) { _, newFocus in
            if newFocus == nil {
                onCommit(draftTitle, draftNotes)
            }
        }
        .task(id: "\(draftTitle)|\(draftNotes)") {
            guard draftTitle != initialTitle || draftNotes != initialNotes else { return }
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            onCommit(draftTitle, draftNotes)
        }
        .onDisappear {
            if draftTitle != initialTitle || draftNotes != initialNotes {
                onCommit(draftTitle, draftNotes)
            }
        }
    }
}
