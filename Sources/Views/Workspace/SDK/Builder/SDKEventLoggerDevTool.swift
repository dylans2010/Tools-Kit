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
    @State private var searchText = ""
    @State private var autoScroll = true
    @State private var showingStats = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            logListView

            footerSection
        }
        .navigationTitle("Event Logger")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingStats = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.entries.removeAll()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingStats) {
            LogStatsView(entries: store.entries)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            Picker("Level", selection: $selectedLevel) {
                Text("All").tag(nil as _DTLogLevel?)
                ForEach(_DTLogLevel.allCases, id: \.self) { (level: _DTLogLevel) in
                    Text(level.rawValue.capitalized).tag(level as _DTLogLevel?)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
    }

    private var logListView: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredEntries) { entry in
                    LogEntryRow(entry: entry, color: color(for: entry.level))
                        .id(entry.id)
                }
            }
            .listStyle(.plain)
            .onChange(of: filteredEntries.count) { _, _ in
                if autoScroll, let last = filteredEntries.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Text("\(filteredEntries.count) events")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)

            Spacer()

            Toggle("Auto-scroll", isOn: $autoScroll)
                .font(.caption2)
                .toggleStyle(.button)
                .tint(.blue)

            Button {
                let text = filteredEntries.map { "[\($0.level.rawValue.uppercased())] \($0.message)" }.joined(separator: "\n")
                UIPasteboard.general.string = text
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption2)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private var filteredEntries: [_DTLogEntry] {
        store.entries.filter { entry in
            let levelMatch = selectedLevel == nil || entry.level == selectedLevel
            let searchMatch = searchText.isEmpty ||
                             entry.message.localizedCaseInsensitiveContains(searchText) ||
                             (entry.source?.localizedCaseInsensitiveContains(searchText) ?? false)
            return levelMatch && searchMatch
        }
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

struct LogEntryRow: View {
    let entry: _DTLogEntry
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.level.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .cornerRadius(3)

                Text(entry.source ?? "SYSTEM")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(entry.timestamp, style: .time)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Text(entry.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

struct LogStatsView: View {
    let entries: [_DTLogEntry]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Distribution") {
                    StatRow(label: "Total Events", value: "\(entries.count)", color: .primary)
                    StatRow(label: "Errors", value: "\(entries.filter { $0.level == .error }.count)", color: .red)
                    StatRow(label: "Warnings", value: "\(entries.filter { $0.level == .warning }.count)", color: .orange)
                    StatRow(label: "Info", value: "\(entries.filter { $0.level == .info }.count)", color: .blue)
                    StatRow(label: "Debug", value: "\(entries.filter { $0.level == .debug }.count)", color: .secondary)
                }

                Section("Rate") {
                    if let first = entries.first {
                        let duration = Date().timeIntervalSince(first.timestamp)
                        let rate = Double(entries.count) / (duration / 60)
                        LabeledContent("Events/min", value: String(format: "%.1f", rate))
                    }
                }
            }
            .navigationTitle("Log Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
            Spacer()
            Text(value).bold().monospacedDigit()
        }
    }
}

#Preview {
    SDKEventLoggerView()
}
