import SwiftUI

struct CodeAssistantView: View {
    @State private var code = ""
    @State private var suggestion = ""

    var body: some View {
        VStack {
            TextEditor(text: $code)
                .font(.system(.body, design: .monospaced))
                .border(Color.gray.opacity(0.2))
                .padding()

            if !suggestion.isEmpty {
                VStack(alignment: .leading) {
                    Text("AI Suggestion:").font(.caption.bold())
                    Text(suggestion).padding().background(Color.blue.opacity(0.05)).cornerRadius(8)
                }
                .padding(.horizontal)
            }

            Button("Get AI Fix") {
                Task {
                    suggestion = await AICodeAssistantManager.shared.suggestFix(for: code)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("AI Code Assistant")
    }
}
