import SwiftUI

struct ScopeInspectorView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @StateObject private var moduleRegistry = SDKModuleRegistry.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared

    @State private var query = ""
    @State private var showOnlyBlocked = false

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Active Scope Count", value: "\(authorizationManager.currentScopes().count)")
                LabeledContent("Violations", value: "\(authorizationManager.securityViolations.count)")
                Toggle("Show only blocked resources", isOn: $showOnlyBlocked)
            }

            if let token = authorizationManager.authSession?.token {
                Section("Token Inspector") {
                    LabeledContent("Version", value: token.header.version)
                    LabeledContent("Type", value: token.header.type)
                    LabeledContent("User ID", value: token.payload.userId)
                    LabeledContent("Issued", value: token.payload.issuedAt, format: .dateTime)
                    LabeledContent("Expires", value: token.payload.expiresAt, format: .dateTime)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scope Hash").font(.caption).foregroundStyle(.secondary)
                        Text(token.payload.scopeHash).font(.caption2.monospaced())
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Signature").font(.caption).foregroundStyle(.secondary)
                        Text(token.signature).font(.caption2.monospaced())
                            .lineLimit(2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Raw Token").font(.caption).foregroundStyle(.secondary)
                        Text(token.rawString).font(.system(size: 8).monospaced())
                            .lineLimit(4)
                            .textSelection(.enabled)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        if token.payload.expiresAt < Date() {
                            Label("Expired", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        } else {
                            Label("Valid Signature", systemImage: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            Section("Active Scopes") {
                let activeScopes = authorizationManager.currentScopes()
                    .filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }
                if activeScopes.isEmpty {
                    Text("No active scopes")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeScopes, id: \.self) { scope in
                        Text(scope).font(.caption.monospaced())
                    }
                }
            }

            ForEach(authorizationManager.currentScopes().filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }, id: \.self) { scope in
                Section(scope) {
                    resourceRows(for: scope)
                }
            }

            Section("Recent Violations") {
                if authorizationManager.securityViolations.isEmpty {
                    Text("No violations detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(authorizationManager.securityViolations) { violation in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(violation.scope)
                                    .font(.caption.monospaced().bold())
                                Spacer()
                                Text(violation.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(violation.resourceType): \(violation.resourceId)")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scope Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Filter scopes")
    }

    @ViewBuilder
    private func resourceRows(for scope: String) -> some View {
        let modules = moduleRegistry.modules.filter { $0.requiredScopes.contains(scope) }
        let plugins = pluginManager.plugins.filter { $0.requiredScopes.contains(scope) }
        let connectors = connectorManager.connectors.filter { $0.requiredScopes.contains(scope) }

        if modules.isEmpty && plugins.isEmpty && connectors.isEmpty {
            Text("No resources depend on this scope")
                .foregroundStyle(.secondary)
        } else {
            ForEach(modules, id: \.id) { module in
                let allowed = authorizationManager.canAccessModule(id: module.identifier)
                if !showOnlyBlocked || !allowed {
                    scopeRow("Module", name: module.displayName, allowed: allowed)
                }
            }
            ForEach(plugins, id: \.id) { plugin in
                let allowed = authorizationManager.canUsePlugin(id: plugin.id)
                if !showOnlyBlocked || !allowed {
                    scopeRow("Plugin", name: plugin.name, allowed: allowed)
                }
            }
            ForEach(connectors, id: \.id) { connector in
                let allowed = authorizationManager.canUseConnector(id: connector.id)
                if !showOnlyBlocked || !allowed {
                    scopeRow("Connector", name: connector.name, allowed: allowed)
                }
            }
        }
    }

    private func scopeRow(_ type: String, name: String, allowed: Bool) -> some View {
        HStack {
            Text("\(type): \(name)")
            Spacer()
            Label(allowed ? "Allowed" : "Blocked", systemImage: allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(allowed ? Color.green : Color.red)
        }
    }
}
