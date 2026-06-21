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
                if let arch = model.architecture {
                    LabeledContent("Architecture", value: arch)
                }
                if let ctx = model.contextLength {
                    LabeledContent("Context Length", value: "\(ctx)")
                }
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
                let response = try await connectionManager.sendChatRequest(prompt: testPrompt)
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
