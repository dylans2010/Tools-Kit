import SwiftUI

struct CodeBlockView: View {
    @Binding var block: NotebookBlock
    var onUpdate: () -> Void

    @State private var isExecuting = false
    @State private var executionResult: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $block.content)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 80)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: block.content) { _, _ in onUpdate() }

            HStack {
                Button {
                    simulateExecution()
                } label: {
                    Label(isExecuting ? "Running..." : "Run Code", systemImage: "play.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .disabled(isExecuting)

                Spacer()
            }

            if let result = executionResult {
                Text(result)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func simulateExecution() {
        isExecuting = true
        executionResult = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isExecuting = false
            executionResult = "Output: 42\nProcess finished with exit code 0"
        }
    }
}
