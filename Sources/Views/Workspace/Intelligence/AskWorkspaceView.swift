import SwiftUI

struct AskWorkspaceView: View {
    @StateObject private var ai = AIOrchestrator.shared
    @State private var prompt = ""
    @State private var responses: [Message] = []

    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(responses) { msg in
                        HStack {
                            if msg.isUser { Spacer() }
                            Text(msg.text)
                                .padding()
                                .background(msg.isUser ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            if !msg.isUser { Spacer() }
                        }
                    }
                }
                .padding()
            }

            HStack {
                TextField("Ask anything...", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    sendMessage()
                }
            }
            .padding()
        }
        .navigationTitle("Ask Workspace")
    }

    private func sendMessage() {
        let userMsg = Message(text: prompt, isUser: true)
        responses.append(userMsg)
        let currentPrompt = prompt
        prompt = ""

        Task {
            let responseText = await ai.query(prompt: currentPrompt)
            responses.append(Message(text: responseText, isUser: false))
        }
    }
}
