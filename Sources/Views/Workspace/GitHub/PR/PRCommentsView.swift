import SwiftUI

struct PRCommentsView: View {
    let owner: String
    let repo: String
    let pullRequest: GitHubPullRequest

    @State private var comments: [GitHubPRComment] = []
    @State private var reviews: [GitHubPRReview] = []
    @State private var isLoading = false
    @State private var newCommentText = ""
    @State private var isPosting = false

    var body: some View {
        List {
            Section("Reviews") {
                if reviews.isEmpty && !isLoading {
                    Text("No reviews yet").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(reviews) { review in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(review.user.login).bold()
                            Spacer()
                            Text(review.state)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(reviewStateColor(review.state).opacity(0.1))
                                .foregroundStyle(reviewStateColor(review.state))
                                .clipShape(Capsule())
                        }
                        if let body = review.body, !body.isEmpty {
                            Text(body).font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Comments") {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            AsyncImage(url: URL(string: comment.user.avatarUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())

                            Text(comment.user.login).font(.caption.bold())
                            Spacer()
                            Text(comment.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                        }

                        Text(comment.body).font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                VStack {
                    TextEditor(text: $newCommentText)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2))
                        )

                    Button {
                        postComment()
                    } label: {
                        if isPosting {
                            ProgressView()
                        } else {
                            Text("Post Comment").bold()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Add Comment")
            }
        }
        .navigationTitle("PR Discussion")
        .overlay {
            if isLoading { ProgressView() }
        }
        .task {
            await fetchData()
        }
    }

    private func fetchData() async {
        isLoading = true
        do {
            async let commentsReq: [GitHubPRComment] = GitHubAPIClient.shared.request(.prComments(owner: owner, repo: repo, number: pullRequest.number))
            async let reviewsReq: [GitHubPRReview] = GitHubAPIClient.shared.request(.prReviews(owner: owner, repo: repo, number: pullRequest.number))

            let (fetchedComments, fetchedReviews) = try await (commentsReq, reviewsReq)
            self.comments = fetchedComments
            self.reviews = fetchedReviews
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func postComment() {
        isPosting = true
        struct CommentPayload: Encodable {
            let body: String
        }
        let payload = CommentPayload(body: newCommentText)

        Task {
            do {
                let _: GitHubPRComment = try await GitHubAPIClient.shared.request(.prComments(owner: owner, repo: repo, number: pullRequest.number), body: payload)
                await MainActor.run {
                    newCommentText = ""
                    isPosting = false
                }
                await fetchData()
            } catch {
                await MainActor.run { isPosting = false }
            }
        }
    }

    private func reviewStateColor(_ state: String) -> Color {
        switch state {
        case "APPROVED": return .green
        case "CHANGES_REQUESTED": return .red
        case "COMMENTED": return .secondary
        default: return .orange
        }
    }
}
