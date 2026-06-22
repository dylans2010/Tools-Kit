import SwiftUI

struct LMStudioLogsView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var filter: LogLevel? = nil

    var filteredLogs: [SDKLogStore.LogEntry] {
        let localLogs = logStore.logs.filter {
            $0.source.contains("LM") || $0.source.contains("AI") || $0.source.contains("Local")
        }
        if let filter = filter {
            return localLogs.filter { $0.level == filter }
        }
        return localLogs
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    Text("All").tag(Optional<LogLevel>.none)
                    Text("Info").tag(Optional(LogLevel.info))
                    Text("Warning").tag(Optional(LogLevel.warning))
                    Text("Error").tag(Optional(LogLevel.error))
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            if filteredLogs.isEmpty {
                Section {
                    Text("No local model logs captured.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else {
                ForEach(filteredLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.source)
                                .font(.caption2.bold())
                                .foregroundColor(.blue)
                            Spacer()
                            Text(log.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Text(log.message)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(color(for: log.level))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("System Logs")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Clear") {
                    logStore.clear()
                }
            }
        }
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        case .debug: return .secondary
        }
    }
}
