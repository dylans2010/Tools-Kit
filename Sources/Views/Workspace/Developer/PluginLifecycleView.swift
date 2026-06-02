import SwiftUI

struct PluginLifecycleView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Active Plugins") {
                let active = store.plugins.filter { $0.status == .published }
                if active.isEmpty {
                    Text("No active plugins.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(active) { plugin in
                        HStack {
                            Image(systemName: plugin.icon)
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text(plugin.name).font(.subheadline.bold())
                                Text("Running • PID: \(Int.random(in: 1000...9999))").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Stop") {
                                updateStatus(plugin, to: .disabled)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .tint(.red)
                        }
                    }
                }
            }

            Section("Drafts & In Review") {
                let drafts = store.plugins.filter { $0.status == .draft || $0.status == .inReview }
                if drafts.isEmpty {
                    Text("No pending plugins.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(drafts) { plugin in
                        HStack {
                            Image(systemName: plugin.icon)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text(plugin.name).font(.subheadline.bold())
                                Text(plugin.status.rawValue.capitalized).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if plugin.status == .draft {
                                Button("Submit") {
                                    updateStatus(plugin, to: .inReview)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.mini)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Plugin Lifecycle")
    }

    private func updateStatus(_ plugin: DeveloperPlugin, to status: DeveloperPlugin.PluginStatus) {
        var updated = store.plugins
        if let index = updated.firstIndex(where: { $0.id == plugin.id }) {
            updated[index].status = status
            store.savePlugins(updated)
        }
    }
}
