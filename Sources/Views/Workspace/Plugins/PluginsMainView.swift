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

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statsStrip
                managementSection
                activePluginsSection
                recentActivitySection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
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

    private var statsStrip: some View {
        HStack(spacing: 12) {
            statCard("Active", value: manager.installedPlugins.filter(\.isEnabled).count, color: .green, icon: "bolt.fill")
            statCard("Disabled", value: manager.installedPlugins.filter { !$0.isEnabled }.count, color: .gray, icon: "pause.fill")
            statCard("Errors", value: manager.installedPlugins.reduce(0) { $0 + $1.errorCount }, color: .red, icon: "exclamationmark.triangle.fill")
        }
    }

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Management")
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: columns, spacing: 12) {
                navTile("Create Plugin", subtitle: "Scaffold a new plugin", icon: "plus.circle.fill", color: .blue, destination: PluginBuildView())
                navTile("Build with ToolsKit", subtitle: "SDK and workflow tools", icon: "hammer.fill", color: .orange, destination: SDKHomeView())
                navTile("App Builder", subtitle: "Visual assembly", icon: "wand.and.stars", color: .pink, destination: SDKBuildView())
                navTile("Connectors", subtitle: "External integrations", icon: "cable.connector", color: .green, destination: ConnectorsMainView())
                navTile("Marketplace", subtitle: "Discover packages", icon: "cart.fill", color: .indigo, destination: MarketplaceView())
                navTile("Installed", subtitle: "Manage local plugins", icon: "puzzlepiece.extension.fill", color: .teal, destination: PluginsInstalledView())
                navTile("Dev Console", subtitle: "Runtime diagnostics", icon: "terminal.fill", color: .purple, destination: PluginDevConsoleView())
                navTile("Security", subtitle: "Scopes and policies", icon: "shield.fill", color: .red, destination: PluginSecurityView())
            }
        }
    }

    private var activePluginsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Plugins").font(.title3.weight(.semibold))
            let enabled = manager.installedPlugins.filter(\.isEnabled)
            if enabled.isEmpty {
                ContentUnavailableView("No Active Plugins", systemImage: "puzzlepiece", description: Text("Enable installed plugins in the Plugin Manager."))
            } else {
                ForEach(enabled) { plugin in
                    NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                        HStack(spacing: 12) {
                            Image(systemName: plugin.icon)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plugin.name).font(.subheadline.weight(.semibold))
                                Text(plugin.capabilities.map(\.displayName).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("Running")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.green.opacity(0.15), in: Capsule())
                                .foregroundStyle(.green)
                        }
                        .padding(12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity").font(.title3.weight(.semibold))
            if recentEvents.isEmpty {
                Text("No recent activity").font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(recentEvents.prefix(5)) { event in
                    HStack {
                        Label("\(event.capability.rawValue).\(event.action)", systemImage: event.capability.icon)
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statCard(_ title: String, value: Int, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func navTile<Destination: View>(_ title: String, subtitle: String, icon: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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

struct StatusIndicator: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)").font(.title2.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


enum PluginStatus {
    case running
    case stopped
    case error
}

struct PluginStatusPill: View {
    let status: PluginStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .running: "Running"
        case .stopped: "Stopped"
        case .error: "Error"
        }
    }

    private var color: Color {
        switch status {
        case .running: .green
        case .stopped: .secondary
        case .error: .red
        }
    }
}
