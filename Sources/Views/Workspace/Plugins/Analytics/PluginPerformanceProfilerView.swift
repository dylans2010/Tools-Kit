import SwiftUI

struct PluginPerformanceProfilerView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @State private var selectedPluginID: UUID?

    var body: some View {
        List {
            Section("System Context") {
                LabeledContent("Active Plugins", value: "\(manager.plugins.filter(\.isEnabled).count)")
                LabeledContent("Avg Latency (Global)", value: "\(Int(telemetry.getMetrics().averageDurationMs))ms")
            }

            Section("Plugin Performance Registry") {
                if manager.plugins.isEmpty {
                    Text("No plugins installed").foregroundStyle(.secondary)
                } else {
                    ForEach(manager.plugins) { plugin in
                        PluginPerfRow(plugin: plugin, isSelected: selectedPluginID == plugin.id)
                            .onTapGesture {
                                withAnimation { selectedPluginID = (selectedPluginID == plugin.id ? nil : plugin.id) }
                            }
                    }
                }
            }

            if let selectedID = selectedPluginID, let plugin = manager.plugins.first(where: { $0.id == selectedID }) {
                Section("Metadata Analysis: \(plugin.name)") {
                    VStack(alignment: .leading, spacing: 16) {
                        StatRow(label: "Permissions", value: "\(plugin.permissions.count)")
                        StatRow(label: "Hooks", value: "\(plugin.automationHooks.count)")
                        StatRow(label: "Tools", value: "\(plugin.tools.count)")
                    }
                    .padding(.vertical, 8)
                }

                Section("Security Profile") {
                    if plugin.permissions.contains(.all) {
                        Label("Critical: Wildcard permissions detected.", systemImage: "exclamationmark.shield.fill")
                            .foregroundStyle(.red)
                    } else if plugin.permissions.count > 3 {
                        Label("High: Multiple sensitive scopes requested.", systemImage: "shield.fill")
                            .foregroundStyle(.orange)
                    } else {
                        Label("Normal: Minimal permission profile.", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .navigationTitle("Performance Profiler")
    }
}

private struct PluginPerfRow: View {
    let plugin: SDKPlugin
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name).font(.subheadline.bold())
                Text("v\(plugin.version)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Circle().fill(plugin.isEnabled ? .green : .secondary).frame(width: 6, height: 6)
                Text(plugin.isEnabled ? "Enabled" : "Disabled").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.headline.monospaced())
        }
    }
}
