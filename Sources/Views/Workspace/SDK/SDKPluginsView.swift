import SwiftUI

struct SDKPluginsView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @State private var showingCatalog = false

    var body: some View {
        List {
            Section("Installed Plugins (\(manager.plugins.count))") {
                if manager.plugins.isEmpty {
                    Text("No plugins installed").foregroundStyle(.secondary)
                } else {
                    ForEach(manager.plugins) { plugin in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(plugin.name).font(.headline)
                                Text("v\(plugin.version)").font(.caption).foregroundStyle(.secondary)
                            }

                            Spacer()

                            HStack {
                                ForEach(plugin.permissions, id: \.self) { perm in
                                    permissionBadge(perm)
                                }
                            }

                            Toggle("", isOn: binding(for: plugin.id))
                                .labelsHidden()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                manager.remove(id: plugin.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if !manager.plugins.isEmpty {
                Section("Plugin Hooks") {
                    ForEach(manager.plugins.filter { !$0.automationHooks.isEmpty }) { plugin in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plugin.name).font(.caption).bold()
                            ForEach(plugin.automationHooks, id: \.self) { hook in
                                Text(hook)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Plugins")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Browse") { showingCatalog = true }
            }
        }
        .sheet(isPresented: $showingCatalog) {
            PluginCatalogView()
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { manager.plugins.first(where: { $0.id == id })?.isEnabled ?? false },
            set: { $0 ? manager.enable(id: id) : manager.disable(id: id) }
        )
    }

    private func permissionBadge(_ perm: PluginPermission) -> some View {
        Image(systemName: icon(for: perm))
            .font(.caption2)
            .padding(4)
            .background(Color.blue.opacity(0.1), in: Circle())
            .foregroundStyle(.blue)
    }

    private func icon(for perm: PluginPermission) -> String {
        switch perm {
        case .readData: return "eye.fill"
        case .writeData: return "pencil"
        case .network: return "globe"
        case .notifications: return "bell.fill"
        case .fileAccess: return "doc.fill"
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
                    ContentUnavailableView("All plugins installed", systemImage: "checkmark.circle", description: Text("All available plugins are already installed."))
                } else {
                    ForEach(availablePlugins) { plugin in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(plugin.name).font(.headline)
                                Text(plugin.version).font(.caption).foregroundStyle(.secondary)
                                HStack {
                                    ForEach(plugin.permissions, id: \.self) { perm in
                                        Text(perm.rawValue)
                                            .font(.system(size: 9))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1), in: Capsule())
                                    }
                                }
                            }
                            Spacer()
                            Button("Install") {
                                try? manager.install(plugin)
                                SDKLogStore.shared.log("Plugin installed: \(plugin.name)", source: "PluginCatalog", level: .info)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Plugin Catalog")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var availablePlugins: [SDKPlugin] {
        let installedIDs = Set(manager.plugins.map { $0.name })
        return catalogPlugins.filter { !installedIDs.contains($0.name) }
    }

    private var catalogPlugins: [SDKPlugin] {
        [
            SDKPlugin(id: UUID(), name: "Data Insights", version: "1.0.0", permissions: [.readData], isEnabled: true, installedAt: Date(), tools: SDKToolManager.shared.tools(for: .dataProcessor).map { $0.id }, automationHooks: ["data.updated"]),
            SDKPlugin(id: UUID(), name: "Cloud Sync", version: "2.1.0", permissions: [.readData, .network], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["connector.sync"]),
            SDKPlugin(id: UUID(), name: "Safety Monitor", version: "0.9.5", permissions: [.notifications, .readData], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["connector.error"]),
            SDKPlugin(id: UUID(), name: "Export Manager", version: "1.2.0", permissions: [.readData, .fileAccess], isEnabled: true, installedAt: Date(), tools: SDKToolManager.shared.tools(for: .workflowAction).map { $0.id }, automationHooks: ["export.completed"]),
            SDKPlugin(id: UUID(), name: "AI Assistant", version: "3.0.0", permissions: [.readData, .writeData, .network], isEnabled: true, installedAt: Date(), tools: SDKToolManager.shared.tools(for: .aiUtility).map { $0.id }, automationHooks: ["persona.query"])
        ]
    }
}
