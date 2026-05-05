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
                pluginStatsCard
                navigationGrid
                activePluginsCard
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
        HStack(spacing: 16) {
            StatusIndicator(label: "Active", count: manager.installedPlugins.filter(\.isEnabled).count, color: .green)
            StatusIndicator(label: "Disabled", count: manager.installedPlugins.filter { !$0.isEnabled }.count, color: .secondary)
            StatusIndicator(label: "Errors", count: manager.installedPlugins.reduce(0) { $0 + $1.errorCount }, color: .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var navigationGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            navLinkCard("Create Plugin", "plus.circle.fill", .blue, PluginBuildView())
            navLinkCard("Connectors", "puzzlepiece.extension", .green, ConnectorsMainView())
            navLinkCard("Marketplace", "cart.fill", .orange, MarketplaceView())
            navLinkCard("Installed", "puzzlepiece.extension.fill", .indigo, PluginsInstalledView())
            navLinkCard("Dev Console", "terminal.fill", .purple, PluginDevConsoleView())
            navLinkCard("Security", "shield.fill", .red, PluginSecurityView())
        }
    }

    private var activePluginsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Plugins").font(.headline)
            if manager.installedPlugins.filter(\.isEnabled).isEmpty {
                Text("No active plugins")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(manager.installedPlugins.filter(\.isEnabled)) { plugin in
                    NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                        HStack(spacing: 10) {
                            Image(systemName: plugin.icon)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.name).font(.subheadline.weight(.semibold))
                                Text(plugin.capabilities.map(\.displayName).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            PluginStatusPill(status: .running)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(color).font(.title3)
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
