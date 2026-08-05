import SwiftUI

struct GoalRowView: View {
    let title: String
    @Binding var value: Int?
    let suffix: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.headline)
            Spacer()
            SuffixTextField(value: $value, suffix: suffix)
            
            // NEW: Using our beautifully animated button
            AnimatedSaveButton(action: action)
        }
        .padding(.vertical, 4)
    }
}
