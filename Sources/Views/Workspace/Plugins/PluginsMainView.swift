import SwiftUI

struct PluginsMainView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: PluginsInstalledView()) {
                    Label("Installed Plugins", systemImage: "puzzlepiece.extension.fill")
                }
                NavigationLink(destination: MarketplaceView()) {
                    Label("Plugin Marketplace", systemImage: "cart.fill")
                }
            }

            Section("Developer") {
                NavigationLink(destination: PluginBuildView()) {
                    Label("Create New Plugin", systemImage: "plus.circle.fill")
                }
                NavigationLink(destination: PluginDevConsoleView()) {
                    Label("Debug Console", systemImage: "terminal.fill")
                }
            }
        }
        .navigationTitle("Extensions")
    }
}
