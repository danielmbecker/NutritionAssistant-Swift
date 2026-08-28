import SwiftUI
import SwiftData

struct HealthKitDashboardView: View {
    var healthKitManager = HealthKitManager.shared
    @Query private var userSettingsList: [UserSettings]
    
    var body: some View {
        HStack {
            Spacer()
            
            // Total Calories
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("\(healthKitManager.totalBurnedEnergy, specifier: "%.0f")")
                    .font(.headline)
                Text("Total Cals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Active Calories
            VStack(spacing: 8) {
                Image(systemName: "figure.highintensity.intervaltraining")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("\(healthKitManager.activeEnergyBurned, specifier: "%.0f")")
                    .font(.headline)
                Text("Active Cals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Step Count
            VStack(spacing: 8) {
                Image(systemName: "shoeprints.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("\(healthKitManager.totalSteps, specifier: "%.0f")")
                    .font(.headline)
                Text("Steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            // A slight delay prevents the Simulator's HealthPrivacyService from timing out
            // when attempting to present the modal immediately upon app launch.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let customWindow = userSettingsList.first?.healthKitCustomDayWindow ?? false
                let startHour = userSettingsList.first?.dayStartHour ?? 0
                
                if !healthKitManager.isAuthorized {
                    healthKitManager.requestAuthorization(customWindowEnabled: customWindow, startHour: startHour)
                } else {
                    healthKitManager.fetchAllData(customWindowEnabled: customWindow, startHour: startHour)
                }
            }
        }
    }
}

#Preview {
    HealthKitDashboardView()
}
