import SwiftUI

struct DeveloperNetworkTrafficView: View {
    @ObservedObject var networkService = NetworkMonitorService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var filteredRequests: [NetworkRequest] {
        networkService.requests.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("All Projects").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Network Traffic") {
                if filteredRequests.isEmpty {
                    EmptyStateView(icon: "wifi.router", title: "No Traffic", message: "Start your application to begin monitoring real-time network requests.")
                } else {
                    ForEach(filteredRequests) { request in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(request.url).font(.caption.bold()).lineLimit(1)
                                Text("\(request.method) • \(request.statusCode)").font(.system(size: 8)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(request.duration * 1000))ms").font(.system(size: 10, design: .monospaced)).foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Network Monitor")
    }
}
