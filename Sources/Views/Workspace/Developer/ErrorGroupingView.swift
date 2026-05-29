import SwiftUI

struct ErrorGroupingView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var selectedError: String?

    var groupedErrors: [(message: String, count: Int, lastSeen: Date)] {
        let errors = logService.logEntries.filter { $0.severity == .error || $0.severity == .critical }
        let groups = Dictionary(grouping: errors, by: { $0.message })
        return groups.map { (message: $0.key, count: $0.value.count, lastSeen: $0.value.map { $0.timestamp }.max() ?? Date()) }
            .sorted(by: { $0.count > $1.count })
    }

    var body: some View {
        List {
            if groupedErrors.isEmpty {
                EmptyStateView(icon: "checkmark.circle", title: "No Errors", message: "No critical errors reported.")
            } else {
                ForEach(groupedErrors, id: \.message) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(group.message)
                                .font(.subheadline.bold())
                                .lineLimit(2)
                            Spacer()
                            Text("\(group.count)")
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.red.opacity(0.1), in: Capsule())
                                .foregroundStyle(.red)
                        }

                        HStack {
                            Text("Last seen: \(group.lastSeen.formatted())")
                            Spacer()
                            Button("View Instances") {
                                selectedError = group.message
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Error Grouping")
    }
}
