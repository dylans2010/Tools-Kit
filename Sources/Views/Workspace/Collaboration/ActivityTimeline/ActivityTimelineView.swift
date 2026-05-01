import SwiftUI

struct ActivityTimelineView: View {
    let space: CollaborationSpace
    @State private var selectedFilter: ActivityTimelineManager.ActivityType? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "All", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }
                    ForEach([ActivityTimelineManager.ActivityType.commit, .merge, .comment, .branch], id: \.self) { type in
                        FilterChip(title: type.rawValue, isSelected: selectedFilter == type) {
                            selectedFilter = type
                        }
                    }
                }
                .padding()
            }

            List(ActivityTimelineManager.shared.filteredFeed(for: space, type: selectedFilter)) { log in
                HStack(alignment: .top, spacing: 12) {
                    ActivityIcon(action: log.action)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.userName).bold() + Text(" \(log.action)")
                        Text(log.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Activity Feed")
    }
}

struct ActivityIcon: View {
    let action: String

    var body: some View {
        Image(systemName: iconName)
            .foregroundColor(iconColor)
            .frame(width: 24, height: 24)
    }

    private var iconName: String {
        if action.contains("Committed") { return "arrow.up.circle.fill" }
        if action.contains("Merged") { return "arrow.merge" }
        if action.contains("Commented") { return "bubble.left.fill" }
        if action.contains("Created branch") { return "arrow.branch" }
        return "circle.fill"
    }

    private var iconColor: Color {
        if action.contains("Committed") { return .blue }
        if action.contains("Merged") { return .purple }
        if action.contains("Commented") { return .green }
        return .gray
    }
}
