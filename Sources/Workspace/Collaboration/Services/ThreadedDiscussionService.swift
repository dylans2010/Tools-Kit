import Foundation

class ThreadedDiscussionService: ObservableObject {
    static let shared = ThreadedDiscussionService()

    @Published var threads: [DiscussionThread] = []

    private init() {}

    func postComment(threadID: UUID, text: String) {
        if let index = threads.firstIndex(where: { $0.id == threadID }) {
            threads[index].comments.append(Comment(id: UUID(), author: "You", text: text, timestamp: Date()))
        }
    }
}

struct DiscussionThread: Identifiable {
    let id: UUID
    let targetID: UUID // ID of the object being discussed
    var comments: [Comment]
}

struct Comment: Identifiable {
    let id: UUID
    let author: String
    let text: String
    let timestamp: Date
}
