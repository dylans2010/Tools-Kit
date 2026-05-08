import SwiftUI

struct SDKLogsView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @State private var selectedLevel: LogLevel?
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SDKSectionHeader(
                    title: "System Logs",
                    subtext: "Platform-wide event stream and diagnostics.",
                    isCentered: true
                )

                SDKModernCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Level Filter").sdkSubtext()
                            Spacer()
                            Picker("Level", selection: $selectedLevel) {
                                Text("All").tag(LogLevel?.none)
                                ForEach(LogLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue.capitalized).tag(LogLevel?.some(level))
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        TextField("Search source...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                SDKSectionHeader(title: "Log Stream", subtext: "Filtered kernel entries.")
                VStack(spacing: 12) {
                    if filteredEntries.isEmpty {
                        SDKModernCard { Text("No matching logs").sdkSubtext().frame(maxWidth: .infinity) }
                    } else {
                        ForEach(filteredEntries.prefix(50)) { entry in
                            SDKModernCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        SDKStatusPill(status: levelToStatus(entry.level), text: entry.level.rawValue.uppercased())
                                        Text(entry.source).font(.caption.bold()).foregroundStyle(.secondary)
                                        Spacer()
                                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundStyle(.tertiary)
                                    }
                                    Text(entry.message).font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("System Logs")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Clear", role: .destructive) { logStore.clear() }
            }
        }
    }

    private var filteredEntries: [SDKLogEntry] {
        logStore.entries.filter { entry in
            (selectedLevel == nil || entry.level == selectedLevel) &&
            (searchText.isEmpty || entry.source.localizedCaseInsensitiveContains(searchText))
        }
    }

    private func levelToStatus(_ level: LogLevel) -> SDKStatus {
        switch level {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        case .debug: return .info
        }
    }
}
