import SwiftUI

struct AccessControlOverviewView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @StateObject private var moduleRegistry = SDKModuleRegistry.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared

    @State private var searchText = ""

    var body: some View {
        List {
            Section("Auth State") {
                LabeledContent("State", value: authorizationManager.authState.rawValue)
                LabeledContent("Active Scopes", value: "\(authorizationManager.currentScopes().count)")
            }

            Section("Modules") {
                let modules = moduleRegistry.modules.filter { searchText.isEmpty || $0.identifier.localizedCaseInsensitiveContains(searchText) || $0.displayName.localizedCaseInsensitiveContains(searchText) }
                if modules.isEmpty {
                    Text("No modules")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(modules, id: \.id) { module in
                        row(name: module.identifier, requiredScopes: module.requiredScopes, allowed: authorizationManager.canAccessModule(id: module.identifier))
                    }
                }
            }

            Section("Plugins") {
                let plugins = pluginManager.plugins.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                if plugins.isEmpty {
                    Text("No plugins")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(plugins, id: \.id) { plugin in
                        row(name: plugin.name, requiredScopes: plugin.requiredScopes, allowed: authorizationManager.canUsePlugin(id: plugin.id))
                    }
                }
            }

            Section("Connectors") {
                let connectors = connectorManager.connectors.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                if connectors.isEmpty {
                    Text("No connectors")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(connectors, id: \.id) { connector in
                        row(name: connector.name, requiredScopes: connector.requiredScopes, allowed: authorizationManager.canUseConnector(id: connector.id))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Access Control")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search modules, plugins, connectors")
    }

    private func row(name: String, requiredScopes: [String], allowed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text(allowed ? "Allowed" : "Blocked")
                    .font(.caption.bold())
                    .foregroundStyle(allowed ? Color.green : Color.red)
            }

            Text(requiredScopes.isEmpty ? "No scopes required" : requiredScopes.joined(separator: ", "))
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
