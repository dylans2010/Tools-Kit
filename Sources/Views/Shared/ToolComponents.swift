import SwiftUI

// MARK: - ToolInputSection

struct ToolInputSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(.primary)

            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - ToolOutputView

struct ToolOutputView: View {
    let title: String
    let text: String
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: { UIPasteboard.general.string = text }) {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(text.isEmpty || isLoading)
            }

            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 80)
                    .overlay(ProgressView())
            } else {
                ScrollView {
                    Text(text.isEmpty ? "Output will appear here" : text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(text.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(minHeight: 80, maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - ToolStateView

struct ToolStateView: View {
    enum State {
        case empty(String)
        case error(String)
        case loading
    }

    let state: State

    var body: some View {
        VStack(spacing: 12) {
            switch state {
            case .empty(let message):
                Image(systemName: "tray")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

            case .error(let message):
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text(message)
                    .font(.callout)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)

            case .loading:
                ProgressView()
                Text("Loading…")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
