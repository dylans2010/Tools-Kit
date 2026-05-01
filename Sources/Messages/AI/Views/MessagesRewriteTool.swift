import SwiftUI

struct MessagesRewriteTool: View {
    @State private var input = ""
    @State private var tone = "Professional"
    @State private var mode = "Clear"
    @State private var result: AIResult?
    @State private var isLoading = false

    var onSend: (AIResult) -> Void

    var body: some View {
        Form {
            Section("Input Text") {
                TextEditor(text: $input)
                    .frame(height: 100)
            }

            Section("Options") {
                Picker("Tone", selection: $tone) {
                    Text("Professional").tag("Professional")
                    Text("Friendly").tag("Friendly")
                    Text("Urgent").tag("Urgent")
                }
                Picker("Mode", selection: $mode) {
                    Text("Clear").tag("Clear")
                    Text("Concise").tag("Concise")
                    Text("Detailed").tag("Detailed")
                }
            }

            Button("Generate Rewrite") {
                generate()
            }
            .disabled(input.isEmpty || isLoading)

            if isLoading {
                ProgressView()
            }

            if let result = result {
                Section("Result") {
                    Text(result.output)
                    Button("Send to Chat") {
                        onSend(result)
                    }
                }
            }
        }
        .navigationTitle("Rewrite")
    }

    private func generate() {
        isLoading = true
        let request = MessagesAIRequest(input: input, subtype: .rewrite, parameters: ["tone": tone, "mode": mode])
        Task {
            do {
                result = try await MessagesAIService.shared.process(request: request)
            } catch {
                print("AI Error: \(error)")
            }
            isLoading = false
        }
    }
}
