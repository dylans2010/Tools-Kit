import SwiftUI

struct MessagesAIHomeView: View {
    var onSelectTool: (PayloadSubtype) -> Void

    var body: some View {
        List {
            Section("AI Tools") {
                Button(action: { onSelectTool(.rewrite) }) {
                    Label("Text Rewrite", systemImage: "pencil.and.outline")
                }
                Button(action: { onSelectTool(.summarize) }) {
                    Label("Summarization", systemImage: "text.alignleft")
                }
                Button(action: { onSelectTool(.reply) }) {
                    Label("Quick Reply", systemImage: "arrowshape.turn.up.left")
                }
            }
        }
    }
}
