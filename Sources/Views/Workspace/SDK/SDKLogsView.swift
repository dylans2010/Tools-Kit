import SwiftUI

struct SDKLogsView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel?

    var filteredEntries: [SDKLogEntry] {
        logStore.entries.filter { entry in
            let matchesSearch = searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText) || entry.source.localizedCaseInsensitiveContains(searchText)
            let matchesLevel = selectedLevel == nil || entry.level == selectedLevel
            return matchesSearch && matchesLevel
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Picker("Level", selection: $selectedLevel) {
                    Text("All Levels").tag(nil as LogLevel?)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level as LogLevel?)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(.systemGroupedBackground))

            List(filteredEntries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        LevelBadge(level: entry.level)
                        Text(entry.source)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.message)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("System Logs")
        .toolbar {
            Button("Clear All") {
                logStore.clear()
            }
        }
    }
}

struct LevelBadge: View {
    let level: LogLevel
    var body: some View {
        Text(level.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(levelColor.opacity(0.2))
            .foregroundStyle(levelColor)
            .cornerRadius(4)
    }

    var levelColor: Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
