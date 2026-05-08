import SwiftUI

struct SDKLogsView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @State private var selectedLevel: LogLevel?
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                SDKModernCard(padding: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Filter by source...", text: $searchText)
                            .font(.subheadline)

                        Menu {
                            Picker("Level", selection: $selectedLevel) {
                                Text("All Levels").tag(LogLevel?.none)
                                ForEach(LogLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue.capitalized).tag(LogLevel?.some(level))
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundStyle(selectedLevel == nil ? Color.secondary : Color.blue)
                        }
                    }
                }

                HStack {
                    SDKStatusPill("\(filteredEntries.count) events", color: .blue)
                    Spacer()
                    Button {
                        logStore.clear()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                            .font(.caption2.bold())
                            .foregroundStyle(.sdkError)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding()
            .background(Color(.systemGroupedBackground))

            List(filteredEntries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        SDKStatusPill(entry.level.rawValue, color: levelColor(entry.level), isCapsule: false)
                        Text(entry.source).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                    }
                    Text(entry.message)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .navigationTitle("System Logs")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Clear", role: .destructive) {
                    logStore.clear()
                }
            }
        }
    }

    private var filteredEntries: [SDKLogEntry] {
        logStore.entries.filter { entry in
            (selectedLevel == nil || entry.level == selectedLevel) &&
            (searchText.isEmpty || entry.source.localizedCaseInsensitiveContains(searchText))
        }
    }

    private func levelBadge(_ level: LogLevel) -> some View {
        Text(level.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(levelColor(level).opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(levelColor(level))
    }

    private func levelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
