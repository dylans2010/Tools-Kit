import SwiftUI

struct MarketplaceReviewFeedbackView: View {
    let submissionID: UUID
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @State private var responseText = ""
    @State private var respondingToID: UUID?

    var submission: MarketplaceSubmission? {
        marketplaceService.submissions.first { $0.id == submissionID }
    }

    var body: some View {
        List {
            if let sub = submission {
                Section("Submission Status") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(sub.metadata.title).font(.subheadline.bold())
                            Text("Submitted \(sub.submittedAt.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        statusBadge(sub.status)
                    }
                }

                Section("Reviewer Notes") {
                    if sub.reviewFeedback.isEmpty {
                        EmptyStateView(icon: "checkmark.seal", title: "No Issues Found", message: "Your submission is currently in the queue for review.")
                    } else {
                        ForEach(sub.reviewFeedback) { item in
                            feedbackRow(item)
                        }
                    }
                }

                if sub.status == .rejected {
                    Section("Action Required") {
                        Text("Address the blocking items above and resubmit your application for a follow-up audit.").font(.caption).foregroundStyle(.secondary)
                        Button { /* resubmit */ } label: {
                            Text("Resubmit for Review").font(.subheadline.bold())
                        }
                    }
                }
            }
        }
        .navigationTitle("Review Audit")
        .sheet(item: $respondingToID) { id in
            responseSheet(feedbackID: id)
        }
    }

    private func feedbackRow(_ item: ReviewFeedbackItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.category.uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                Spacer()
                severityBadge(item.severity)
            }

            Text(item.note).font(.system(size: 14))

            HStack {
                Text(item.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                if !item.isResolved {
                    Button { respondingToID = item.id } label: {
                        Text("Respond").font(.system(size: 10, weight: .bold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                } else {
                    Label("Resolved", systemImage: "checkmark.circle.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: SubmissionStatus) -> some View {
        Text(status.rawValue.uppercased()).font(.system(size: 8, weight: .black))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(status == .rejected ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
            .foregroundStyle(status == .rejected ? .red : .blue)
            .clipShape(Capsule())
    }

    private func severityBadge(_ severity: String) -> some View {
        Text(severity.uppercased()).font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(severity == "Blocking" ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
            .foregroundStyle(severity == "Blocking" ? .red : .orange)
            .clipShape(Capsule())
    }

    private func responseSheet(feedbackID: UUID) -> some View {
        NavigationStack {
            Form {
                Section("Your Explanation") {
                    TextEditor(text: $responseText).frame(minHeight: 150)
                }
            }
            .navigationTitle("Respond to Review")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { respondingToID = nil; responseText = "" } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task {
                            try? await marketplaceService.respondToReview(feedbackItemID: feedbackID, message: responseText)
                            await MainActor.run { respondingToID = nil; responseText = "" }
                        }
                    }
                    .disabled(responseText.isEmpty)
                }
            }
        }
    }
}

extension UUID: Identifiable {
    public var id: String { uuidString }
}
