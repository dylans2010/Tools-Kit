import SwiftUI
import OSLog

struct Diag_SystemLogView: View {
    @State private var logs: [LogEntry] = []
    @State private var isLoading = false
    @State private var selectedLevel: LogLevel = .all
    @State private var searchText: String = ""
    @State private var maxEntries: Int = 100

    enum LogLevel: String, CaseIterable {
        case all = "All"
        case error = "Error"
        case fault = "Fault"
        case info = "Info"
        case debug = "Debug"
    }

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: String
        let category: String
        let message: String
        let subsystem: String
    }

    var filteredLogs: [LogEntry] {
        var result = logs
        if selectedLevel != .all {
            result = result.filter { $0.level.lowercased() == selectedLevel.rawValue.lowercased() }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.message.lowercased().contains(query) ||
                $0.category.lowercased().contains(query) ||
                $0.subsystem.lowercased().contains(query)
            }
        }
        return result
    }

    var body: some View {
        Form {
            Section("Filters") {
                Picker("Level", selection: $selectedLevel) {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Search logs...", text: $searchText)
                    .textInputAutocapitalization(.never)
            }

            Section("Statistics") {
                LabeledContent("Total Entries") { Text("\(logs.count)") }
                LabeledContent("Errors") {
                    Text("\(logs.filter { $0.level == "Error" }.count)")
                        .foregroundStyle(.red)
                }
                LabeledContent("Faults") {
                    Text("\(logs.filter { $0.level == "Fault" }.count)")
                        .foregroundStyle(.purple)
                }
                LabeledContent("Filtered") { Text("\(filteredLogs.count)") }
            }

            Section("Log Entries (\(filteredLogs.count))") {
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading logs...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if filteredLogs.isEmpty {
                    Text("No log entries found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredLogs.prefix(50), id: \.id) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(levelColor(entry.level))
                                    .frame(width: 8, height: 8)
                                Text(entry.level)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(levelColor(entry.level))
                                Spacer()
                                Text(entry.timestamp, style: .time)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                            Text(entry.message)
                                .font(.caption)
                                .lineLimit(3)
                            if !entry.subsystem.isEmpty {
                                Text("\(entry.subsystem) / \(entry.category)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                Button {
                    loadLogs()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(isLoading ? "Loading..." : "Refresh Logs")
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("System Log")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadLogs() }
    }

    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "error": return .red
        case "fault": return .purple
        case "info": return .blue
        case "debug": return .gray
        case "notice": return .orange
        default: return .secondary
        }
    }

    private func loadLogs() {
        isLoading = true
        logs = []

        DispatchQueue.global(qos: .userInitiated).async {
            var entries: [LogEntry] = []

            if #available(iOS 15.0, *) {
                do {
                    let store = try OSLogStore(scope: .currentProcessIdentifier)
                    let position = store.position(timeIntervalSinceEnd: -300) // Last 5 minutes
                    let predicate = NSPredicate(format: "subsystem != ''")
                    let logEntries = try store.getEntries(at: position, matching: predicate)

                    for entry in logEntries.prefix(maxEntries) {
                        if let logEntry = entry as? OSLogEntryLog {
                            entries.append(LogEntry(
                                timestamp: logEntry.date,
                                level: levelString(logEntry.level),
                                category: logEntry.category,
                                message: logEntry.composedMessage,
                                subsystem: logEntry.subsystem
                            ))
                        }
                    }
                } catch {
                    entries.append(LogEntry(
                        timestamp: Date(),
                        level: "Info",
                        category: "System",
                        message: "Log access requires entitlement. Showing process logs only.",
                        subsystem: "com.tools-kit"
                    ))
                }
            }

            // Add some system info as fallback
            if entries.isEmpty {
                entries.append(LogEntry(timestamp: Date(), level: "Info", category: "System", message: "Device: \(UIDevice.current.model) running iOS \(UIDevice.current.systemVersion)", subsystem: "system"))
                entries.append(LogEntry(timestamp: Date(), level: "Info", category: "Memory", message: "Physical RAM: \(ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))", subsystem: "system"))
                entries.append(LogEntry(timestamp: Date(), level: "Info", category: "Thermal", message: "Thermal state: \(ProcessInfo.processInfo.thermalState.rawValue)", subsystem: "system"))
            }

            DispatchQueue.main.async {
                self.logs = entries
                self.isLoading = false
            }
        }
    }

    @available(iOS 15.0, *)
    private func levelString(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .undefined: return "Undefined"
        case .debug: return "Debug"
        case .info: return "Info"
        case .notice: return "Notice"
        case .error: return "Error"
        case .fault: return "Fault"
        @unknown default: return "Unknown"
        }
    }
}
