import SwiftUI

struct MessagesReplyGenerator: View {
    @State private var context = ""
    @State private var result: AIResult?
    @State private var isLoading = false

    var onSend: (AIResult) -> Void

    var body: some View {
        Form {
            Section("Message Context") {
                TextEditor(text: $context)
                    .frame(height: 100)
            }

            Button("Generate Reply") {
                generate()
            }
            .disabled(context.isEmpty || isLoading)

            if isLoading {
                ProgressView()
            }

            if let result = result {
                Section("Suggested Reply") {
                    Text(result.output)
                    Button("Send to Chat") {
                        onSend(result)
                    }
                }
            }
        }
        .navigationTitle("Quick Reply")
    }

    private func generate() {
        isLoading = true
        let request = MessagesAIRequest(input: context, subtype: .reply)
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
