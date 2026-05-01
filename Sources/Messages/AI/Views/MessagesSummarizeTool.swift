import SwiftUI

struct MessagesSummarizeTool: View {
    @State private var input = ""
    @State private var result: AIResult?
    @State private var isLoading = false

    var onSend: (AIResult) -> Void

    var body: some View {
        Form {
            Section("Long Text") {
                TextEditor(text: $input)
                    .frame(height: 150)
            }

            Button("Summarize") {
                generate()
            }
            .disabled(input.isEmpty || isLoading)

            if isLoading {
                ProgressView()
            }

            if let result = result {
                Section("Summary") {
                    Text(result.output)
                    Button("Send to Chat") {
                        onSend(result)
                    }
                }
            }
        }
        .navigationTitle("Summarize")
    }

    private func generate() {
        isLoading = true
        let request = MessagesAIRequest(input: input, subtype: .summarize)
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
