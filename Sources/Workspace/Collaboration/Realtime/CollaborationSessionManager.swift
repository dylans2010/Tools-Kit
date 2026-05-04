import Foundation

@MainActor
class CollaborationSessionManager: ObservableObject {
    static let shared = CollaborationSessionManager()

    @Published var activeUsers: [String] = ["You"]
    @Published var cursorPositions: [String: CGPoint] = [:]

    private init() {}

    func joinSession() {
        activeUsers.append("User_\(Int.random(in: 100...999))")
    }

    func updateCursor(position: CGPoint) {
        cursorPositions["You"] = position
        WebSocketManager.shared.send(message: "cursor:\(position.x),\(position.y)")
    }
}
