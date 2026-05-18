

import SwiftUI

struct SDKConsoleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logStore = SDKLogStore.shared
    @StateObject private var runtimeState = SDKRuntimeWorkspaceState.shared

    let embedded: Bool
    @State private var selectedLevel: ConsoleLogLevel?
    @State private var pluginFilter = "All"
    @State private var connectorFilter = "All"
    @State private var selectedEventID: UUID?
    @State private var showTimeline = false

    init(embedded: Bool = false) {
        self.embedded = embedded
    }

    private var filteredEntries: [SDKLogEntry] {
        logStore.entries.filter { entry in
            let levelMatches = selectedLevel == nil || selectedLevel?.matches(entry.level) == true
            let pluginMatches = pluginFilter == "All" || entry.source.localizedCaseInsensitiveContains(pluginFilter)
            let connectorMatches = connectorFilter == "All" || entry.source.localizedCaseInsensitiveContains(connectorFilter)
            return levelMatches && pluginMatches && connectorMatches
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            consoleHeader

            List(filteredEntries) { entry in
                ConsoleLogRow(entry: entry,
                             isExpanded: selectedEventID == entry.id,
                             showTimeline: showTimeline,
                             diagnostics: runtimeState.diagnostics)
                .onTapGesture { selectedEventID = (selectedEventID == entry.id ? nil : entry.id) }
            }
            .listStyle(.plain)

            consoleFooter
        }
        .navigationTitle("Console")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !embedded {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var consoleHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Level", selection: $selectedLevel) {
                    Text("All").tag(Optional<ConsoleLogLevel>.none)
                    ForEach(ConsoleLogLevel.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag(Optional($0)) }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $showTimeline) { Image(systemName: "timer") }
                    .toggleStyle(.button)
                    .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            HStack(spacing: 12) {
                FilterMenu(title: "Plugin", selection: $pluginFilter, options: ["All"] + SDKPluginManager.shared.plugins.map(\.name))
                FilterMenu(title: "Connector", selection: $connectorFilter, options: ["All"] + SDKConnectorManager.shared.connectors.map(\.name))
                Spacer()
                Text("\(filteredEntries.count) events").font(.caption2.monospaced()).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }

    private var consoleFooter: some View {
        HStack {
            Button { logStore.clear() } label: { Label("Clear", systemImage: "trash") }
            Spacer()
            Label("\(runtimeState.memoryEstimateMB) MB", systemImage: "memorychip")
                .font(.caption2.monospaced())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - Private Subviews

private struct ConsoleLogRow: View {
    let entry: SDKLogEntry
    let isExpanded: Bool
    let showTimeline: Bool
    let diagnostics: [SDKRuntimeDiagnostic]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(ConsoleLogLevel(from: entry.level).shortLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(ConsoleLogLevel(from: entry.level).color.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                    .foregroundStyle(ConsoleLogLevel(from: entry.level).color)

                Text(entry.source).font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                if showTimeline {
                    Text("+\(Int(entry.timestamp.timeIntervalSince1970.truncatingRemainder(dividingBy: 1000) * 1000))ms")
                        .font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
                }
                Text(entry.timestamp.formatted(date: .omitted, time: .standard)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
            }

            Text(entry.message).font(.caption.monospaced()).foregroundStyle(.primary)

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    Divider().padding(.vertical, 4)
                    if let diag = diagnostics.first(where: { entry.message.localizedCaseInsensitiveContains($0.node.title) }) {
                        Text("Hint: \(diag.suggestion)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.orange)
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct FilterMenu: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var body: some View {
        Menu {
            Picker(title, selection: $selection) { ForEach(options, id: \.self) { Text($0).tag($0) } }
        } label: {
            HStack(spacing: 4) {
                Text(selection == "All" ? title : selection)
                Image(systemName: "chevron.down").font(.caption2)
            }
            .font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 4).background(Color.primary.opacity(0.05), in: Capsule()).foregroundStyle(.secondary)
        }
    }
}

private enum ConsoleLogLevel: String, CaseIterable, Decodable {
    case info, warning, error, critical
    init(from level: LogLevel) {
        switch level { case .debug, .info: self = .info; case .warning: self = .warning; case .error: self = .error }
    }
    func matches(_ level: LogLevel) -> Bool {
        switch self { case .info: return level == .info || level == .debug; case .warning: return level == .warning; case .error, .critical: return level == .error }
    }
    var shortLabel: String { switch self { case .info: return "INF"; case .warning: return "WRN"; case .error: return "ERR"; case .critical: return "CRT" } }
    var color: Color { switch self { case .info: return .blue; case .warning: return .orange; case .error: return .red; case .critical: return .purple } }
}
