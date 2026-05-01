import Foundation
import Combine
final class PRManager: ObservableObject {
    static let shared = PRManager()
    @Published var pullRequests: [PullRequest] = []
    private init() { load() }
    func createPR(spaceID: UUID, title: String) {
        pullRequests.append(PullRequest(id: UUID(), spaceID: spaceID, title: title, status: .open, author: "User"))
        save()
    }
    private func save() { try? WorkspacePersistence.shared.save(pullRequests, filename: "prs.json") }
    private func load() { if let d = try? WorkspacePersistence.shared.load(filename: "prs.json", as: [PullRequest].self) { pullRequests = d } }
}