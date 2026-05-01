import Foundation

/// Represents an active participant in a live session.
struct LiveParticipant: Identifiable, Codable {
    let id: UUID
    let name: String
    var cursorPosition: CGPoint?
    var activeObjectID: UUID?
}

/// Manages real-time collaborative sessions.
final class LiveStudioManager: ObservableObject {
    static let shared = LiveStudioManager()

    @Published var activeParticipants: [LiveParticipant] = []

    private init() {}

    func joinSession(spaceID: UUID, user: SpaceMember) {
        let participant = LiveParticipant(id: user.id, name: user.name)
        activeParticipants.append(participant)
    }

    func updatePosition(userID: UUID, position: CGPoint) {
        if let index = activeParticipants.firstIndex(where: { $0.id == userID }) {
            activeParticipants[index].cursorPosition = position
        }
    }
}
