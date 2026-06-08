import Foundation
import Combine

@MainActor
public final class RequestsViewModel: ObservableObject {
    @Published public var requests: [FeedbackRequest] = []
    @Published public var isLoading = false

    public init() {}

    public func fetchRequests() async {
        isLoading = true
        requests = await FeedbackService.shared.fetchRequests()
        isLoading = false
    }

    public func vote(for requestId: UUID) {
        if let index = requests.firstIndex(where: { $0.id == requestId }) {
            if requests[index].hasVoted {
                requests[index].votes -= 1
                requests[index].hasVoted = false
            } else {
                requests[index].votes += 1
                requests[index].hasVoted = true
            }
            // In a real app, sync with server here
        }
    }
}
