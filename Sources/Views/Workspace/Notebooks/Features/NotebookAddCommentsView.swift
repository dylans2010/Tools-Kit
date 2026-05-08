import SwiftUI

struct NotebookAddCommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    let pageID: UUID

    @State private var commentText = ""
    @State private var comments: [NotebookComment] = []

    struct NotebookComment: Identifiable, Codable {
        var id = UUID()
        let author: String
        let text: String
        let timestamp: Date
    }

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if comments.isEmpty {
                            Text("No comments yet. Start the conversation!")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else {
                            ForEach(comments) { comment in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(comment.author)
                                            .font(.subheadline.bold())
                                        Spacer()
                                        Text(comment.timestamp, style: .relative)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(comment.text)
                                        .font(.callout)
                                        .padding(10)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $commentText, axis: .vertical)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .lineLimit(1...5)

                    Button(action: postComment) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(commentText.isEmpty ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(commentText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: loadComments)
        }
    }

    private func loadComments() {
        // In a real app, this would be fetched from NotebooksManager or a dedicated service.
        // For now, we simulate persistence via UserDefaults per page.
        if let data = UserDefaults.standard.data(forKey: "comments_\(pageID.uuidString)"),
           let decoded = try? JSONDecoder().decode([NotebookComment].self, from: data) {
            comments = decoded
        }
    }

    private func postComment() {
        let newComment = NotebookComment(author: "Local User", text: commentText, timestamp: Date())
        comments.append(newComment)
        commentText = ""

        if let data = try? JSONEncoder().encode(comments) {
            UserDefaults.standard.set(data, forKey: "comments_\(pageID.uuidString)")
        }
    }
}
