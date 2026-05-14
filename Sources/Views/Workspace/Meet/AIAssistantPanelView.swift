import SwiftUI

struct AIAssistantPanelView: View {
    let notes: String
    let onSummarize: () -> Void
    let onExtractActionItems: () -> Void
    let onRewrite: () -> Void
    let result: String
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI Assistant")
                .font(.headline)
            HStack(spacing: 8) {
                Button("Summarize", action: onSummarize)
                    .buttonStyle(.bordered)
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                Button("Action Items", action: onExtractActionItems)
                    .buttonStyle(.bordered)
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                Button("Rewrite", action: onRewrite)
                    .buttonStyle(.bordered)
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }

            if isLoading {
                Text("AI Is Processing…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !result.isEmpty && !isLoading {
                ScrollView {
                    Text(result)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .aiAnimationLoading(isLoading)
    }
}
