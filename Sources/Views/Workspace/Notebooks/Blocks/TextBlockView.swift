import SwiftUI

struct TextBlockView: View {
    @Binding var block: NotebookBlock
    var onUpdate: () -> Void

    var body: some View {
        TextEditor(text: $block.content)
            .font(.body)
            .frame(minHeight: 40)
            .fixedSize(horizontal: false, vertical: true)
            .scrollContentBackground(.hidden)
            .onChange(of: block.content) { _, _ in onUpdate() }
    }
}
