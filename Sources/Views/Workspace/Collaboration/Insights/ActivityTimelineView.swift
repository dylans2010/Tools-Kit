import SwiftUI

struct ActivityTimelineView: View {
    let spaceID: UUID
    @StateObject private var manager = CollaborationManager.shared
    @State private var filter: ActivityFilter = .all

    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case commits = "Commits"
        case merges = "Merges"
        case comments = "Comments"
    }

    private var filteredActivities: [ActivityLog] {
        guard let space = manager.spaces.first(where: { $0.id == spaceID }) else { return [] }
        switch filter {
        case .all: return space.activityFeed
        case .commits: return space.activityFeed.filter { $0.action.contains("Committed") }
        case .merges: return space.activityFeed.filter { $0.action.contains("Merged") }
        case .comments: return space.activityFeed.filter { $0.action.contains("Commented") }
        }
    }

    var body: some View {
        VStack {
            Picker("Filter", selection: $filter) {
                ForEach(ActivityFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                ForEach(filteredActivities) { log in
                    TimelineActivityRow(log: log)
                }
            }
        }
        .navigationTitle("Activity Timeline")
    }
}

struct TimelineActivityRow: View {
    let log: ActivityLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForAction(log.action))
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(log.action)
                    .font(.subheadline)
                    .bold()

                HStack {
                    Text(log.userName)
                    Text("•")
                    Text(log.timestamp, style: .relative)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconForAction(_ action: String) -> String {
        if action.contains("Committed") { return "arrow.triangle.merge" }
        if action.contains("Forked") { return "arrow.branch" }
        if action.contains("Created") { return "plus.circle" }
        if action.contains("Merged") { return "checkmark.circle" }
        return "circle"
    }
}
