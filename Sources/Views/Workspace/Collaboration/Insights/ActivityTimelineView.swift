import SwiftUI

struct ActivityFeedView: View {
    let workspace: CollaborationWorkspace
    @StateObject private var manager = CollaborationManager.shared

    private func iconForAction(_ action: String) -> String {
        let lower = action.lowercased()
        if lower.contains("message") { return "message.fill" }
        if lower.contains("commit") { return "terminal.fill" }
        if lower.contains("branch") { return "arrow.branch" }
        if lower.contains("create") { return "plus.circle.fill" }
        return "bolt.fill"
    }

    private func colorForAction(_ action: String) -> Color {
        let lower = action.lowercased()
        if lower.contains("message") { return .blue }
        if lower.contains("commit") { return .purple }
        if lower.contains("branch") { return .orange }
        if lower.contains("create") { return .green }
        return .secondary
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Activity Feed")
                    .font(.headline)
                Spacer()
                Button { /* Filter */ } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))

            Divider()

            List {
                let activity = manager.workspaces.first(where: { $0.id == workspace.id })?.activityFeed ?? []

                if activity.isEmpty {
                    ContentUnavailableView("No Recent Activity", systemImage: "clock")
                } else {
                    Section("Recent Updates") {
                        ForEach(activity) { log in
                            ActivityRow(
                                icon: iconForAction(log.action),
                                color: colorForAction(log.action),
                                title: log.action,
                                detail: "\(log.userName) • \(log.timestamp, style: .relative)",
                                time: ""
                            )
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

private struct ActivityRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String
    let time: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.headline)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(time)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
