import SwiftUI

struct SDKAPIBrowserView: View {
    @State private var endpoint = "mail.list"
    @State private var result = ""

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Internal Router")) {
                    TextField("Endpoint", text: $endpoint)
                    Button("Call Endpoint") {
                        Task {
                            do {
                                let response: SDKResponse<[Any]> = try await WorkspaceSDK.shared.router.call(endpoint: endpoint)
                                if let data = response.data {
                                    result = "Success: \(data.count) items returned"
                                } else if let error = response.error {
                                    result = "Error: \(error.localizedDescription)"
                                }
                            } catch {
                                result = "Exception: \(error.localizedDescription)"
                            }
                        }
                    }
                }

                Section(header: Text("Response")) {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("API Explorer")
    }
}
