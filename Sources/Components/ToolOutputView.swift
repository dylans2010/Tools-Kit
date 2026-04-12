import SwiftUI

struct ToolOutputView: View {
    let title: String
    let value: String
    let icon: String?

    init(_ title: String, value: String, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            HStack(spacing: 16) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.body.monospaced())
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }

                Spacer()

                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}
