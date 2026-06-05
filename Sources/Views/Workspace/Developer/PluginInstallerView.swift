import SwiftUI

struct PluginInstallerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Available Plugins") {
                pluginList
            }
        }
        .navigationTitle("Plugin Installer")
        .onAppear {
            loadInitialPlugins()
        }
    }

    @ViewBuilder
    private var pluginList: some View {
        if store.pluginPackages.isEmpty {
            Text("No plugins available.").font(.caption).foregroundStyle(.secondary)
        } else {
            ForEach(store.pluginPackages) { plugin in
                pluginRow(for: plugin)
            }
        }
    }

    private func pluginRow(for plugin: PluginPackage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name).font(.subheadline.bold())
                Text(plugin.description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Install") {
                installPlugin(plugin)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }

    private func installPlugin(_ plugin: PluginPackage) {
        var current = store.activities
        current.append(DeveloperActivityEvent(eventType: .appUpdated, sourceAppName: "Plugin \(plugin.name) installed"))
        store.saveActivities(current)
    }

    private func loadInitialPlugins() {
        if store.pluginPackages.isEmpty {
            store.savePluginPackages([
                PluginPackage(name: "Logging Analytics", description: "Extended logging for cloud clusters", version: "2.1.0"),
                PluginPackage(name: "Security Shield", description: "Real-time threat detection", version: "1.0.5")
            ])
        }
    }
}
