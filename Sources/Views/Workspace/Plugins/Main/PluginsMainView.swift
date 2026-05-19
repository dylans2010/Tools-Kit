import SwiftUI
import Combine

struct PluginsMainView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @State private var recentEvents: [PluginEvent] = []
    @State private var cancellables = Set<AnyCancellable>()

    @State private var blockedPlugin: SDKPlugin?
    @State private var blockedReason: PluginValidationFailureReason = .capabilityMismatch
    @State private var blockedDetail = ""
    @State private var showingLimitedView = false
    @State private var showingConfigSheet = false
    @State private var selectedPlugin: SDKPlugin?

    var enabledPlugins: [SDKPlugin] {
        manager.plugins.filter(\.isEnabled)
    }

    var disabledPlugins: [SDKPlugin] {
        manager.plugins.filter { !$0.isEnabled }
    }

    var errorPlugins: [SDKPlugin] {
        [] // TODO: errorCount unavailable on SDKPlugin
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 20) {
                        PluginMetric(label: "Active", value: "\(enabledPlugins.count)", color: .green)
                        PluginMetric(label: "Disabled", value: "\(disabledPlugins.count)", color: .secondary)
                        PluginMetric(label: "Errors", value: "0", color: .red)
                    }
                    .padding(.vertical, 8)
                }

                if !manager.plugins.isEmpty {
                    Section("Installed Plugins") {
                        ForEach(manager.plugins) { plugin in
                            PluginStateRow(
                                plugin: plugin,
                                onToggle: {
                                    if plugin.isEnabled {
                                        manager.disable(id: plugin.id)
                                    } else {
                                        manager.enable(id: plugin.id)
                                    }
                                },
                                onConfigure: {
                                    selectedPlugin = plugin
                                    showingConfigSheet = true
                                }
                            )
                        }
                    }
                }

                Section("Tools & Marketplace") {
                    NavigationLink(destination: MarketplaceView()) {
                        Label("Marketplace", systemImage: "storefront.fill")
                    }
                    NavigationLink(destination: PluginBuildView()) {
                        Label("Plugin Builder", systemImage: "hammer.fill")
                    }
                    NavigationLink(destination: PluginDevConsoleView()) {
                        Label("Developer Console", systemImage: "terminal.fill")
                    }
                }

                Section("Management") {
                    NavigationLink(destination: ConnectorsMainView()) {
                        Label("Connector Bridges", systemImage: "cable.connector")
                    }
                    NavigationLink(destination: PluginSecurityView()) {
                        Label("Security & Sandboxing", systemImage: "shield.lefthalf.filled")
                    }
                }

                if !recentEvents.isEmpty {
                    Section("Recent Activity") {
                        ForEach(recentEvents.prefix(10)) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.description)
                                    .font(.caption)
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
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
            .sheet(isPresented: $showingConfigSheet) {
                if let plugin = selectedPlugin {
                    NavigationStack {
                        PluginConfigurationView(plugin: plugin, manager: manager)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
                   let plugin = manager.plugins.first(where: { $0.id == pluginID }),
                   let reason = notification.userInfo?["reason"] as? PluginValidationFailureReason,
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

// MARK: - Plugin State Row

private struct PluginMetric: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold().monospacedDigit()).foregroundStyle(color)
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct PluginStateRow: View {
    let plugin: SDKPlugin
    let onToggle: () -> Void
    let onConfigure: () -> Void

    var stateLabel: String {
        return plugin.isEnabled ? "Enabled" : "Disabled"
    }

    var stateColor: Color {
        return plugin.isEnabled ? .green : .secondary
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "puzzlepiece.extension") // TODO: icon unavailable on SDKPlugin
                    Text(plugin.name).font(.subheadline.bold())
                }
                Text("v\(plugin.version) · \(stateLabel)")
                    .font(.caption)
                    .foregroundStyle(stateColor)
            }

            Spacer()

            Button { onConfigure() } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(
                get: { plugin.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Plugin Configuration View

private struct PluginConfigurationView: View {
    let plugin: SDKPlugin
    let manager: SDKPluginManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Identity") {
                LabeledContent("Name", value: plugin.name)
                LabeledContent("Identifier", value: "com.toolskit.plugin") // TODO: identifier unavailable on SDKPlugin
                LabeledContent("Version", value: plugin.version)
                LabeledContent("Author", value: "Unknown Author") // TODO: author unavailable on SDKPlugin
            }

            Section("State") {
                LabeledContent("Status", value: plugin.isEnabled ? "Enabled" : "Disabled")
                LabeledContent("Installed", value: plugin.installedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Last Executed", value: "Never") // TODO: lastExecutedAt unavailable on SDKPlugin
                LabeledContent("Error Count", value: "0") // TODO: errorCount unavailable on SDKPlugin
            }

            Section("Capabilities") {
                ForEach(plugin.permissions, id: \.self) { capability in
                    HStack {
                        Text(capability.rawValue.capitalized)
                            .font(.caption)
                        Spacer()
                        Text("Permission")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("Actions") {
                ForEach(plugin.automationHooks, id: \.self) { action in
                    Text(action)
                        .font(.caption.monospaced())
                }
            }

            Section {
                Button("Reload Plugin") {
                    manager.disable(id: plugin.id)
                    manager.enable(id: plugin.id)
                }

                Button(role: .destructive) {
                    manager.remove(id: plugin.id)
                    dismiss()
                } label: {
                    Label("Uninstall", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Plugin Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
}
