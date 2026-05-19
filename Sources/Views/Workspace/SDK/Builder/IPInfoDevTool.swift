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
        List {
            Section("Network Target") {
                HStack {
                    Image(systemName: "network").foregroundStyle(.secondary)
                    TextField("Current IP (empty) or 8.8.8.8", text: $viewModel.ipAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        Task { await viewModel.lookup() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Query")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }
            }

            if let info = viewModel.info {
                Section("Geolocation") {
                    IPInfoRow(label: "Country", value: info.country, icon: "flag.fill")
                    IPInfoRow(label: "Region", value: info.region, icon: "map.fill")
                    IPInfoRow(label: "City", value: info.city, icon: "building.2.fill")
                    IPInfoRow(label: "Location", value: info.loc, icon: "location.fill")
                }

                Section("Provider") {
                    IPInfoRow(label: "ASN", value: info.org, icon: "server.rack")
                    IPInfoRow(label: "Timezone", value: info.timezone, icon: "clock.fill")
                    IPInfoRow(label: "Postal", value: info.postal, icon: "envelope.fill")
                }
            }

            Section {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .font(.caption)
                    .disabled(viewModel.history.isEmpty)
                }

                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                        .frame(height: 200)
                } else {
                    List {
                        ForEach(viewModel.history) { item in
                            Button {
                                viewModel.ipAddress = item.title
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.bold())
                                    Text(item.detail)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                    Text(item.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 300)
                }
            } header: {
                Text("History")
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

#Preview {
    IPInfoDevToolView()
}
