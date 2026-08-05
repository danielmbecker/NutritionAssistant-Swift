import SwiftUI

struct SuffixTextField: View {
    @Binding var value: Int?
    let suffix: String
    
    var body: some View {
        HStack(spacing: 2) {
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
            
            Text(suffix)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .frame(width: 65)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(UIColor.opaqueSeparator), lineWidth: 1)
        )
    }
}
