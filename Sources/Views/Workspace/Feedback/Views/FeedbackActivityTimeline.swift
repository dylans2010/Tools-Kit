import SwiftUI

public struct FeedbackActivityTimeline: View {
    let activities: [FeedbackActivity]

    public init(activities: [FeedbackActivity]) {
        self.activities = activities
    }

    public body: some View {
        if activities.isEmpty {
            Text("No recent activity.")
                .foregroundColor(.secondary)
                .font(.subheadline)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                    HStack(alignment: .top, spacing: 15) {
                        VStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                            if index < activities.count - 1 {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.action)
                                .font(.subheadline.bold())
                            HStack {
                                Text(activity.actor)
                                Text("•")
                                Text(activity.timestamp.formatted())
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
}
