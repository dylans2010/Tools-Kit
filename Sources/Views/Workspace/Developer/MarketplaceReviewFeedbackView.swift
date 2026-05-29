import SwiftUI

struct MarketplaceReviewFeedbackView: View {
    let submissionID: UUID
    @ObservedObject var marketplaceService = MarketplaceService.shared

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
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Review Feedback")
    }

    private func severityBadge(_ severity: String) -> some View {
        Text(severity).font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(severity == "Blocking" ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
            .foregroundStyle(severity == "Blocking" ? .red : .orange)
            .clipShape(Capsule())
    }
}
