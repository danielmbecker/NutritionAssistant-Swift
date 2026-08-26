import SwiftUI
import Charts

struct FractionSelectionView: View {
    @Binding var sections: Int
    
    private var gridConfig: (columns: [GridItem], size: CGFloat) {
        let cols: Int
        let size: CGFloat
        let spacing: CGFloat = 4
        
        switch sections {
        case 2: cols = 2; size = 56 // 120 / 2 minus spacing
        case 3: cols = 3; size = 37 // 120 / 3 minus spacing
        case 4...6: cols = 3; size = 30
        case 7...8: cols = 4; size = 23
        case 9...10: cols = 5; size = 18
        case 11...12: cols = 6; size = 15
        case 13...20: cols = 5; size = 12
        case 21...25: cols = 5; size = 10
        case 26...30: cols = 6; size = 7
        default: cols = 6; size = 7
        }
        
        let gridItems = Array(repeating: GridItem(.fixed(size), spacing: spacing), count: cols)
        return (gridItems, size)
    }
    
    private var percentageValue: Double {
        if sections < 0 {
            return (1.0 / Double(abs(sections))) * 100.0
        } else {
            return Double(sections) * 100.0
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(sections <= -2 ? "\(abs(sections)) servings per recipe" : "Recipe makes \(abs(sections)) servings")
                .font(.headline)
                
            HStack(spacing: 20) {
                // Conditional rendering based on sections value
            if sections < 0 {
                Chart(0..<abs(sections), id: \.self) { index in
                    SectorMark(
                        angle: .value("Section", 1.0),
                        innerRadius: .ratio(0),
                        angularInset: 1
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .frame(width: 120, height: 120)
            } else {
                let config = gridConfig
                LazyVGrid(columns: config.columns, spacing: 4) {
                    ForEach(0..<sections, id: \.self) { index in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: config.size, height: config.size)
                    }
                }
                .frame(width: 120, height: 120)
            }
            
            // Buttons to add/remove sections
            VStack(spacing: 16) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        
                  
                        
                        if sections < -1 {
                            sections += 1
                        } else if sections == -1 {
                            sections = 2 // jump to 2 circles
                        } else if sections >= 2 && sections < 30 {
                            sections += 1
                        }
                        print(sections)
                        
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .frame(width: 44, height: 32)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        
                        
                        
                        if sections > 2 {
                            sections -= 1
                        } else if sections == 2 {
                            sections = -1 // back to 1 whole pie chart
                        } else if sections < 0 {
                            sections -= 1
                        }
                        print(sections)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.title3.weight(.bold))
                        .frame(width: 44, height: 32)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            
        } // Closes HStack(spacing: 20)
//        
//        HStack {
//            Text("Multiplier equivalent:")
//                .foregroundColor(.secondary)
//            Spacer()
//            Text(String(format: "%.1f%%", percentageValue))
//                .fontWeight(.semibold)
//        }
//        
        } // Closes VStack
        .padding()
    }
}

#Preview {
    FractionSelectionView(sections: .constant(-4))
}
