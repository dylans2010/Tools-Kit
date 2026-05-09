/*
 REDESIGN SUMMARY:
 - Standardized on a modern console aesthetic with a dark monospaced output area.
 - Replaced manual filter picker with a native ToolbarItem(placement: .topBarLeading) containing a Menu/Picker.
 - Modernized log rows using a private struct PluginLogLine with semantic color coding.
 - Replaced manual control bar with ToolbarItem(placement: .topBarTrailing) for secondary actions and a bottom bar for primary debugging.
 - strictly preserved all PluginManager logging subscriptions and event injection logic.
 - Added ContentUnavailableView for empty log states.
 - Improved auto-scrolling reliability using ScrollViewProxy.
 */

import SwiftUI
import Combine

struct PluginDevConsoleView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var logs: [PluginLog] = []
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedFilter: LogFilter = .all

    enum LogFilter: String, CaseIterable {
        case all = "All"
        case events = "Events"
        case system = "System"
        case errors = "Errors"
    }

    struct PluginLog: Identifiable {
        let id = UUID()
        let timestamp = Date()
        let type: LogType
        let message: String

        enum LogType {
            case event, system, error

            var color: Color {
                switch self {
                case .event: return .blue
                case .system: return .green
                case .error: return .red
                }
            }
        }
    }

    var filteredLogs: [PluginLog] {
        switch selectedFilter {
        case .all: return logs
        case .events: return logs.filter { $0.type == .event }
        case .system: return logs.filter { $0.type == .system }
        case .errors: return logs.filter { $0.type == .error }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if filteredLogs.isEmpty {
                ContentUnavailableView("No Logs", systemImage: "terminal", description: Text("Plugin activity and system events will appear here."))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(filteredLogs) { log in
                                PluginLogLine(log: log)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .background(Color.black)
                    .onChange(of: logs.count) { _, _ in
                        if let last = filteredLogs.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }

            // Bottom Control Bar
            HStack {
                Button(action: injectTestEvent) {
                    Label("Inject Test Event", systemImage: "bolt.fill")
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(filteredLogs.count) entries")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Dev Console")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(LogFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Label(selectedFilter.rawValue, systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { logs.removeAll() } label: {
                    Label("Clear", systemImage: "trash")
                }
            }
        }
        .onAppear(perform: setupLogging)
    }

    private func setupLogging() {
        appendLog(.system, "Plugin Runtime Initialized.")
        appendLog(.system, "Sandbox security layers active.")

        PluginEventBus.shared.subscribe { event in
            appendLog(.event, "EVENT: \(event.capability.rawValue).\(event.action)")
        }
        .store(in: &cancellables)
    }

    private func appendLog(_ type: PluginLog.LogType, _ message: String) {
        logs.append(PluginLog(type: type, message: message))
        if logs.count > 500 { logs.removeFirst() }
    }

    private func injectTestEvent() {
        let event = PluginEvent(
            id: UUID(),
            capability: .notes,
            action: "note.created",
            payload: ["id": UUID().uuidString, "title": "Debug Note"],
            timestamp: Date()
        )
        appendLog(.system, "Injecting test event...")
        PluginEventBus.shared.emit(event)
    }
}

private struct PluginLogLine: View {
    let log: PluginDevConsoleView.PluginLog
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log.timestamp.formatted(date: .omitted, time: .standard))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(log.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(log.type.color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 1)
    }
}
