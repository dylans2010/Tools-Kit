
import SwiftUI

struct ConnectorDebuggerView: View {
    @StateObject private var manager = ConnectorManager.shared

    var body: some View {
        List {
            Section("Recent Request Traffic") {
                if manager.logs.isEmpty {
                    ContentUnavailableView("No Traffic", systemImage: "network.slash")
                } else {
                    ForEach(manager.logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.type.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .bold)).padding(4).background(color(for: log.type).opacity(0.1)).foregroundStyle(color(for: log.type))
                                Spacer()
                                Text(log.timestamp.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(log.message).font(.subheadline)
                            if let details = log.details {
                                Text(details).font(.system(.caption2, design: .monospaced)).foregroundStyle(.tertiary).lineLimit(2)
                            }
                        }
                    }
                }
            }

            Button("Clear History", role: .destructive) { manager.clearAllLogs() }
        }
        .navigationTitle("Network Debugger")
    }

    private func color(for type: ConnectorLog.LogType) -> Color {
        switch type {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .performance: return .purple
        }
    }
}
