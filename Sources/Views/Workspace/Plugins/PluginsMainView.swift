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
            VStack(alignment: .leading, spacing: 24) {
                pluginStatsCard

                SDKSectionHeader("Management", subtitle: "Core plugin development and deployment", systemImage: "hammer.fill")
                navigationGrid

                SDKSectionHeader("Active Plugins", subtitle: "Currently running in the background", systemImage: "bolt.fill")
                activePluginsCard

                SDKSectionHeader("Recent Activity", subtitle: "Latest capability execution events", systemImage: "list.bullet.rectangle.fill")
                recentActivityCard
            }
            .padding()
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

    private var pluginStatsCard: some View {
        SDKModernCard(padding: 12, content: {
            HStack(spacing: 0) {
                SDKStatPill(label: "Active", value: "\(manager.installedPlugins.filter(\.isEnabled).count)", color: .sdkSuccess)
                SDKStatPill(label: "Disabled", value: "\(manager.installedPlugins.filter { !$0.isEnabled }.count)", color: .secondary)
                SDKStatPill(label: "Errors", value: "\(manager.installedPlugins.reduce(0) { $0 + $1.errorCount })", color: .sdkError)
            }
        }
    }

    private var navigationGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            navLinkCard("Create Plugin", "plus.circle.fill", .blue, PluginBuildView())
            navLinkCard("Build with ToolsKit", "hammer.fill", .orange, SDKHomeView())
            navLinkCard("App Builder", "wand.and.stars", .pink, SDKBuildView())
            navLinkCard("Connectors", "puzzlepiece.extension", .green, ConnectorsMainView())
            navLinkCard("Marketplace", "cart.fill", .orange, MarketplaceView())
            navLinkCard("Installed", "puzzlepiece.extension.fill", .indigo, PluginsInstalledView())
            navLinkCard("Dev Console", "terminal.fill", .purple, PluginDevConsoleView())
            navLinkCard("Security", "shield.fill", .red, PluginSecurityView())
        }
    }

    private var activePluginsCard: some View {
        VStack(spacing: 12) {
            if manager.installedPlugins.filter(\.isEnabled).isEmpty {
                ContentUnavailableView("No Active Plugins", systemImage: "puzzlepiece", description: Text("Enable installed plugins in the Plugin Manager."))
                    .padding(.vertical, 20)
            } else {
                ForEach(manager.installedPlugins.filter(\.isEnabled)) { plugin in
                    NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                        SDKModernCard(padding: 12, content: {
                            HStack(spacing: 12) {
                                Image(systemName: plugin.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plugin.name).font(.subheadline.bold())
                                    Text(plugin.capabilities.map(\.displayName).joined(separator: ", "))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                SDKStatusPill("Running", color: .sdkSuccess)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity").font(.headline)
            if recentEvents.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private func navLinkCard<Destination: View>(_ title: String, _ icon: String, _ color: Color, _ destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            SDKActionTile(title, subtitle: "Manage system \(title.lowercased())", systemImage: icon, color: color) {}
        }
        .buttonStyle(.plain)
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
