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
            filterPicker

            consoleOutput

            controls
        }
        .navigationTitle("Developer Console")
        .onAppear(perform: setupLogging)
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(LogFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private var consoleOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if filteredLogs.isEmpty {
                        Text("No logs to display")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredLogs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Text(log.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)

                                Text(log.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(log.type.color)
                            }
                            .id(log.id)
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: logs.count) { _, _ in
                if let last = logs.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .background(Color.black)
    }

    private var controls: some View {
        HStack {
            Button(action: injectTestEvent) {
                Label("Test Event", systemImage: "bolt.fill")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Clear") {
                logs.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
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
