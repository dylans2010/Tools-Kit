import SwiftUI

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
    typealias SDKLogStore = Tools_Kit.SDKLogStore
    typealias LogLevel = Tools_Kit.LogLevel
    typealias SDKLogEntry = Tools_Kit.SDKLogEntry

    @StateObject private var logStore = Self.SDKLogStore.shared
    @State private var selectedLevel: Self.LogLevel?

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Event Logger",
                description: "Live monitoring of internal SDK events, audit logs, and diagnostic messages.",
                icon: "bolt.horizontal.icloud.fill"
            )
            .padding()

            VStack {
                Picker("Level", selection: $selectedLevel) {
                    Text("All").tag(nil as Self.LogLevel?)
                    ForEach(Self.LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level as Self.LogLevel?)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    ForEach(filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                StatusBadge(text: entry.level.rawValue.uppercased(), color: color(for: entry.level))
                                Text(entry.source).font(.caption2.bold()).foregroundStyle(Color.accentColor)
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
    }

    private var filteredEntries: [Self.SDKLogEntry] {
        if let level = selectedLevel {
            return logStore.entries.filter { $0.level == level }
        }
        return logStore.entries
    }

    private func color(for level: Self.LogLevel) -> Color {
        switch level {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
