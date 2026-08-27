import SwiftUI

struct NavigationCategory<ID: Hashable>: Identifiable {
    var id: ID
    var label: String
    var iconName: String
}

struct IconNavigationHelper<ID: Hashable>: View {
    let categories: [NavigationCategory<ID>]
    let onSelect: (ID) -> Void
    
    var body: some View {
        let midpoint = (categories.count + 1) / 2
        let topRow = Array(categories.prefix(midpoint))
        let bottomRow = Array(categories.suffix(categories.count - midpoint))
        
        VStack(spacing: 16) {
            iconRow(for: topRow)
            
            if !bottomRow.isEmpty {
                iconRow(for: bottomRow)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    private func iconRow(for rowCategories: [NavigationCategory<ID>]) -> some View {
        HStack {
            ForEach(rowCategories) { category in
                Button(action: {
                    onSelect(category.id)
                }) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                if category.id != rowCategories.last?.id {
                    Spacer()
                }
            }
        }
    }
}
