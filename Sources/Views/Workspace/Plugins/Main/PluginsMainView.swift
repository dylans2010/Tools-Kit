/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style as the root navigation container.
 - Replaced manual stat cards with a centered StatHeader section using SDKStatPill.
 - Modernized the Management grid using a private ManagementGridSection with native navigation tiles.
 - Replaced manual active plugin rows with a dedicated ActivePluginsSection using standardized icon styling.
 - Standardized the "Running" pill using native semantic backgrounds and typography.
 - strictly preserved all PluginEventBus subscriptions and blocked execution notification logic.
 - Replaced manual activity rows with Label-based activity entries.
 - Improved visual hierarchy for empty states and destructive triggers.
 - Extracted subviews for StatHeader, ManagementGrid, ActivePlugins, and RecentActivity.
 */

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
        List {
            Section {
                PluginsStatHeader(manager: manager)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            Section("Management") {
                PluginsManagementGrid()
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            Section("Active Extensions") {
                ActivePluginsSection(manager: manager)
            }

            Section("Activity Stream") {
                RecentActivitySection(events: recentEvents)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plugins")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: PluginsInstalledView()) {
                    Label("Settings", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .onAppear(perform: setupActivityStream)
        .onAppear(perform: setupBlockedExecutionListener)
        .sheet(isPresented: $showingLimitedView) {
            if let plugin = blockedPlugin {
                NavigationStack {
                    PluginLimitedView(plugin: plugin, reason: blockedReason, detail: blockedDetail)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
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

// MARK: - Private Subviews

private struct PluginsStatHeader: View {
    @ObservedObject var manager: PluginManager
    var body: some View {
        HStack(spacing: 0) {
            SDKStatPill(label: "Active", value: "\(manager.installedPlugins.filter(\.isEnabled).count)", color: .sdkSuccess)
            SDKStatPill(label: "Disabled", value: "\(manager.installedPlugins.filter { !$0.isEnabled }.count)", color: .secondary)
            SDKStatPill(label: "Errors", value: "\(manager.installedPlugins.reduce(0) { $0 + $1.errorCount })", color: .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct PluginsManagementGrid: View {
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            NavTile(title: "Builder", icon: "plus.circle.fill", color: .blue, destination: PluginBuildView())
            NavTile(title: "SDK Home", icon: "hammer.fill", color: .orange, destination: SDKHomeView())
            NavTile(title: "Connectors", icon: "cable.connector", color: .green, destination: ConnectorsMainView())
            NavTile(title: "Marketplace", icon: "cart.fill", color: .indigo, destination: MarketplaceView())
            NavTile(title: "Installed", icon: "puzzlepiece.extension.fill", color: .teal, destination: PluginsInstalledView())
            NavTile(title: "Console", icon: "terminal.fill", color: .purple, destination: PluginDevConsoleView())
            NavTile(title: "Security", icon: "shield.fill", color: .red, destination: PluginSecurityView())
            NavTile(title: "Builder UI", icon: "wand.and.stars", color: .pink, destination: SDKBuildView())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct NavTile<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.headline).foregroundStyle(color)
                Text(title).font(.caption.bold()).foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ActivePluginsSection: View {
    @ObservedObject var manager: PluginManager
    var body: some View {
        let enabled = manager.installedPlugins.filter(\.isEnabled)
        if enabled.isEmpty {
            ContentUnavailableView("No Active Extensions", systemImage: "puzzlepiece", description: Text("Enable installed plugins in the settings to see them here."))
        } else {
            ForEach(enabled) { plugin in
                NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                    HStack(spacing: 12) {
                        Image(systemName: plugin.icon)
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plugin.name).font(.subheadline.bold())
                            Text(plugin.capabilities.map(\.displayName).joined(separator: ", "))
                                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Text("RUNNING")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.sdkSuccess.opacity(0.1), in: Capsule())
                            .foregroundStyle(.sdkSuccess)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct RecentActivitySection: View {
    let events: [PluginEvent]
    var body: some View {
        if events.isEmpty {
            Text("No recent activity recorded.").font(.caption).foregroundStyle(.secondary)
        } else {
            ForEach(events.prefix(10)) { event in
                HStack {
                    Label("\(event.capability.rawValue).\(event.action)", systemImage: event.capability.icon)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(event.timestamp.formatted(.relative(presentation: .named)))
                        .font(.system(size: 9)).foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
