

import SwiftUI

struct SDKPluginsView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var showingCatalog = false

    var body: some View {
        List {
            Section {
                if manager.plugins.isEmpty {
                    Text("No Plugins Installed")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(manager.plugins) { plugin in
                        PluginRow(plugin: plugin, manager: manager, authorizationManager: authorizationManager)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    manager.remove(id: plugin.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                Text("Installed")
            }

            if !manager.plugins.isEmpty {
                Section {
                    ForEach(manager.plugins.filter { !$0.automationHooks.isEmpty }) { plugin in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plugin.name).font(.caption.bold())
                            ForEach(plugin.automationHooks, id: \.self) { hook in
                                Text(hook)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Automation Hooks")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plugins")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCatalog = true
                } label: {
                    Label("Browse", systemImage: "cart")
                }
            }
        }
        .sheet(isPresented: $showingCatalog) {
            PluginCatalogView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }
}

// MARK: - Private Subviews

private struct PluginRow: View {
    let plugin: SDKPlugin
    @ObservedObject var manager: SDKPluginManager
    @ObservedObject var authorizationManager: AuthorizationManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name).font(.headline)
                Text("v\(plugin.version)").font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(plugin.permissions, id: \.self) { perm in
                    PermissionBadge(perm: perm)
                }
            }

            Toggle("", isOn: Binding(
                get: { manager.plugins.first(where: { $0.id == plugin.id })?.isEnabled ?? false },
                set: { $0 ? manager.enable(id: plugin.id) : manager.disable(id: plugin.id) }
            ))
            .labelsHidden()
            .disabled(!authorizationManager.canUsePlugin(id: plugin.id))
        }
        .padding(.vertical, 4)
    }
}

private struct PermissionBadge: View {
    let perm: PluginPermission

    var body: some View {
        Image(systemName: icon)
            .font(.caption2)
            .padding(4)
            .background(Color.accentColor.opacity(0.1), in: Circle())
            .foregroundStyle(Color.accentColor)
    }

    private var icon: String {
        switch perm {
        case .readData: return "eye"
        case .writeData: return "pencil"
        case .network: return "globe"
        case .notifications: return "bell"
        case .fileAccess: return "doc"
        }
    }
}

struct PluginCatalogView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = SDKPluginManager.shared

    var body: some View {
        NavigationStack {
            List {
                if availablePlugins.isEmpty {
                    ContentUnavailableView(
                        "All Plugins Installed",
                        systemImage: "checkmark.circle",
                        description: Text("All available extensions are already in your workspace.")
                    )
                } else {
                    ForEach(availablePlugins) { plugin in
                        CatalogRow(plugin: plugin, manager: manager)
                    }
                }
            }
            .navigationTitle("Plugin Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var availablePlugins: [SDKPlugin] {
        let installedNames = Set(manager.plugins.map { $0.name })
        return [
            SDKPlugin(id: UUID(), name: "Data Insights", version: "1.0.0", permissions: [.readData], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["data.updated"]),
            SDKPlugin(id: UUID(), name: "Cloud Sync", version: "2.1.0", permissions: [.readData, .network], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["connector.sync"]),
            SDKPlugin(id: UUID(), name: "Safety Monitor", version: "0.9.5", permissions: [.notifications, .readData], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["connector.error"]),
            SDKPlugin(id: UUID(), name: "Export Manager", version: "1.2.0", permissions: [.readData, .fileAccess], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["export.completed"]),
            SDKPlugin(id: UUID(), name: "AI Assistant", version: "3.0.0", permissions: [.readData, .writeData, .network], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["persona.query"])
        ].filter { !installedNames.contains($0.name) }
    }
}

private struct CatalogRow: View {
    let plugin: SDKPlugin
    @ObservedObject var manager: SDKPluginManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name).font(.headline)
                HStack {
                    ForEach(plugin.permissions, id: \.self) { perm in
                        Text(perm.rawValue)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1), in: Capsule())
                    }
                }
            }
            Spacer()
            Button("Install") {
                try? manager.install(plugin)
                SDKLogStore.shared.log("Plugin Installed: \(plugin.name)", source: "PluginCatalog", level: .info)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
