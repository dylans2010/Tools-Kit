import SwiftUI

struct ConnectorLogsView: View {
    var connectorID: UUID?
    @StateObject private var manager = ConnectorManager.shared
    @State private var filter: LogFilter = .all

    enum LogFilter: String, CaseIterable {
        case all = "All"
        case errors = "Errors"
        case performance = "Performance"
    }

    var filteredLogs: [ConnectorLog] {
        let base = connectorID == nil ? manager.logs : manager.logs.filter { $0.connectorID == connectorID }
        switch filter {
        case .all: return base
        case .errors: return base.filter { $0.type == .error }
        case .performance: return base.filter { $0.type == .performance }
        }
    }

    var body: some View {
        VStack {
            Picker("Filter", selection: $filter) {
                ForEach(LogFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                if filteredLogs.isEmpty {
                    Text("No logs found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(filteredLogs) { log in
                        logRow(log)
                    }
                }
            }
        }
        .navigationTitle(connectorID == nil ? "Global Logs" : "Execution Logs")
    }

    private func logRow(_ log: ConnectorLog) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.type.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(logTypeColor(log.type).opacity(0.15))
                    .foregroundColor(logTypeColor(log.type))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                Text(log.timestamp.formatted(date: .omitted, time: .standard))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(log.message)
                .font(.subheadline.bold())

            if let details = log.details {
                Text(details)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }

    private func logTypeColor(_ type: ConnectorLog.LogType) -> Color {
        switch type {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .performance: return .purple
        }
    }
}
