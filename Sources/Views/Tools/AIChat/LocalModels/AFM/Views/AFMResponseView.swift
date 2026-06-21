import SwiftUI

struct AFMResponseView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(.body)
                .textSelection(.enabled)

            HStack {
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = text
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 5)
    }
}
