import SwiftUI
import Combine

struct PluginsMainView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var recentEvents: [PluginEvent] = []
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        List {
            headerSection

            primaryActionsSection

            activePluginsSection

            recentActivitySection

            quickInsightsSection
        }
        .navigationTitle("Plugins")
        .onAppear(perform: setupActivityStream)
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("System Status")
                    .font(.headline)

                HStack(spacing: 20) {
                    StatusIndicator(label: "Active", count: manager.installedPlugins.filter { $0.isEnabled }.count, color: .green)
                    StatusIndicator(label: "Disabled", count: manager.installedPlugins.filter { !$0.isEnabled }.count, color: .secondary)
                    StatusIndicator(label: "Errors", count: manager.installedPlugins.reduce(0) { $0 + $1.errorCount }, color: .red)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var primaryActionsSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: PluginBuildView()) {
                    ActionCard(title: "Create Plugin", icon: "plus.circle.fill", color: .blue)
                }

                NavigationLink(destination: PluginsInstalledView()) {
                    ActionCard(title: "Installed", icon: "puzzlepiece.extension.fill", color: .green)
                }

                NavigationLink(destination: MarketplaceView()) {
                    ActionCard(title: "Marketplace", icon: "cart.fill", color: .orange)
                }

                NavigationLink(destination: PluginDevConsoleView()) {
                    ActionCard(title: "Dev Console", icon: "terminal.fill", color: .purple)
                }
            }
            .padding(.vertical, 8)
            .buttonStyle(.plain)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private var activePluginsSection: some View {
        Section("Active Plugins") {
            if manager.installedPlugins.filter({ $0.isEnabled }).isEmpty {
                Text("No active plugins").foregroundColor(.secondary).font(.subheadline)
            } else {
                ForEach(manager.installedPlugins.filter({ $0.isEnabled })) { plugin in
                    NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                        HStack(spacing: 12) {
                            Image(systemName: plugin.icon)
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 36, height: 36)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.name).font(.subheadline).bold()
                                Text(plugin.capabilities.map { $0.displayName }.joined(separator: ", "))
                                    .font(.caption2).foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                if let lastExec = plugin.lastExecutedAt {
                                    Text(lastExec.formatted(.relative(presentation: .named)))
                                        .font(.caption2).foregroundColor(.tertiary)
                                }
                                PluginStatusPill(status: .running)
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentActivitySection: some View {
        Section("Recent Activity") {
            if recentEvents.isEmpty {
                Text("No recent activity").foregroundColor(.secondary).font(.subheadline)
            } else {
                ForEach(recentEvents.prefix(5)) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.capability.icon)
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(event.capability.rawValue).\(event.action)")
                                .font(.caption.bold())
                            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var quickInsightsSection: some View {
        Section("Quick Insights") {
            LabeledContent("Most Used", value: "Task Scheduler")
            LabeledContent("Top Action", value: "note.created")
            LabeledContent("System Health", value: "98% Stable")
        }
    }

    // MARK: - Helpers

    private func setupActivityStream() {
        PluginEventBus.shared.subscribe { event in
            recentEvents.insert(event, at: 0)
            if recentEvents.count > 20 { recentEvents.removeLast() }
        }
        .store(in: &cancellables)
    }
}

// MARK: - Subviews

struct StatusIndicator: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(title)
                .font(.caption.bold())
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

enum PluginStatus {
    case running, idle, error
}

struct PluginStatusPill: View {
    let status: PluginStatus

    var body: some View {
        Text(statusText)
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch status {
        case .running: return "RUNNING"
        case .idle: return "IDLE"
        case .error: return "ERROR"
        }
    }

    private var statusColor: Color {
        switch status {
        case .running: return .green
        case .idle: return .blue
        case .error: return .red
        }
    }
}
