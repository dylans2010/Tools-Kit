import Foundation
import Combine
final class PRManager: ObservableObject {
    static let shared = PRManager()
    @Published var pullRequests: [PullRequest] = []
    private init() {}
}