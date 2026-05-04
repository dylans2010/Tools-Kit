import SwiftUI

struct PluginsInstalledView: View {
    @StateObject private var manager = PluginManager.shared

    var body: some View {
        List {
            if manager.installedPlugins.isEmpty {
                ContentUnavailableView("No Plugins Installed", systemImage: "puzzlepiece", description: Text("Visit the marketplace to discover new extensions."))
            } else {
                ForEach(manager.installedPlugins) { plugin in
                    PluginRow(plugin: plugin) { }
                }
            }
        }
        .navigationTitle("Installed")
    }
}
