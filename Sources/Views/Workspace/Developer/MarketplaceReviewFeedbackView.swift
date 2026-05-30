import SwiftUI

struct MarketplaceReviewFeedbackView: View {
    let submissionID: UUID
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @State private var responseMessage = ""
    @State private var replyingToID: UUID?

    var submission: MarketplaceSubmission? {
        marketplaceService.submissions.first { $0.id == submissionID }
    }

    var body: some View {
        List {
            if let sub = submission {
                Section("Reviewer Notes") {
                    if sub.reviewFeedback.isEmpty {
                        Text("No feedback items yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(sub.reviewFeedback) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.category).font(.caption.bold()).foregroundStyle(.secondary)
                                    Spacer()
                                    severityBadge(item.severity)
                                }
                                Text(item.note).font(.body)
                                Text(item.timestamp.formatted()).font(.caption2).foregroundStyle(.tertiary)

                                if !item.isResolved {
                                    Button("Respond") {
                                        replyingToID = item.id
                                    }
                                    .font(.caption.bold())
                                } else {
                                    Text("Resolved").font(.caption2.bold()).foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Response History") {
                    if sub.reviewResponses.isEmpty {
                        Text("No responses sent yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(sub.reviewResponses, id: \.feedbackItemID) { res in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(res.message).font(.caption)
                                Text(res.timestamp.formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Review Feedback")
        .sheet(item: Binding(get: { replyingToID.map { IdentifiableUUID(id: $0) } }, set: { replyingToID = $0?.id })) { item in
            replySheet(id: item.id)
        }
    }

    private func replySheet(id: UUID) -> some View {
        NavigationStack {
            Form {
                Section("Your Response") {
                    TextEditor(text: $responseMessage).frame(minHeight: 150)
                }
            }
            .navigationTitle("Respond to Reviewer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { replyingToID = nil } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task {
                            try? await marketplaceService.respondToReview(feedbackItemID: id, message: responseMessage)
                            await MainActor.run {
                                replyingToID = nil
                                responseMessage = ""
                            }
                        }
                    }
                    .disabled(responseMessage.isEmpty)
                }
            }
        }
    }

    private func severityBadge(_ severity: String) -> some View {
        Text(severity).font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(severity == "Blocking" ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
            .foregroundStyle(severity == "Blocking" ? .red : .orange)
            .clipShape(Capsule())
    }
}
