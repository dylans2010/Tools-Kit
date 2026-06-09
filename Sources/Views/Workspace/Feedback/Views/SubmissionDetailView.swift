import SwiftUI

struct SubmissionDetailView: View {
    let report: FeedbackReport
    @ObservedObject var viewModel: SubmissionsViewModel
    @State private var newComment = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                SectionHeader(title: "Details", subtitle: "", icon: "")
                Text(report.description)

                if !report.reproductionSteps.isEmpty {
                    SectionHeader(title: "Reproduction Steps", subtitle: "", icon: "")
                    ForEach(Array(report.reproductionSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                            Text(step)
                        }
                        .font(.subheadline)
                    }
                }

                SectionHeader(title: "History", subtitle: "", icon: "")
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(report.history) { activity in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(activity.action).bold()
                                Text(activity.timestamp.formatted()).font(.caption2)
                            }
                            Spacer()
                            Text(activity.actor).font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }

                SectionHeader(title: "Thread", subtitle: "", icon: "")
                VStack(spacing: 15) {
                    ForEach(report.comments) { comment in
                        CommentBubble(comment: comment)
                    }

                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(.roundedBorder)
                        Button("Send") {
                            // Logic to send comment
                            newComment = ""
                        }
                        .disabled(newComment.isEmpty)
                    }
                }

                if report.status != .closed && report.status != .resolved {
                    Button("Close Report", role: .destructive) {
                        Task {
                            await viewModel.updateStatus(for: report, to: .closed)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Report Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(report.summary)
                .font(.title2.bold())

            HStack {
                StatusBadge(status: report.status)
                PriorityBadge(priority: report.priority)
                Spacer()
                Text("ID: \(report.id.uuidString.prefix(8))")
                    .font(.caption2)
                    .monospaced()
                    .foregroundColor(.secondary)
            }
        }
    }
}


struct StatusBadge: View {
    let status: FeedbackStatus
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.1))
            .foregroundColor(status.color)
            .cornerRadius(4)
    }
}

struct PriorityBadge: View {
    let priority: FeedbackPriority
    var body: some View {
        Text(priority.displayName)
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.1))
            .foregroundColor(priority.color)
            .cornerRadius(4)
    }
}

struct CommentBubble: View {
    let comment: FeedbackComment
    var body: some View {
        VStack(alignment: comment.isSystem ? .center : .leading, spacing: 4) {
            if !comment.isSystem {
                Text(comment.author).font(.caption2).bold().foregroundColor(.secondary)
            }
            Text(comment.text)
                .padding(10)
                .background(comment.isSystem ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(10)
            Text(comment.timestamp.formatted()).font(.system(size: 8)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: comment.isSystem ? .center : .leading)
    }
}
