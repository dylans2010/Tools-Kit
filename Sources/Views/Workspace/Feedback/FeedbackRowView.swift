import SwiftUI

struct FeedbackRowView: View {
    let feedback: Feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(feedback.userName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(feedback.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                badge(feedback.categoryValue.displayName, color: .blue)
                badge(feedback.statusValue.displayName, color: statusColor(feedback.statusValue))
                badge(feedback.priorityValue.displayName, color: priorityColor(feedback.priorityValue))
            }

            Text(feedback.message)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func badge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func statusColor(_ status: FeedbackStatus) -> Color {
        switch status {
        case .open: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .closed: return .secondary
        }
    }

    private func priorityColor(_ priority: FeedbackPriority) -> Color {
        switch priority {
        case .low: return .secondary
        case .medium: return .orange
        case .high: return .red
        }
    }
}
