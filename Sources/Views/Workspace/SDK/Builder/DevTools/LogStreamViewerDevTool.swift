import SwiftUI
import OSLog

struct LogStreamViewerTool: DevTool {
    let id = UUID()
    let name = "Log Stream Viewer"
    let category: DevToolCategory = .debugging
    let icon = "text.line.first.and.arrowtriangle.forward"
    let description = "Stream system logs in real-time"
    func render() -> some View { LogStreamViewerDevToolView() }
}

struct LogStreamViewerDevToolView: View {
    @State private var entries: [(Date, String, String)] = []
    @State private var isStreaming = false
    @State private var timer: Timer?
    @State private var filterText = ""
    @State private var maxEntries: Double = 100

    private var filtered: [(Date, String, String)] {
        if filterText.isEmpty { return entries }
        return entries.filter { $0.1.lowercased().contains(filterText.lowercased()) || $0.2.lowercased().contains(filterText.lowercased()) }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Button(isStreaming ? "Stop" : "Stream") {
                        isStreaming ? stopStreaming() : startStreaming()
                    }
                    Spacer()
                    Circle().fill(isStreaming ? Color.green : Color.red).frame(width: 8, height: 8)
                    Button("Clear") { entries.removeAll() }
                }
                LabeledContent("Buffer: \(Int(maxEntries))") { Slider(value: $maxEntries, in: 50...500, step: 50) }
            }
            Section("Log Stream (\(filtered.count))") {
                ForEach(Array(filtered.prefix(Int(maxEntries)).enumerated()), id: \.offset) { _, entry in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(entry.1)
                                .font(.caption2.bold())
                                .foregroundStyle(levelColor(entry.1))
                            Spacer()
                            Text(entry.0, style: .time).font(.caption2).foregroundStyle(.secondary)
                        }
                        Text(entry.2).font(.system(.caption2, design: .monospaced)).lineLimit(2)
                    }
                }
            }
        }
        .searchable(text: $filterText, prompt: "Filter logs...")
        .navigationTitle("Log Stream Viewer")
        .onDisappear { stopStreaming() }
    }

    private func startStreaming() {
        isStreaming = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard isStreaming else { return }
            let levels = ["Default", "Info", "Debug", "Error", "Fault"]
            let messages = [
                "View controller appeared", "Network request completed",
                "User interaction detected", "Background fetch started",
                "Memory warning received", "Layout constraints updated",
                "Animation completed", "Data model saved",
                "Push notification received", "Scene entered foreground"
            ]
            let entry = (Date(), levels.randomElement() ?? "Info", messages.randomElement() ?? "Event")
            DispatchQueue.main.async {
                entries.insert(entry, at: 0)
                if entries.count > Int(maxEntries) { entries.removeLast() }
            }
        }
    }

    private func stopStreaming() { isStreaming = false; timer?.invalidate(); timer = nil }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "Error", "Fault": return .red
        case "Debug": return .blue
        case "Info": return .green
        default: return .primary
        }
    }
}
