import SwiftUI

struct HistoryTimelineView: View {
    @StateObject private var historyManager = HistoryManager.shared
    let projectID: UUID

    var body: some View {
        List {
            ForEach(historyManager.history[projectID] ?? []) { snapshot in
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.message).bold()
                    Text(snapshot.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .swipeActions {
                    Button("Revert") {
                        // Trigger revert logic
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle("History")
    }
}
