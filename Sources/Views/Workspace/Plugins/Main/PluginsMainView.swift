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
    @State private var showingConfigSheet = false
    @State private var selectedPlugin: PluginDefinition?

    var enabledPlugins: [PluginDefinition] {
        manager.installedPlugins.filter(\.isEnabled)
    }

    var disabledPlugins: [PluginDefinition] {
        manager.installedPlugins.filter { !$0.isEnabled }
    }

    var errorPlugins: [PluginDefinition] {
        manager.installedPlugins.filter { $0.errorCount > 0 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Plugin State") {
                    LabeledContent("Installed", value: "\(manager.installedPlugins.count)")
                    LabeledContent("Enabled", value: "\(enabledPlugins.count)")
                    LabeledContent("Disabled", value: "\(disabledPlugins.count)")
                    LabeledContent("With Errors", value: "\(errorPlugins.count)")
                    LabeledContent("Recent Events", value: "\(recentEvents.count)")
                }

                if !manager.installedPlugins.isEmpty {
                    Section("Installed Plugins") {
                        ForEach(manager.installedPlugins) { plugin in
                            PluginStateRow(
                                plugin: plugin,
                                onToggle: { manager.toggle(pluginID: plugin.id) },
                                onConfigure: {
                                    selectedPlugin = plugin
                                    showingConfigSheet = true
                                }
                            )
                        }
                    }
                }

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

// MARK: - Plugin State Row

private struct PluginStateRow: View {
    let plugin: PluginDefinition
    let onToggle: () -> Void
    let onConfigure: () -> Void

    var stateLabel: String {
        if plugin.errorCount > 0 { return "Error" }
        return plugin.isEnabled ? "Enabled" : "Disabled"
    }

    var stateColor: Color {
        if plugin.errorCount > 0 { return .red }
        return plugin.isEnabled ? .green : .secondary
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: plugin.icon)
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
    let plugin: PluginDefinition
    let manager: PluginManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Identity") {
                LabeledContent("Name", value: plugin.name)
                LabeledContent("Identifier", value: plugin.identifier)
                LabeledContent("Version", value: plugin.version)
                LabeledContent("Author", value: plugin.author)
            }

            Section("State") {
                LabeledContent("Status", value: plugin.isEnabled ? "Enabled" : "Disabled")
                LabeledContent("Installed", value: plugin.installedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                LabeledContent("Last Executed", value: plugin.lastExecutedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                LabeledContent("Error Count", value: "\(plugin.errorCount)")
            }

            Section("Capabilities") {
                ForEach(plugin.capabilities, id: \.id) { capability in
                    HStack {
                        Text(capability.displayName)
                            .font(.caption)
                        Spacer()
                        Text(capability.riskLevel.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(riskColor(capability.riskLevel))
                    }
                }
            }

            Section("Actions") {
                ForEach(plugin.actions, id: \.rawValue) { action in
                    Text(action.rawValue)
                        .font(.caption.monospaced())
                }
            }

            if !plugin.changelog.isEmpty {
                Section("Changelog") {
                    ForEach(plugin.changelog) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("v\(entry.version)").font(.caption.bold())
                            Text(entry.notes).font(.caption).foregroundStyle(.secondary)
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button("Reload Plugin") {
                    manager.toggle(pluginID: plugin.id)
                    manager.toggle(pluginID: plugin.id)
                }

                Button(role: .destructive) {
                    manager.uninstall(pluginID: plugin.id)
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
