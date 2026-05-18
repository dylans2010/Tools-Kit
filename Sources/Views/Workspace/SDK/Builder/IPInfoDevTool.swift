import SwiftUI

struct IPInfoDevTool: DevTool {
    let id = "ip-info"
    let name = "IP Info"
    let category = DevToolCategory.networking
    let icon = "globe"
    let description = "Geolocate and inspect IP addresses"

    func render() -> some View {
        IPInfoDevToolView()
    }
}

struct IPInfoDevToolView: View {
    @StateObject private var viewModel = IPInfoViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "IP Info",
                description: "Retrieve geolocation, ISP, and network data for any IP address.",
                icon: "globe"
            )
            .padding()

            Form {
                Section("Target IP") {
                    HStack {
                        TextField("8.8.8.8", text: $viewModel.ipAddress)
                            .autocorrectionDisabled()

                        Button("Lookup") {
                            Task { await viewModel.lookup() }
                        }
                    }
                }

                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }

                if let info = viewModel.info {
                    Section("Geographical Data") {
                        LabeledContent("Country", value: info.country ?? "Unknown")
                        LabeledContent("Region", value: info.region ?? "Unknown")
                        LabeledContent("City", value: info.city ?? "Unknown")
                        LabeledContent("Coordinates", value: info.loc ?? "Unknown")
                    }

                    Section("Network Data") {
                        LabeledContent("Organization", value: info.org ?? "Unknown")
                        LabeledContent("Timezone", value: info.timezone ?? "Unknown")
                        LabeledContent("Postal Code", value: info.postal ?? "Unknown")
                    }
                }

                Section("History") {
                    HistoryView(history: viewModel.history) { item in
                        viewModel.ipAddress = item.title
                    } onClear: {
                        viewModel.history.removeAll()
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

class IPInfoViewModel: ObservableObject {
    @Published var ipAddress = ""
    @Published var isLoading = false
    @Published var info: IPData?
    @Published var history: [HistoryItem] = []

    func lookup() async {
        let target = ipAddress.isEmpty ? "" : "/\(ipAddress)"
        guard let url = URL(string: "https://ipinfo.io\(target)/json") else { return }

        await MainActor.run { isLoading = true; info = nil }

        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let decoded = try JSONDecoder().decode(IPData.self, from: data)

            await MainActor.run {
                self.info = decoded
                self.history.insert(HistoryItem(title: decoded.ip ?? "Unknown IP", detail: "\(decoded.city ?? ""), \(decoded.country ?? "")"), at: 0)
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}
