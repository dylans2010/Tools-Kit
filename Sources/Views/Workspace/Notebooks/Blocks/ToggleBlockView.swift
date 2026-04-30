import SwiftUI

struct ToggleBlockView: View {
    @Binding var block: NotebookBlock
    var onUpdate: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                TextField("Toggle Title", text: $block.content)
                    .font(.body.weight(.semibold))
                    .onChange(of: block.content) { _ in onUpdate() }

                Spacer()
            }

            if isExpanded {
                TextEditor(text: Binding(
                    get: { block.metadata["details"] ?? "" },
                    set: { block.metadata["details"] = $0 }
                ))
                .font(.body)
                .frame(minHeight: 40)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 24)
                .onChange(of: block.metadata["details"]) { _ in onUpdate() }
            }
        }
    }
}
