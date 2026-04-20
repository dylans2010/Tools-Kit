import SwiftUI

struct FeedbackSuccessView: View {
    let onSubmitAnother: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text("Feedback Submitted")
                .font(.title3.bold())

            Text("Thanks for helping improve ToolsKit.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Submit Another", action: onSubmitAnother)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
