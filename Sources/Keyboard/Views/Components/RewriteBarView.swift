import SwiftUI

struct RewriteBarView: View {
    @Binding var state: KeyboardState
    var onApply: () -> Void

    var body: some View {
        if let rewrite = state.bestRewrite, rewrite != state.currentText {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Better version available")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(rewrite)
                        .font(.subheadline)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onApply) {
                    Text("Apply")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]), startPoint: .leading, endPoint: .trailing))
        }
    }
}
