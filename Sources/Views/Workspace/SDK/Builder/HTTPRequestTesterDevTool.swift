import SwiftUI

struct HTTPRequestTesterDevTool: DevTool {
    let id = "http-request-tester"
    let name = "HTTP Request Tester"
    let category = DevToolCategory.networking
    let icon = "network"
    let description = "Test HTTP endpoints"

    func render() -> some View {
        HTTPRequestTesterView()
    }
}

struct HTTPRequestTesterView: View {
    @StateObject private var viewModel = HTTPRequestTesterViewModel()

    var body: some View {
        Form {
            Section("Request") {
                TextField("https://api.github.com", text: $viewModel.urlString)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Picker("Method", selection: $viewModel.method) {
                    Text("GET").tag("GET")
                    Text("POST").tag("POST")
                    Text("PUT").tag("PUT")
                    Text("DELETE").tag("DELETE")
                }

                Button("Send Request") {
                    Task { await viewModel.send() }
                }
                .disabled(viewModel.isLoading)
            }

            if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Loading...")
                    }
                }
            }

            if let response = viewModel.responseBody {
                Section("Response") {
                    LabeledContent("Status", value: "\(viewModel.statusCode)")
                    Text(response)
                        .font(.monospaced(.caption2)())
                        .textSelection(.enabled)
                        .frame(maxHeight: 200)
                }
            }
        }
    }
}

class HTTPRequestTesterViewModel: ObservableObject {
    @Published var urlString = "https://api.github.com"
    @Published var method = "GET"
    @Published var isLoading = false
    @Published var responseBody: String?
    @Published var statusCode = 0

    func send() async {
        guard let url = URL(string: urlString) else { return }
        await MainActor.run { isLoading = true; responseBody = nil }

        var request = URLRequest(url: url)
        request.httpMethod = method

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            await MainActor.run {
                self.statusCode = httpResponse?.statusCode ?? 0
                self.responseBody = String(data: data, encoding: .utf8) ?? "Binary Data"
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.responseBody = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
