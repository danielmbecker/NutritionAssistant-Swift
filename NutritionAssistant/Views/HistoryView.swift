import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "clock")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text("History features coming soon!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("History")
        }
    }
}
