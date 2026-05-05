import SwiftUI

struct ConnectorTestConsoleView: View {
    @State var connector: ConnectorDefinition
    @Environment(\.dismiss) var dismiss

    @State private var selectedEndpointID: UUID?
    @State private var requestBody = "{}"
    @State private var responseOutput = "No data yet."
    @State private var isExecuting = false
    @State private var statusCode: Int?

    var body: some View {
        List {
            Section("API Simulation") {
                Picker("Endpoint", selection: $selectedEndpointID) {
                    Text("Select Endpoint").tag(Optional<UUID>.none)
                    ForEach(connector.endpoints) { ep in
                        Text("\(ep.method) \(ep.path)").tag(Optional(ep.id))
                    }
                }
            }

            Section("Request Body") {
                TextEditor(text: $requestBody)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 150)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }

            Section {
                Button(action: runTest) {
                    if isExecuting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Simulate API Call")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(isExecuting || selectedEndpointID == nil)
            }

            Section("Response Console") {
                if let code = statusCode {
                    HStack {
                        Text("Status Code")
                        Spacer()
                        Text("\(code)")
                            .foregroundColor(code < 300 ? .green : .red)
                            .bold()
                    }
                }

                ScrollView {
                    Text(responseOutput)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 200)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .navigationTitle("Test Console")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func runTest() {
        guard let endpointID = selectedEndpointID,
              let endpoint = connector.endpoints.first(where: { $0.id == endpointID }) else { return }

        isExecuting = true
        responseOutput = "Executing request..."

        Task {
            do {
                let data = try await ConnectorExecutionService.shared.execute(endpoint: endpoint, connector: connector)
                let output = String(data: data, encoding: .utf8) ?? "Invalid response data"

                await MainActor.run {
                    self.responseOutput = output
                    self.statusCode = 200
                    self.isExecuting = false
                }
            } catch {
                await MainActor.run {
                    self.responseOutput = "Error: \(error.localizedDescription)"
                    self.statusCode = (error as NSError).code
                    self.isExecuting = false
                }
            }
        }
    }
}
