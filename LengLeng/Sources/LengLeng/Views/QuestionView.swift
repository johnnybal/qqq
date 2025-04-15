import SwiftUI

struct QuestionView: View {
    var body: some View {
        List {
            ForEach(0..<5) { index in
                VStack(alignment: .leading) {
                    Text("Question \(index + 1)")
                        .font(.headline)
                    Text("Sample question description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }
} 