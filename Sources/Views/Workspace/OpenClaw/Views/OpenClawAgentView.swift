import SwiftUI

struct OpenClawAgentView: View {
    @State private var prompt = ""
    @State private var messages: [String] = []
    @State private var isRunning = false
    @State private var sessionId: String?

    let service: OpenClawGatewayService

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(messages, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                TextField("Ask OpenClaw Agent...", text: $prompt)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isRunning)

                if isRunning {
                    Button(role: .destructive) {
                        stopAgent()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                } else {
                    Button {
                        startAgent()
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(prompt.isEmpty)
                }
            }
            .padding()
        }
        .navigationTitle("AI Agent")
        .task {
            await observeEvents()
        }
    }

    private func startAgent() {
        isRunning = true
        Task {
            do {
                sessionId = try await service.startAgent(prompt: prompt, model: "default", channel: "default")
                prompt = ""
            } catch {
                messages.append("Error: \(error.localizedDescription)")
                isRunning = false
            }
        }
    }

    private func stopAgent() {
        guard let id = sessionId else { return }
        Task {
            try? await service.stopAgent(sessionId: id)
            isRunning = false
            sessionId = nil
        }
    }

    private func observeEvents() async {
        for await event in service.observeEvents() {
            if event.event == "agent.token",
               let data = event.data?.value as? [String: Any],
               let token = data["token"] as? String {
                if messages.isEmpty {
                    messages.append(token)
                } else {
                    let last = messages.removeLast()
                    messages.append(last + token)
                }
            } else if event.event == "agent.complete" {
                isRunning = false
            }
        }
    }
}
