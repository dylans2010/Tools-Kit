import SwiftUI

struct MCPDebugConsole: View {
    @StateObject private var mcpManager = MCPManager.shared
    @State private var filterText = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(mcpManager.servers) { server in
                    Section("Server: \(server.name)") {
                        if let logs = server.trafficLogs, !logs.isEmpty {
                            ForEach(logs.filter { filterText.isEmpty || $0.payload.localizedCaseInsensitiveContains(filterText) }) { log in
                                LogEntryRow(log: log)
                            }
                        } else {
                            Text("No packets captured.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("MCP Debug Console")
            .searchable(text: $filterText, prompt: "Filter packets...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All") {
                        for i in 0..<mcpManager.servers.count {
                            mcpManager.servers[i].trafficLogs = []
                        }
                    }
                }
            }
        }
    }
}

struct LogEntryRow: View {
    let log: MCPTrafficLog
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: log.direction == .request ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(log.direction == .request ? .blue : .green)

                Text(log.method ?? "NOTIFY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))

                Spacer()

                Text(log.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Text(log.payload)
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(isExpanded ? nil : 2)
                .onTapGesture {
                    withAnimation { isExpanded.toggle() }
                }
        }
        .padding(.vertical, 4)
    }
}
