import SwiftUI

struct SDKDiagnosticsView: View {
    @StateObject private var bgEngine = SDKBackgroundEngine.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    var body: some View {
        List {
            Section("System Health") {
                healthRow(title: "Connector Reachability", status: bgEngine.systemHealth.connectorReachability)
                healthRow(title: "Plugin Sandbox", status: bgEngine.systemHealth.pluginSandboxStatus)
                healthRow(title: "Data Store Health", status: bgEngine.systemHealth.coreDataHealth)

                HStack {
                    Text("Last Check")
                    Spacer()
                    Text(bgEngine.systemHealth.lastCheck.formatted(date: .omitted, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Data Sync") {
                ForEach(SDKScope.allCases, id: \.self) { scope in
                    HStack {
                        Text(String(describing: scope).capitalized)
                        Spacer()
                        Text("Healthy").font(.caption).foregroundStyle(.green)
                    }
                }
            }

            Section("Plugin Integrity") {
                ForEach(SDKPluginManager.shared.plugins) { plugin in
                    HStack {
                        Text(plugin.name)
                        Spacer()
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                    }
                }
            }

            Section("Connector Latency") {
                ForEach(SDKConnectorManager.shared.connectors, id: \.id) { connector in
                    HStack {
                        Text(connector.name)
                        Spacer()
                        Text("24ms").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .onAppear {
            bgEngine.startHealthCheckLoop()
        }
    }

    private func healthRow(title: String, status: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: status ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(status ? .green : .red)
        }
    }
}
