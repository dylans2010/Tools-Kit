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
            VStack(spacing: 24) {
                SDKSectionHeader(
                    title: "Plugin Ecosystem",
                    subtext: "Extend your workspace with sandboxed logic and intelligence modules.",
                    isCentered: true
                )

                SDKModernCard {
                    HStack(spacing: 0) {
                        StatusIndicator(label: "Active", count: manager.installedPlugins.filter(\.isEnabled).count, color: .green)
                        Divider().padding(.vertical, 4)
                        StatusIndicator(label: "Disabled", count: manager.installedPlugins.filter { !$0.isEnabled }.count, color: .secondary)
                        Divider().padding(.vertical, 4)
                        StatusIndicator(label: "Errors", count: manager.installedPlugins.reduce(0) { $0 + $1.errorCount }, color: .red)
                    }
                }

                SDKSectionHeader(title: "Management & Discovery", subtext: "Build and browse platform extensions.")

                LazyVGrid(columns: columns, spacing: 12) {
                    navLinkCard("Marketplace", "cart.fill", .orange, MarketplaceView())
                    navLinkCard("Connectors", "puzzlepiece.extension", .green, ConnectorsMainView())
                    navLinkCard("App Builder", "wand.and.stars", .pink, SDKBuildView())
                    navLinkCard("IDE Workspace", "hammer.fill", .indigo, SDKHomeView())
                }

                SDKSectionHeader(title: "Active Plugins", subtext: "Currently running in the workspace runtime.")

                VStack(spacing: 12) {
                    let active = manager.installedPlugins.filter(\.isEnabled)
                    if active.isEmpty {
                        SDKModernCard {
                            Text("No active plugins").sdkSubtext().frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(active) { plugin in
                            NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                                SDKModernCard {
                                    HStack(spacing: 12) {
                                        Image(systemName: plugin.icon)
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .frame(width: 36, height: 36)
                                            .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(plugin.name).font(.subheadline.bold())
                                            Text(plugin.capabilities.map(\.displayName).joined(separator: ", "))
                                                .sdkSubtext().lineLimit(1)
                                        }
                                        Spacer()
                                        SDKStatusPill(status: .success, text: "RUNNING")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SDKSectionHeader(title: "Recent Activity", subtext: "Plugin event bus stream.")

                SDKModernCard {
                    VStack(alignment: .leading, spacing: 10) {
                        if recentEvents.isEmpty {
                            Text("No recent activity").sdkSubtext().frame(maxWidth: .infinity)
                        } else {
                            ForEach(recentEvents.prefix(5)) { event in
                                HStack {
                                    Label("\(event.capability.rawValue).\(event.action)", systemImage: event.capability.icon)
                                        .font(.caption.bold())
                                    Spacer()
                                    Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if event.id != recentEvents.prefix(5).last?.id { Divider() }
                            }
                        }
                    }
                }
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
            SDKModernCard {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: icon).foregroundStyle(color).font(.title3)
                    Text(title).font(.caption.bold()).foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
