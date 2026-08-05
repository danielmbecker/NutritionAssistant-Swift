import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsList: [UserSettings]
    @AppStorage("dayStartHour") private var dayStartHour: Int = 0
    
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        // NEW: This explicitly creates perfectly safe bindings for the compiler
        @Bindable var bindableViewModel = viewModel
        
        List {
            Section(
                header: Text("Time Preferences"),
                footer: Text("Set the time your day resets. Any food logged before this time will be grouped with the previous day.")
            ) {
                Picker("Day Start Time", selection: $dayStartHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(timeString(for: hour)).tag(hour)
                    }
                }
            }
            
            Section(header: Text("Goal Values")) {
                
                CalorieAndMacroSectionView(
                    // We use the bindable variable for the inputs
                    calorieInput: $bindableViewModel.calorieInput,
                    fatInput: $bindableViewModel.fatInput,
                    carbInput: $bindableViewModel.carbInput,
                    proteinInput: $bindableViewModel.proteinInput,
                    
                    // We use the standard variable for the function calls
                    onSaveCalories: { viewModel.saveCalorieAndMacros(settingsList: userSettingsList) },
                    onSaveMacros: { viewModel.saveMacroGoal(settingsList: userSettingsList) }
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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.initializeSettingsIfNeeded(settingsList: userSettingsList, context: modelContext)
        }
    }
    
    // MARK: - View Helpers
    
    private func timeString(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
