import SwiftUI

private enum _DTLogLevel: String, CaseIterable, Hashable {
    case debug, info, warning, error
}

private struct _DTLogEntry: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let level: _DTLogLevel
    let message: String
    let source: String?
    init(level: _DTLogLevel, message: String, source: String? = nil) {
        self.timestamp = Date()
        self.level = level
        self.message = message
        self.source = source
    }
}

private class _DTLogStore: ObservableObject {
    static let shared = _DTLogStore()
    @Published var entries: [_DTLogEntry] = []
    private init() {}
    func log(_ message: String, level: _DTLogLevel = .info, source: String? = nil) {
        let entry = _DTLogEntry(level: level, message: message, source: source)
        DispatchQueue.main.async { self.entries.append(entry) }
    }
}

struct SDKEventLoggerDevTool: DevTool {
    let id = "sdk-event-logger"
    let name = "SDK Event Logger"
    let category = DevToolCategory.debugging
    let icon = "bolt.horizontal.icloud.fill"
    let description = "Stream and filter SDK internal logs"

    func render() -> some View {
        SDKEventLoggerView()
    }
}

struct SDKEventLoggerView: View {
    @StateObject private var store = _DTLogStore.shared
    @State private var selectedLevel: _DTLogLevel?

    var body: some View {
        VStack {
            Picker("Level", selection: $selectedLevel) {
                Text("All").tag(nil as _DTLogLevel?)
                ForEach(_DTLogLevel.allCases, id: \.self) { (level: _DTLogLevel) in
                    Text(level.rawValue.capitalized).tag(level as _DTLogLevel?)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                ForEach(filteredEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.level.rawValue.uppercased())
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(.white)
                                .background(color(for: entry.level), in: RoundedRectangle(cornerRadius: 4))
                            Text(entry.source ?? "unknown").font(.caption2.bold()).foregroundStyle(Color.accentColor)
                            Spacer()
                            Text(entry.timestamp, style: .time).font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
    }

    private var filteredEntries: [_DTLogEntry] {
        if let level = selectedLevel {
            return store.entries.filter { $0.level == level }
        }
        return store.entries
    }

    private func color(for level: _DTLogLevel) -> Color {
        switch level {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

#Preview {
    SDKEventLoggerView()
}
