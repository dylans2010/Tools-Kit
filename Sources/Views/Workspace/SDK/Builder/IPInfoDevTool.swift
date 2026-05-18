import SwiftUI

struct IPInfoDevTool: DevTool {
    let id = "ip-info"
    let name = "IP Info"
    let category = DevToolCategory.networking
    let icon = "info.circle"
    let description = "Get information about an IP address"

    func render() -> some View {
        IPInfoView()
    }
}

struct IPInfoView: View {
    @StateObject private var viewModel = IPInfoViewModel()

    var body: some View {
        Form {
            Section("IP Address") {
                TextField("8.8.8.8", text: $viewModel.ipAddress)
                Button("Get Info") {
                    Task { await viewModel.fetch() }
                }
                .disabled(viewModel.isLoading)
            }

            if viewModel.isLoading {
                ProgressView()
            }

            if let info = viewModel.info {
                Section("Details") {
                    LabeledContent("City", value: info.city ?? "Unknown")
                    LabeledContent("Region", value: info.region ?? "Unknown")
                    LabeledContent("Country", value: info.country ?? "Unknown")
                    LabeledContent("Org", value: info.org ?? "Unknown")
                    LabeledContent("Location", value: info.loc ?? "Unknown")
                }
            }
        }
    }
}

class IPInfoViewModel: ObservableObject {
    @Published var ipAddress = ""
    @Published var info: IPData?
    @Published var isLoading = false

    func fetch() async {
        let urlStr = ipAddress.isEmpty ? "https://ipinfo.io/json" : "https://ipinfo.io/\(ipAddress)/json"
        guard let url = URL(string: urlStr) else { return }

        await MainActor.run { isLoading = true }

        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let decoded = try JSONDecoder().decode(IPData.self, from: data)
            await MainActor.run {
                self.info = decoded
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}
