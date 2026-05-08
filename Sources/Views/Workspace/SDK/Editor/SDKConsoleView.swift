import SwiftUI

struct SDKConsoleView: View {
    final class LogBus: ObservableObject {
        static let shared = LogBus()

        enum LogType {
            case info
            case success
            case warning
            case error
        }

        private init() {}

        func log(_ message: String, type: LogType) {
            Task { @MainActor in
                SDKLogStore.shared.log(message, source: "SDKConsole", level: type.logLevel)
            }
        }

        func clear() {
            Task { @MainActor in
                SDKLogStore.shared.clear()
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var logStore = SDKLogStore.shared
    @StateObject private var runtimeState = SDKRuntimeWorkspaceState.shared

    let embedded: Bool

    @State private var selectedLevel: ConsoleLogLevel?
    @State private var pluginFilter = "All"
    @State private var connectorFilter = "All"
    @State private var appFilter = "All"
    @State private var selectedEventID: UUID?
    @State private var showPerformanceTimeline = false

    init(embedded: Bool = false) {
        self.embedded = embedded
    }

    private var pluginOptions: [String] {
        ["All"] + SDKPluginManager.shared.plugins.map(\.name).sorted()
    }

    private var connectorOptions: [String] {
        ["All"] + SDKConnectorManager.shared.connectors.map(\.name).sorted()
    }

    private var appOptions: [String] {
        ["All"] + SDKProjectManager.shared.projects.map(\.name).sorted()
    }

    private var filteredEntries: [SDKLogEntry] {
        logStore.entries.filter { entry in
            let levelMatches = selectedLevel == nil || selectedLevel?.matches(entry.level) == true
            let pluginMatches = pluginFilter == "All" || entry.source.localizedCaseInsensitiveContains(pluginFilter)
            let connectorMatches = connectorFilter == "All" || entry.source.localizedCaseInsensitiveContains(connectorFilter)
            let appMatches = appFilter == "All" || entry.message.localizedCaseInsensitiveContains(appFilter)
            return levelMatches && pluginMatches && connectorMatches && appMatches
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            filters
            Divider()
            logList
            footer
        }
        .navigationTitle("SDK Console")
        .background(Color(uiColor: .systemBackground))
        .toolbar {
            if !embedded {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            runtimeState.recalculateDiagnostics()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill")
                Text("CONSOLE")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Toggle(isOn: $showPerformanceTimeline) {
                    Text("TIMELINE").font(.system(size: 10, weight: .bold))
                }
                .toggleStyle(ConsoleToggleStyle())

                Text("\(filteredEntries.count) ENTRIES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
        .overlay(Divider(), alignment: .bottom)
    }

    private var filters: some View {
        VStack(spacing: 8) {
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        filterButton("ALL", level: nil)
                        filterButton("INFO", level: .info)
                        filterButton("WARN", level: .warning)
                        filterButton("ERR", level: .error)
                        filterButton("CRT", level: .critical)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Menu {
                        Picker("Plugin", selection: $pluginFilter) {
                            ForEach(pluginOptions, id: \.self) { Text($0).tag($0) }
                        }
                    } label: {
                        filterMenuLabel(pluginFilter, icon: "puzzlepiece")
                    }

                    Menu {
                        Picker("Connector", selection: $connectorFilter) {
                            ForEach(connectorOptions, id: \.self) { Text($0).tag($0) }
                        }
                    } label: {
                        filterMenuLabel(connectorFilter, icon: "link")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color.primary.opacity(0.02))
    }

    private var logList: some View {
        List(filteredEntries) { entry in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                    badge(for: entry)
                    Spacer()
                    if showPerformanceTimeline {
                        Text(timelineMarker(for: entry))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                Text(entry.message)
                    .font(.system(.caption, design: .monospaced))
                if selectedEventID == entry.id {
                    Text(stackTrace(for: entry))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedEventID = selectedEventID == entry.id ? nil : entry.id
            }
        }
        .listStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Button {
                logStore.clear()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button {
                for replay in filteredEntries.prefix(10).reversed() {
                    logStore.log("REPLAY: \(replay.message)", source: "REPLAY", level: replay.level)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle")
                    Text("REPLAY 10")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                Text("\(runtimeState.memoryEstimateMB) MB")
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
        .overlay(Divider(), alignment: .top)
    }

    private func filterButton(_ text: String, level: ConsoleLogLevel?) -> some View {
        Button {
            selectedLevel = level
        } label: {
            Text(text)
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedLevel == level ? Color.blue : Color.primary.opacity(0.05), in: Capsule())
                .foregroundStyle(selectedLevel == level ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func filterMenuLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text.uppercased())
            Image(systemName: "chevron.down")
        }
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
    }

    struct ConsoleToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button {
                configuration.isOn.toggle()
            } label: {
                HStack(spacing: 4) {
                    configuration.label
                    Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                        .font(.system(size: 10))
                }
                .foregroundStyle(configuration.isOn ? .blue : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func badge(for entry: SDKLogEntry) -> some View {
        let mapped = ConsoleLogLevel(from: entry.level)
        return Text(mapped.shortLabel)
            .font(.caption2.bold().monospaced())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(mapped.color.opacity(0.2), in: Capsule())
            .foregroundStyle(mapped.color)
    }

    private func timelineMarker(for entry: SDKLogEntry) -> String {
        let ms = Int(entry.timestamp.timeIntervalSince1970.truncatingRemainder(dividingBy: 1000) * 1000)
        return "t+\(max(0, ms))ms"
    }

    private func stackTrace(for entry: SDKLogEntry) -> String {
        """
        source: \(entry.source)
        level: \(entry.level.rawValue)
        diagnostic-hint: \(runtimeState.diagnostics.first(where: { entry.message.localizedCaseInsensitiveContains($0.node.title) })?.suggestion ?? "No Linked Diagnostic")
        """
    }
}

private extension SDKConsoleView.LogBus.LogType {
    var logLevel: LogLevel {
        switch self {
        case .info, .success:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }
}

private enum ConsoleLogLevel: String, CaseIterable {
    case info
    case warning
    case error
    case critical

    init(from level: LogLevel) {
        switch level {
        case .debug, .info: self = .info
        case .warning: self = .warning
        case .error: self = .error
        }
    }

    func matches(_ level: LogLevel) -> Bool {
        switch self {
        case .info: return level == .info || level == .debug
        case .warning: return level == .warning
        case .error, .critical: return level == .error
        }
    }

    var shortLabel: String {
        switch self {
        case .info: return "INF"
        case .warning: return "WRN"
        case .error: return "ERR"
        case .critical: return "CRT"
        }
    }

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}
