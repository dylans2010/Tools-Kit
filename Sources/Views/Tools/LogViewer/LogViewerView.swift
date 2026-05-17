import SwiftUI

struct LogViewerView: View {
    @StateObject private var backend = LogViewerBackend()
    @State private var showingAddLog = false
    @State private var newLogMessage = ""
    @State private var newLogLevel: LogViewerLevel = .info

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Filter", selection: $backend.selectedFilter) {
                    Text("All").tag(LogViewerLevel?.none)
                    ForEach(LogViewerLevel.allCases) { level in
                        Text(level.rawValue).tag(LogViewerLevel?.some(level))
                    }
                }
                .pickerStyle(.menu)
                .buttonStyle(.bordered)

                Spacer()

                Button(action: { showingAddLog = true }) {
                    Label("Add Log", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            List {
                if backend.filteredEntries.isEmpty {
                    Text("No logs found.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(backend.filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.level.symbol)
                                Text(entry.level.rawValue.uppercased())
                                    .font(.caption.bold())
                                    .foregroundColor(colorForLevel(entry.level))
                                Spacer()
                                Text(entry.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Text(entry.message)
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)

            HStack {
                Button("Clear All", role: .destructive) {
                    backend.clearLogs()
                }
                Spacer()
                Button(action: {
                    let logStr = backend.entries.map { "[\($0.level.rawValue)] \($0.message)" }.joined(separator: "\n")
                    UIPasteboard.general.string = logStr
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(backend.entries.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Log Viewer")
        .sheet(isPresented: $showingAddLog) {
            NavigationStack {
                Form {
                    Picker("Level", selection: $newLogLevel) {
                        ForEach(LogViewerLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    TextField("Log message...", text: $newLogMessage)
                }
                .navigationTitle("New Log Entry")
                .toolbar {
                    Button("Cancel") { showingAddLog = false }
                    Button("Add") {
                        backend.addLog(newLogMessage, level: newLogLevel)
                        newLogMessage = ""
                        showingAddLog = false
                    }
                    .disabled(newLogMessage.isEmpty)
                }
            }
        }
        .onAppear {
            if backend.entries.isEmpty {
                backend.addLog("Log session initialized.")
                backend.addLog("Network subsystem ready.", level: .debug)
            }
        }
    }

    private func colorForLevel(_ level: LogViewerLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .debug: return .purple
        }
    }
}

struct LogViewerTool: Tool {
    let name = "Log Viewer"
    let icon = "list.bullet.rectangle"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Simulated system log viewer with filtering and export capabilities"
    let requiresAPI = false
    var view: AnyView { AnyView(LogViewerView()) }
}
