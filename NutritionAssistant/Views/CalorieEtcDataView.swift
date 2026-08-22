import SwiftUI

struct CalorieEtcDataView: View {
    let calories: Int
    let carbs: Double
    let protein: Double
    let fat: Double
    
    var body: some View {
        HStack(spacing: 0) {
            SingleFoodMetricDisplayView(
                title: "Calories",
                valueText: "\(calories)",
                color: .primary
            )
            
            SingleFoodMetricDisplayView(
                title: "Carbs",
                valueText: "\(String(format: "%.0f", carbs))g",
                color: .accentColor
            )
            
            SingleFoodMetricDisplayView(
                title: "Protein",
                valueText: "\(String(format: "%.0f", protein))g",
                color: .red
            )
            
            SingleFoodMetricDisplayView(
                title: "Fat",
                valueText: "\(String(format: "%.0f", fat))g",
                color: .orange
            )
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        CalorieEtcDataView(calories: 2150, carbs: 250, protein: 145, fat: 65)
            .padding()
    }
}
