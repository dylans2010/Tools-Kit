import SwiftUI

private struct _DTConfigEntry: Identifiable, Hashable {
    let id = UUID()
    let key: String
    var value: String
    init(key: String, value: String) {
        self.key = key; self.value = value
    }
}

private class _DTConfigManager: ObservableObject {
    static let shared = _DTConfigManager()
    @Published var entries: [_DTConfigEntry] = []
    @Published var changes: [_DTConfigEntry] = []
    private init() {}
}

struct SDKConfigValidatorDevTool: DevTool {
    let id = "sdk-config-validator"
    let name = "Config Validator"
    let category = DevToolCategory.debugging
    let icon = "checkmark.shield.fill"
    let description = "Validate SDK configuration entries"

    func render() -> some View {
        SDKConfigValidatorView()
    }
}

struct SDKConfigValidatorView: View {
    @StateObject private var config = _DTConfigManager.shared
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section("Validation Overview") {
                HStack(spacing: 12) {
                    ConfigStatusCard(label: "Healthy", count: config.entries.count, color: .green)
                    ConfigStatusCard(label: "Overrides", count: config.changes.count, color: .orange)
                    ConfigStatusCard(label: "Conflicts", count: 0, color: .red)
                }
                .padding(.vertical, 8)
            }

            Section("Live Parameters Index") {
                if config.entries.isEmpty {
                    ContentUnavailableView("No Configs", systemImage: "gearshape.fill", description: Text("Runtime configurations will appear here once loaded."))
                } else {
                    ForEach(config.entries.sorted(by: { $0.key < $1.key })) { entry in
                        ConfigEntryRow(entry: entry)
                    }
                }
            }

            Section("Audit Trail") {
                if config.changes.isEmpty {
                    Text("No configuration changes recorded").font(.caption2).foregroundStyle(.secondary)
                } else {
                    ForEach(config.changes.reversed()) { change in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(change.key).font(.caption.bold())
                                Spacer()
                                Text("CHANGED").font(.system(size: 7, weight: .black)).foregroundStyle(.orange)
                            }
                            Text("Modified to: \(change.value)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                Button { showingAddSheet = true } label: {
                    Label("Add Parameter Override", systemImage: "plus.circle.fill")
                }
                Button("Force Reload from Disk") { /* Logic */ }
                Button(role: .destructive) { config.changes.removeAll() } label: {
                    Label("Clear Audit Trail", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Config Lab")
    }
}

struct ConfigStatusCard: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
            Text("\(count)").font(.title3.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ConfigEntryRow: View {
    let entry: _DTConfigEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.key).font(.subheadline.bold())
                Text(entry.value).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
        }
    }
}

#Preview {
    SDKConfigValidatorView()
}
