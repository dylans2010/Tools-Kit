import SwiftUI

struct SDKLogsView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @State private var selectedLevel: LogLevel?
    @State private var searchText = ""

    var body: some View {
        VStack {
            HStack {
                Picker("Level", selection: $selectedLevel) {
                    Text("All").tag(LogLevel?.none)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(LogLevel?.some(level))
                    }
                }
                .pickerStyle(.menu)

                TextField("Search Source", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()

            List(filteredEntries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        levelBadge(entry.level)
                        Text(entry.source).font(.caption).bold().foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(entry.message).font(.subheadline)
                }
                .padding(.vertical, 2)
            }
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
