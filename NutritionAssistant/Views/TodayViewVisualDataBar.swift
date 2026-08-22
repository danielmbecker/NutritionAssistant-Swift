import SwiftUI
import SwiftData

struct TodayViewVisualDataBar: View {
    let calories: Int
    let carbs: Double
    let protein: Double
    let fat: Double

    @Query private var userSettingsList: [UserSettings]
    
    private var calorieGoal: Double { Double(userSettingsList.first?.userCaloriesGoal ?? 2000) }
    private var fatGoal: Double { Double(userSettingsList.first?.userFatGoal ?? 80) }
    private var proteinGoal: Double { Double(userSettingsList.first?.userProteinGoal ?? 110) }
    private var carbGoal: Double { Double(userSettingsList.first?.userCarbGoal ?? 210) }

    private enum NC {
        static let calories = Color.gray
        static let fat      = Color(hex: "#FDE4BE")
        static let protein  = Color(hex: "#E4BEFD")
        static let carbs    = Color(hex: "#BEFDE4")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ── Top: Full-width Calories progress bar & labels ───────────────
            MacroColumnView(
                name: "Calories",
                value: Double(calories),
                goal: calorieGoal,
                color: NC.calories,
                unit: "kcal",
                textAbove: true
            )
            
            // ── Bottom: Parallel macro progress bars & labels ──────────────────
            HStack(spacing: 12) {
                MacroColumnView(name: "Fat", value: fat, goal: fatGoal, color: NC.fat)
                MacroColumnView(name: "Protein", value: protein, goal: proteinGoal, color: NC.protein)
                MacroColumnView(name: "Carbs", value: carbs, goal: carbGoal, color: NC.carbs)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 1)
    }
}

private struct MacroColumnView: View {
    let name: String
    let value: Double
    let goal: Double
    let color: Color
    var unit: String = "g"
    var textAbove: Bool = false
    
    @State private var showingGoal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if textAbove {
                labels
            }
            
            MacroProgressBar(value: value, goal: goal, color: color)
                .frame(height: 8)
            
            if !textAbove {
                labels
            }
        }
        .contentShape(Rectangle()) // Make the whole column tappable
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingGoal = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingGoal = false
                }
            }
        }
    }
    
    private var labels: some View {
        HStack(spacing: 4) {
            Text(showingGoal ? "Goal:" : name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            let displayValue = showingGoal ? goal : value
            
            // For calories over 1000, we might want a comma, but Int(displayValue) is fine
            // Let's format it properly if needed, but for now we'll stick to simple Int conversion
            // or we can use a formatter.
            Text("\(formatValue(displayValue))\(unit)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
                .contentTransition(.numericText())
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        let n = Int(val.rounded())
        return n >= 1000 ? "\(n / 1000),\(String(format: "%03d", n % 1000)) " : "\(n)"
    }
}

private struct MacroProgressBar: View {
    let value: Double
    let goal:  Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(color.opacity(0.15))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Primary fill (capped at 100%)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * max(0, min(value / max(goal, 1), 1.0)))
                
                // Over-goal fill (visualizes excess, drawn on top)
                if value > goal {
                    let excessRatio = (value - goal) / max(goal, 1)
                    let cappedExcessRatio = max(0, min(excessRatio, 1.0))
                    
                    ZStack {
                        Capsule().fill(color)
                        // Adding a white overlay perfectly mathematically brightens the base color
                        Capsule().fill(Color.white.opacity(0.6))
                    }
                    .frame(width: geo.size.width * cappedExcessRatio)
                    // Added shadow to create depth and separate it from the underlying base bar
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 0)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        TodayViewVisualDataBar(
            calories: 1798,
            carbs: 35,
            protein: 265,
            fat: 61
        )
        .padding()
    }
}
