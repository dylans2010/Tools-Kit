import SwiftUI

struct HeaderInspectorDevTool: DevTool {
    let id = "header-inspector"
    let name = "Header Inspector"
    let category = DevToolCategory.networking
    let icon = "list.bullet.indent"
    let description = "Inspect HTTP Headers"

    func render() -> some View {
        HeaderInspectorView()
    }
}

struct HeaderInspectorView: View {
    @StateObject private var viewModel = HeaderInspectorViewModel()

    var body: some View {
        Form {
            Section("URL to Fetch Headers") {
                TextField("https://example.com", text: $viewModel.urlString)
                Button("Fetch Headers") {
                    Task { await viewModel.fetch() }
                }
                .disabled(viewModel.isLoading)
            }

            Section("Headers") {
                if viewModel.headers.isEmpty {
                    Text("No headers fetched")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading) {
                            Text(key).font(.caption.bold())
                            Text(value).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

class HeaderInspectorViewModel: ObservableObject {
    @Published var urlString = "https://example.com"
    @Published var headers: [String: String] = [:]
    @Published var isLoading = false

    func fetch() async {
        guard let url = URL(string: urlString) else { return }
        await MainActor.run { isLoading = true; headers = [:] }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                await MainActor.run {
                    self.headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}
