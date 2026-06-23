import SwiftUI

struct LMLinkModelDetailView: View {
    let device: LMDevice
    let model: LMModel

    @State private var testPrompt = "Hello! How are you?"
    @State private var testResponse = ""
    @State private var isTesting = false
    @StateObject private var connectionManager = LMConnectionManager.shared

    var body: some View {
        List {
            Section(header: Text("Model Metadata")) {
                LabeledContent("ID", value: model.id)
                LabeledContent("Name", value: model.name)
                LabeledContent("Architecture", value: model.architecture ?? "N/A")
                LabeledContent("Context Length", value: model.contextLength != nil ? "\(model.contextLength!)" : "N/A")
                LabeledContent("File Size", value: model.fileSize ?? "N/A")
                LabeledContent("Quantization", value: model.quantization ?? "N/A")
                LabeledContent("Author", value: model.author ?? "N/A")
                LabeledContent("License", value: model.license ?? "N/A")
                LabeledContent("Release Date", value: model.releaseDate ?? "N/A")
            }

            Section(header: Text("Test Model")) {
                TextField("Enter test prompt", text: $testPrompt)

                Button(action: {
                    runTest()
                }) {
                    if isTesting {
                        ProgressView()
                    } else {
                        Text("Run Test Prompt")
                    }
                }
                .disabled(isTesting || testPrompt.isEmpty)

                if !testResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Response:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(testResponse)
                            .font(.body)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle(model.name)
    }

    private func runTest() {
        isTesting = true
        testResponse = ""

        Task {
            do {
                // Ensure we are using this device/model for the test
                let response = try await connectionManager.sendChatRequest(messages: [
                    ChatMessage(role: "user", content: testPrompt)
                ])
                await MainActor.run {
                    self.testResponse = response
                    self.isTesting = false
                }
            } catch {
                await MainActor.run {
                    self.testResponse = "Error: \(error.localizedDescription)"
                    self.isTesting = false
                }
            }
        }
    }
}
