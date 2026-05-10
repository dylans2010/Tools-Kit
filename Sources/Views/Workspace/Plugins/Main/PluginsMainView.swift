import SwiftUI
import Combine

struct PluginsMainView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var recentEvents: [PluginEvent] = []
    @State private var cancellables = Set<AnyCancellable>()

    @State private var blockedPlugin: PluginDefinition?
    @State private var blockedReason: ValidationFailureReason = .capabilityMismatch
    @State private var blockedDetail = ""
    @State private var showingLimitedView = false

    var body: some View {
        NavigationStack {
            List {
                Section("Plugin Development") {
                    NavigationLink("Plugin Builder", destination: PluginBuildView())
                    NavigationLink("Developer Console", destination: PluginDevConsoleView())
                    NavigationLink("Marketplace", destination: MarketplaceView())
                }

                Section("Plugin Management") {
                    NavigationLink("Installed Plugins", destination: PluginsInstalledView())
                    NavigationLink("Plugin Connectors", destination: ConnectorsMainView())
                    NavigationLink("SDK Workspace", destination: SDKHomeView())
                    NavigationLink("SDK Build", destination: SDKBuildView())
                }

                Section("Security") {
                    NavigationLink("Plugin Security", destination: PluginSecurityView())
                }

                Section("Runtime Overview") {
                    LabeledContent("Enabled", value: "\(manager.installedPlugins.filter(\.isEnabled).count)")
                    LabeledContent("Disabled", value: "\(manager.installedPlugins.filter { !$0.isEnabled }.count)")
                    LabeledContent("Recent Events", value: "\(recentEvents.count)")
                }
            }
            .navigationTitle("Plugins")
            .onAppear(perform: setupActivityStream)
            .onAppear(perform: setupBlockedExecutionListener)
            .sheet(isPresented: $showingLimitedView) {
                if let plugin = blockedPlugin {
                    NavigationStack {
                        PluginLimitedView(plugin: plugin, reason: blockedReason, detail: blockedDetail)
                    }
                }
            }
        }
    }

    private func setupActivityStream() {
        PluginEventBus.shared.subscribe { event in
            recentEvents.insert(event, at: 0)
            if recentEvents.count > 20 { recentEvents.removeLast() }
        }
        .store(in: &cancellables)
    }

    private func setupBlockedExecutionListener() {
        NotificationCenter.default.publisher(for: .pluginExecutionBlocked)
            .sink { notification in
                if let pluginID = notification.userInfo?["pluginID"] as? UUID,
                   let plugin = manager.installedPlugins.first(where: { $0.id == pluginID }),
                   let reason = notification.userInfo?["reason"] as? ValidationFailureReason,
                   let detail = notification.userInfo?["detail"] as? String {
                    blockedPlugin = plugin
                    blockedReason = reason
                    blockedDetail = detail
                    showingLimitedView = true
                }
            }
            .store(in: &cancellables)
    }
}
