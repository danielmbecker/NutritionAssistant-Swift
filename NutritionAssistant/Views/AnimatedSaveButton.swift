import SwiftUI

struct AnimatedSaveButton: View {
    let action: () -> Void
    @State private var isSaved = false
    
    var body: some View {
        Button(action: {
            action()
            // Triggers a smooth pop and color change
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isSaved = true
            }
            // Reverts the button back after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSaved = false
                }
            }
        }) {
            HStack(spacing: 4) {
                if isSaved {
                    Image(systemName: "checkmark")
                        .transition(.scale.combined(with: .opacity))
                }
                Text("Save")
            }
            .font(.caption)
            .fontWeight(.bold)
        }
        .buttonStyle(.borderedProminent)
        .tint(isSaved ? .green : .blue)
    }
}
