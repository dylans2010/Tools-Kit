import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var isEnabled: Bool = true
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Message", text: $text)
                .textFieldStyle(.roundedBorder)
                .disabled(!isEnabled)
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isEnabled || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
