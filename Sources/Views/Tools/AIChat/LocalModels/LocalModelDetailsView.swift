import SwiftUI

struct LocalModelDetailsView: View {
    let model: AIModel
    let config: LocalModelConfig
    @ObservedObject var localService: AIService.AILocalService

    @State private var testResponse: String?
    @State private var isTesting = false
    @State private var errorMessage: String?
    @State private var detailedLogs: String = ""

    var body: some View {
        List {
            Section("Model Information") {
                LabeledContent("Name", value: model.name)
                LabeledContent("ID", value: model.id)
                LabeledContent("Vision Support", value: model.supportsVision ? "Yes" : "No")
                if let context = model.contextLength {
                    LabeledContent("Context Length", value: "\(context) tokens")
                }
            }

            Section("Provider Configuration") {
                LabeledContent("Endpoint", value: config.baseURL)
                LabeledContent("Provider Name", value: config.name)
            }

            Section("Connectivity Test") {
                Button(action: runTest) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isTesting ? "Testing Connection..." : "Send Test Request")
                    }
                }
                .disabled(isTesting)

                if let response = testResponse {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Response Received", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(response)
                            .font(.subheadline)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                if let error = errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Test Failed", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }

            if !detailedLogs.isEmpty {
                Section("Detailed Error Logs") {
                    Text(detailedLogs)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
        }
        .navigationTitle(model.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runTest() {
        isTesting = true
        testResponse = nil
        errorMessage = nil
        detailedLogs = ""

        Task {
            do {
                let message = ChatMessage(role: "user", content: "Hello from ToolsKit")
                // Temporarily use the config's modelName for the test request to ensure it matches what was fetched
                var testConfig = config
                testConfig.modelName = model.id

                detailedLogs += "[TEST] Starting request to \(config.baseURL)/chat/completions\n"
                detailedLogs += "[TEST] Model: \(model.id)\n"

                let response = try await localService.sendRequest(messages: [message], config: testConfig)

                await MainActor.run {
                    self.testResponse = response
                    self.isTesting = false
                    detailedLogs += "[SUCCESS] Response received.\n"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isTesting = false
                    detailedLogs += "[ERROR] \(error.localizedDescription)\n"
                    if let aiError = error as? AIError {
                        detailedLogs += "[DETAILS] \(aiError.localizedDescription)\n"
                    }
                    // Attempt to extract more info if available
                    detailedLogs += "[STACK] \(String(describing: error))\n"
                }
            }
        }
    }
}
