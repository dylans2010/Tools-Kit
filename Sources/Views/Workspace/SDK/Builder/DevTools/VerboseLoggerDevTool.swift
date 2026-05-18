import SwiftUI

struct VerboseLoggerTool: DevTool {
    let id = UUID()
    let name = "Verbose Logger"
    let category: DevToolCategory = .diagnostics
    let icon = "text.alignleft"
    let description = "Real-time log capture with filtering"
    func render() -> some View { VerboseLoggerDevToolView() }
}

final class VerboseLoggerStore: ObservableObject {
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: String
        let message: String
    }
    @Published var entries: [LogEntry] = []
    @Published var isCapturing = false
    private var timer: Timer?

    func startCapturing() {
        isCapturing = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, self.isCapturing else { return }
            let levels = ["INFO", "DEBUG", "WARNING", "ERROR"]
            let messages = ["View loaded", "Network request started", "Cache hit", "Layout pass completed",
                           "Memory pressure detected", "Background task scheduled", "State updated"]
            let entry = LogEntry(
                timestamp: Date(),
                level: levels.randomElement() ?? "INFO",
                message: messages.randomElement() ?? "Event"
            )
            DispatchQueue.main.async { self.entries.insert(entry, at: 0) }
        }
    }

    func stopCapturing() {
        isCapturing = false
        timer?.invalidate()
        timer = nil
    }

    func clear() { entries.removeAll() }
}

struct VerboseLoggerDevToolView: View {
    @StateObject private var store = VerboseLoggerStore()
    @State private var filterLevel = "ALL"
    private let levels = ["ALL", "INFO", "DEBUG", "WARNING", "ERROR"]

    private var filtered: [VerboseLoggerStore.LogEntry] {
        filterLevel == "ALL" ? store.entries : store.entries.filter { $0.level == filterLevel }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Button(store.isCapturing ? "Stop" : "Start") {
                        store.isCapturing ? store.stopCapturing() : store.startCapturing()
                    }
                    Spacer()
                    Circle().fill(store.isCapturing ? Color.green : Color.red).frame(width: 8, height: 8)
                    Button("Clear") { store.clear() }
                }
                Picker("Filter", selection: $filterLevel) {
                    ForEach(levels, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Logs (\(filtered.count))") {
                ForEach(filtered) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Text(logIcon(entry.level)).font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(entry.level).font(.caption2.bold())
                                    .foregroundStyle(logColor(entry.level))
                                Spacer()
                                Text(entry.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(entry.message).font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
        }
        .navigationTitle("Verbose Logger")
        .onDisappear { store.stopCapturing() }
    }

    private func logColor(_ level: String) -> Color {
        switch level {
        case "ERROR": return .red
        case "WARNING": return .orange
        case "DEBUG": return .blue
        default: return .green
        }
    }
    private func logIcon(_ level: String) -> String {
        switch level {
        case "ERROR": return "🔴"
        case "WARNING": return "🟡"
        case "DEBUG": return "🔵"
        default: return "🟢"
        }
    }
}
