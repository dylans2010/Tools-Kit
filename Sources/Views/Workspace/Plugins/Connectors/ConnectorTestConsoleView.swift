import SwiftUI

struct ConnectorTestConsoleView: View {
    let connector: ConnectorDefinition
    @State private var selectedEndpoint: ExternalAPIEndpoint?
    @State private var responseOutput = ""
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Test Configuration") {
                Picker("Endpoint", selection: $selectedEndpoint) {
                    Text("Select Endpoint").tag(Optional<ExternalAPIEndpoint>.none)
                    ForEach(connector.endpoints) { ep in
                        Text(ep.name).tag(Optional(ep))
                    }
                }
            }

            Section {
                Button("Run Test Request") {
                    runTest()
                }
                .disabled(selectedEndpoint == nil || isTesting)
            }

            Section("Response Output") {
                if isTesting {
                    ProgressView()
                } else {
                    TextEditor(text: $responseOutput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
        }
        .navigationTitle("Test Console")
    }

    private func runTest() {
        guard let ep = selectedEndpoint else { return }
        isTesting = true
        responseOutput = "Requesting \(ep.baseURL)\(ep.path)..."

        Task {
            do {
                let (data, response) = try await ConnectorExecutionService.shared.performRequest(endpoint: ep, connector: connector)
                let body = String(data: data, encoding: .utf8) ?? "Unable to parse body"

                await MainActor.run {
                    responseOutput = "Status: \(response.statusCode)\n\n\(body)"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    responseOutput = "Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}
