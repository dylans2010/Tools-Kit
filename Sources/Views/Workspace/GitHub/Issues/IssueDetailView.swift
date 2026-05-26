import SwiftUI

struct IssueDetailView: View {
    let issue: GitHubIssue
    @State private var comments: [IssueComment] = []
    @State private var newComment = ""

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: issue.state == .open ? "circle.circle" : "checkmark.circle.fill")
                            .foregroundStyle(issue.state == .open ? .green : .purple)
                        Text(issue.state.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(issue.state == .open ? Color.green.opacity(0.15) : Color.purple.opacity(0.15))
                            .clipShape(Capsule())
                        Spacer()
                        Text("#\(issue.number)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Text(issue.title)
                        .font(.title3.bold())
                    if issue.body?.isEmpty == false {
                        Text(issue.body ?? "")
                            .font(.body)
                    }
                    HStack {
                        if let assignee = issue.assignee {
                            Label(assignee.login, systemImage: "person")
                        }
                        Spacer()
                        Text("Opened \(issue.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if !issue.labels.isEmpty {
                        HStack {
                            ForEach(issue.labels, id: \.self) { label in
                                Text(label.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            Section("Comments (\(comments.count))") {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(comment.author)
                                .font(.subheadline.bold())
                            Spacer()
                            Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(comment.body)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Add Comment") {
                TextEditor(text: $newComment)
                    .frame(minHeight: 60)
                Button("Comment") {
                    submitComment()
                }
                .disabled(newComment.isEmpty)
            }
        }
        .navigationTitle("Issue #\(issue.number)")
        .navigationBarTitleDisplayMode(.inline)
        .task { loadComments() }
    }

    private func submitComment() {
        comments.append(IssueComment(author: "You", body: newComment, createdAt: Date()))
        newComment = ""
    }

    private func loadComments() {
        // Issue comments are fetched from the GitHub API; start empty until connected.
    }
}

private struct IssueComment: Identifiable {
    let id = UUID()
    let author: String
    let body: String
    let createdAt: Date
}
