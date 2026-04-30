import SwiftUI

struct EmbedBlockView: View {
    @Binding var block: NotebookBlock
    var onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "link.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Title", text: $block.content)
                        .font(.headline)
                    TextField("URL", text: Binding(
                        get: { block.metadata["url"] ?? "" },
                        set: { block.metadata["url"] = $0 }
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .onChange(of: block.content) { _ in onUpdate() }
            .onChange(of: block.metadata["url"]) { _ in onUpdate() }
        }
    }
}
