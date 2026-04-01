import SwiftUI

struct Base64View: View {
    @StateObject private var backend = Base64Backend()

    var body: some View {
        VStack {
            TextEditor(text: $backend.inputText)
                .frame(maxHeight: 200)
                .border(Color.gray, width: 1)
                .padding()

            HStack {
                Button("Encode") { backend.encode() }
                Button("Decode") { backend.decode() }
            }
            .buttonStyle(.borderedProminent)

            TextEditor(text: .constant(backend.outputText))
                .frame(maxHeight: 200)
                .border(Color.blue, width: 1)
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("Base64 Encoder/Decoder")
    }
}

struct Base64Tool: Tool {
    let name = "Base64 Tool"
    let icon = "lock.open"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Encode and decode Base64 strings"
    let requiresAPI = false

    var view: AnyView {
        AnyView(Base64View())
    }
}
