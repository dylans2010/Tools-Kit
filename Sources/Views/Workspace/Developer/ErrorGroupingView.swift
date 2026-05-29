import SwiftUI

struct ErrorGroupingView: View {
    @ObservedObject var logService = DeveloperLogService.shared

    var errorGroups: [String: [LogEntry]] {
        Dictionary(grouping: logService.logEntries.filter { $0.severity == .error || $0.severity == .critical }) { entry in
            // Basic grouping by first 50 chars of message
            String(entry.message.prefix(50))
        }
    }

    var body: some View {
        List {
            Section("Grouped Errors") {
                if errorGroups.isEmpty {
                    Text("No recurring errors detected.").foregroundStyle(.secondary)
                } else {
                    ForEach(errorGroups.keys.sorted(), id: \.self) { key in
                        if let entries = errorGroups[key] {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(key).font(.subheadline.bold()).lineLimit(1)
                                    Spacer()
                                    Text("\(entries.count)").font(.caption2.bold())
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.red.opacity(0.1), in: Capsule())
                                        .foregroundStyle(.red)
                                }
                                Text("Last seen: \(entries.first?.timestamp.formatted() ?? "Unknown")")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Error Grouping")
    }
}
