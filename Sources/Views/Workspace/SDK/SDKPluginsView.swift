import SwiftUI

struct SDKPluginsView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @State private var showingCatalog = false

    var body: some View {
        List {
            Section("Installed Plugins") {
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

    let catalog: [SDKPlugin] = [
        SDKPlugin(id: UUID(), name: "Data Insights", version: "1.0.0", permissions: [.readData], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["data.updated"]),
        SDKPlugin(id: UUID(), name: "Cloud Sync", version: "2.1.0", permissions: [.readData, .network], isEnabled: true, installedAt: Date(), tools: [], automationHooks: []),
        SDKPlugin(id: UUID(), name: "Safety Monitor", version: "0.9.5", permissions: [.notifications, .readData], isEnabled: true, installedAt: Date(), tools: [], automationHooks: ["connector.error"])
    ]

    var body: some View {
        NavigationStack {
            List(catalog) { plugin in
                HStack {
                    VStack(alignment: .leading) {
                        Text(plugin.name).font(.headline)
                        Text(plugin.version).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Install") {
                        try? manager.install(plugin)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
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
}
