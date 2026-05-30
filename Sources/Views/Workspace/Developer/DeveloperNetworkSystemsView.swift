import SwiftUI

struct NetworkInspectorView: View {
    @ObservedObject var networkService = NetworkMonitoringService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var body: some View {
        List {
            Section("Project Context") {
                Picker("App", selection: $selectedAppID) {
                    Text("All Network Traffic").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Request History") {
                let filtered = networkService.requests.filter { req in
                    selectedAppID == nil || req.appID == selectedAppID
                }

                if filtered.isEmpty {
                    Text("No network requests recorded.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(filtered) { req in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(req.method).font(.caption.bold())
                                    .padding(.horizontal, 4).padding(.vertical, 2)
                                    .background(methodColor(req.method).opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                                    .foregroundStyle(methodColor(req.method))

                                Text(req.url).font(.caption).lineLimit(1)
                                Spacer()
                                if let code = req.statusCode {
                                    Text("\(code)").font(.caption2.bold())
                                        .foregroundStyle(code >= 400 ? .red : .green)
                                }
                            }

                            HStack {
                                Text(req.timestamp, style: .time).font(.caption2).foregroundStyle(.tertiary)
                                Spacer()
                                Text(String(format: "%.0fms", req.duration * 1000)).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Network Inspector")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Clear") {
                    Task { await networkService.clearLogs() }
                }
            }
        }
    }

    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .secondary
        }
    }
}

struct APIStateMonitorView: View {
    @ObservedObject var networkService = NetworkMonitoringService.shared

    var averageLatency: Double {
        let recent = networkService.requests.prefix(20)
        guard !recent.isEmpty else { return 0 }
        return recent.reduce(0) { $0 + $1.duration } / Double(recent.count)
    }

    var body: some View {
        List {
            Section("Service Health") {
                HStack {
                    Text("Average Latency")
                    Spacer()
                    Text(String(format: "%.0f ms", averageLatency * 1000)).bold()
                }

                HStack {
                    Text("Success Rate")
                    Spacer()
                    let recent = networkService.requests.prefix(50)
                    let successes = recent.filter { ($0.statusCode ?? 0) < 400 }.count
                    let rate = recent.isEmpty ? 100 : (Double(successes) / Double(recent.count) * 100)
                    Text(String(format: "%.1f%%", rate))
                        .bold()
                        .foregroundStyle(rate > 95 ? .green : .orange)
                }
            }

            Section("Endpoint Stats") {
                let endpoints = Dictionary(grouping: networkService.requests, by: { $0.url })
                ForEach(Array(endpoints.keys).sorted(), id: \.self) { url in
                    HStack {
                        Text(url).font(.caption).lineLimit(1)
                        Spacer()
                        Text("\(endpoints[url]?.count ?? 0) hits").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("API State Monitor")
    }
}
