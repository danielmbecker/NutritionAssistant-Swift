import SwiftUI

struct SingleFoodMetricDisplayView: View {
    let title: String
    let valueText: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(valueText)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SingleFoodMetricDisplayView(title: "Protein", valueText: "145g", color: .red)
        .padding()
}
