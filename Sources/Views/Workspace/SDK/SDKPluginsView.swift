import SwiftUI

struct SDKPluginsView: View {
    @StateObject private var pluginManager = SDKPluginManager.shared
    @State private var showingInstallSheet = false

    var body: some View {
        List {
            ForEach(pluginManager.plugins) { plugin in
                HStack(spacing: 12) {
                    Image(systemName: "puzzlepiece.fill")
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading) {
                        Text(plugin.name).font(.headline)
                        Text("v\(plugin.version)").font(.caption).foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(plugin.permissions, id: \.self) { perm in
                            PermissionIcon(permission: perm)
                        }
                    }

                    Toggle("", isOn: Binding(
                        get: { plugin.isEnabled },
                        set: { if $0 { pluginManager.enable(id: plugin.id) } else { pluginManager.disable(id: plugin.id) } }
                    ))
                    .labelsHidden()
                }
                .swipeActions {
                    Button(role: .destructive) {
                        pluginManager.remove(id: plugin.id)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Plugins")
        .toolbar {
            Button("Browse / Install") {
                showingInstallSheet = true
            }
        }
        .sheet(isPresented: $showingInstallSheet) {
            PluginCatalogView()
        }
    }
}

struct PermissionIcon: View {
    let permission: PluginPermission
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 10))
            .padding(4)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Circle())
    }

    var iconName: String {
        switch permission {
        case .readData: return "eye"
        case .writeData: return "pencil"
        case .network: return "network"
        case .notifications: return "bell"
        case .fileAccess: return "folder"
        }
    }
}

struct PluginCatalogView: View {
    @Environment(\.dismiss) var dismiss
    let catalog = [
        SDKPlugin(name: "Data Visualizer", version: "1.0.0", permissions: [.readData]),
        SDKPlugin(name: "Auto Archiver", version: "1.2.0", permissions: [.readData, .fileAccess]),
        SDKPlugin(name: "Notification Bot", version: "0.9.0", permissions: [.notifications, .network])
    ]

    var body: some View {
        NavigationStack {
            List(catalog) { plugin in
                HStack {
                    VStack(alignment: .leading) {
                        Text(plugin.name).font(.headline)
                        Text("v\(plugin.version)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Install") {
                        try? SDKPluginManager.shared.install(plugin)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Plugin Catalog")
            .toolbar {
                Button("Close") { dismiss() }
            }
        }
    }
}
