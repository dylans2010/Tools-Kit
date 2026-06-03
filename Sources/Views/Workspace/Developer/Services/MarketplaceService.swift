import Foundation

public class MarketplaceService: ObservableObject {
    public static let shared = MarketplaceService()
    private let store = DeveloperPersistentStore.shared

    @Published public var submissions: [MarketplaceSubmission] = []
    @Published public var drafts: [MarketplaceSubmissionDraft] = []

    private init() {
        loadSubmissions()
        loadDrafts()
    }

    public func loadSubmissions() {
        self.submissions = store.submissions
    }

    public func loadDrafts() {
        self.drafts = store.drafts
    }

    public func saveDraft(_ draft: MarketplaceSubmissionDraft) async throws {
        var currentDrafts = store.drafts
        var updatedDraft = draft
        updatedDraft.lastSavedAt = Date()

        if let index = currentDrafts.firstIndex(where: { $0.id == draft.id }) {
            currentDrafts[index] = updatedDraft
        } else {
            currentDrafts.append(updatedDraft)
        }

        store.saveDrafts(currentDrafts)

        let updatedDrafts = currentDrafts
        await MainActor.run {
            self.drafts = updatedDrafts
        }
    }

    public func deleteDraft(id: UUID) async throws {
        var currentDrafts = store.drafts
        currentDrafts.removeAll { $0.id == id }
        store.saveDrafts(currentDrafts)
        let updatedDrafts = currentDrafts
        await MainActor.run {
            self.drafts = updatedDrafts
        }
    }

    public func submitApp(draft: MarketplaceSubmissionDraft) async throws {
        let submission = MarketplaceSubmission(
            appID: draft.appID,
            status: .pendingReview,
            submittedAt: Date(),
            statusHistory: [SubmissionStatusEvent(status: .pendingReview, reason: "Initial submission")],
            metadata: draft.metadata,
            assets: draft.assets,
            technicalDetails: draft.technicalDetails,
            supportConfig: draft.supportConfig,
            dataHandling: draft.dataHandling
        )

        var currentSubmissions = store.submissions
        currentSubmissions.append(submission)
        store.saveSubmissions(currentSubmissions)

        // Remove draft upon successful submission
        try await deleteDraft(id: draft.id)

        let updatedSubmissions = currentSubmissions
        await MainActor.run {
            self.submissions = updatedSubmissions
        }

        await DeveloperActivityService.shared.logEvent(
            eventType: .submissionCompleted,
            appID: draft.appID,
            appName: draft.metadata.title
        )
    }

    public func respondToReview(feedbackItemID: UUID, message: String) async throws {
        var currentSubmissions = store.submissions
        for i in 0..<currentSubmissions.count {
            if currentSubmissions[i].reviewFeedback.contains(where: { $0.id == feedbackItemID }) {
                let response = ReviewResponse(feedbackItemID: feedbackItemID, message: message)
                currentSubmissions[i].reviewResponses.append(response)

                // Mark feedback as resolved when responded (policy dependent, but logical for this implementation)
                if let feedbackIndex = currentSubmissions[i].reviewFeedback.firstIndex(where: { $0.id == feedbackItemID }) {
                    currentSubmissions[i].reviewFeedback[feedbackIndex].isResolved = true
                }
            }
        }

        store.saveSubmissions(currentSubmissions)
        let updatedSubmissions = currentSubmissions
        await MainActor.run {
            self.submissions = updatedSubmissions
        }
    }

    public func updateListingStatus(submissionID: UUID, newStatus: SubmissionStatus, reason: String) async throws {
        var currentSubmissions = store.submissions
        if let index = currentSubmissions.firstIndex(where: { $0.id == submissionID }) {
            currentSubmissions[index].status = newStatus
            let event = SubmissionStatusEvent(status: newStatus, reason: reason)
            currentSubmissions[index].statusHistory.append(event)

            store.saveSubmissions(currentSubmissions)

            let updatedSubmissions = currentSubmissions
            await MainActor.run {
                self.submissions = updatedSubmissions
            }

            // Also update the linked DeveloperApp status if it transitions to Live
            if newStatus == .live {
                try await DeveloperAppService.shared.transitionStatus(id: currentSubmissions[index].appID, newStatus: .live, reason: "Marketplace listing went live.")
            }
        }
    }

    public func resubmit(submissionID: UUID) async throws {
        var currentSubmissions = store.submissions
        if let index = currentSubmissions.firstIndex(where: { $0.id == submissionID }) {
            currentSubmissions[index].status = .pendingReview
            currentSubmissions[index].statusHistory.append(SubmissionStatusEvent(status: .pendingReview, reason: "Resubmitted by developer after addressing feedback."))
            store.saveSubmissions(currentSubmissions)
            let updatedSubmissions = currentSubmissions
            await MainActor.run { self.submissions = updatedSubmissions }
        }
    }
}
