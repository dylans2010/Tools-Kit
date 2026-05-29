import Foundation

public class MarketplaceService: ObservableObject {
    public static let shared = MarketplaceService()

    @Published public var submissions: [MarketplaceSubmission] = []
    @Published public var drafts: [MarketplaceSubmissionDraft] = []

    private init() {
        loadSubmissions()
        loadDrafts()
    }

    public func loadSubmissions() {
        // Awaiting backend integration
    }

    public func loadDrafts() {
        // Awaiting backend integration
    }

    public func saveDraft(_ draft: MarketplaceSubmissionDraft) async throws {
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = draft
        } else {
            drafts.append(draft)
        }
        // Awaiting backend integration
    }

    public func submitApp(draft: MarketplaceSubmissionDraft) async throws {
        let submission = MarketplaceSubmission(
            appID: draft.appID,
            metadata: draft.metadata,
            assets: draft.assets,
            technicalDetails: draft.technicalDetails,
            supportConfig: draft.supportConfig,
            dataHandling: draft.dataHandling
        )
        submissions.append(submission)
        drafts.removeAll { $0.id == draft.id }
        // Awaiting backend integration
    }

    public func respondToReview(feedbackItemID: UUID, message: String) async throws {
        let response = ReviewResponse(feedbackItemID: feedbackItemID, message: message)
        // Find submission and append response
        // Awaiting backend integration
    }

    public func updateListingStatus(submissionID: UUID, newStatus: SubmissionStatus, reason: String) async throws {
        if let index = submissions.firstIndex(where: { $0.id == submissionID }) {
            submissions[index].status = newStatus
            let event = SubmissionStatusEvent(status: newStatus, reason: reason)
            submissions[index].statusHistory.append(event)
        }
        // Awaiting backend integration
    }
}
