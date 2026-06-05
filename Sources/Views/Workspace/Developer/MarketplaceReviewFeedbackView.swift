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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let sub = submission {
                        // Submission Status Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Submission Status")
                                .font(.headline)

                            Section {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sub.metadata.title)
                                            .font(.subheadline.bold())
                                        Text("Submitted \(sub.submittedAt.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                    }
                                    Spacer()
                                    statusBadge(sub.status)
                                }
                                .padding()
                            }
                        }

                        Divider()

                        // Reviewer Notes Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reviewer Notes")
                                .font(.headline)

                            Section {
                                if sub.reviewFeedback.isEmpty {
                                    VStack(spacing: 20) {
                                        Image(systemName: "checkmark.seal")
                                            .font(.system(size: 52, weight: .light))
                                        VStack(spacing: 6) {
                                            Text("No Issues Found")
                                                .font(.title3.bold())
                                            Text("Your submission is currently in the queue for review.")
                                                .font(.subheadline)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 32)
                                        }
                                    }
                                    .padding(.vertical, 40)
                                } else {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(sub.reviewFeedback) { item in
                                            feedbackRow(item)
                                            if item.id != sub.reviewFeedback.last?.id {
                                                Divider()
                                                    .padding(.vertical, 12)
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }

                        if sub.status == .rejected {
                            Divider()

                            // Action Required Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Action Required")
                                    .font(.headline)

                                Section {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Address the blocking items above and resubmit your application for a follow-up audit.")
                                            .font(.caption)

                                        Button {
                                            Task {
                                                try? await MarketplaceService.shared.resubmit(submissionID: sub.id)
                                            }
                                        } label: {
                                            HStack {
                                                Spacer()
                                                Text("Resubmit for Review")
                                                    .font(.subheadline.bold())
                                                Spacer()
                                            }
                                            .padding()
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Review Audit")
        }
        .sheet(isPresented: Binding(
            get: { respondingToID != nil },
            set: { if !$0 { respondingToID = nil } }
        )) {
            if let id = respondingToID {
                responseSheet(feedbackID: id)
            }
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
