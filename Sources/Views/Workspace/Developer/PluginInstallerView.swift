import SwiftUI

struct PluginInstallerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Available Plugins") {
                if store.pluginPackages.isEmpty {
                    Text("No plugins available.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.pluginPackages) { plugin in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plugin.name).font(.subheadline.bold())
                                Text(plugin.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Install") {
                                // Real logic would add to an installed set
                                var current = store.activities
                                current.append(DeveloperActivityEvent(type: .appUpdated, appName: "Plugin \(plugin.name) installed"))
                                store.saveActivities(current)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Plugin Installer")
        .onAppear {
            if store.pluginPackages.isEmpty {
                store.savePluginPackages([
                    PluginPackage(name: "Logging Analytics", description: "Extended logging for cloud clusters", version: "2.1.0"),
                    PluginPackage(name: "Security Shield", description: "Real-time threat detection", version: "1.0.5")
                ])
            }
        }
    }
}
