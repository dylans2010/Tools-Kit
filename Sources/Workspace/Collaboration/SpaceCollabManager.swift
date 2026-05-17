import Foundation
import Combine

/// Single source of truth for Space-driven collaboration.
@MainActor
final class SpaceCollabManager: ObservableObject {
    static let shared = SpaceCollabManager()

    @Published var spaces: [CollaborationSpace] = []

    private let manager = CollaborationManager.shared

    private init() {
        self.spaces = manager.spaces
    }

    func refresh() {
        self.spaces = manager.spaces
    }

    // MARK: - Space Operations

    func createSpace(name: String, description: String, icon: String, visibility: SpaceVisibility) -> CollaborationSpace {
        let space = manager.createSpace(name: name, description: description, icon: icon, visibility: visibility)
        refresh()
        return space
    }

    func deleteSpace(id: UUID) {
        manager.deleteSpace(id: id)
        refresh()
    }

    // MARK: - Messaging

    func sendMessage(spaceID: UUID, content: String) {
        guard let index = manager.spaces.firstIndex(where: { $0.id == spaceID }) else { return }
        let message = SpaceMessage(
            id: UUID(),
            senderID: UUID(), // Current user
            senderName: "Local User",
            content: content,
            timestamp: Date()
        )
        manager.spaces[index].messages.append(message)
        manager.saveData()
        refresh()
    }

    // MARK: - File Sharing

    func uploadFile(spaceID: UUID, name: String, type: String, size: Int64, localPath: String?) {
        guard let index = manager.spaces.firstIndex(where: { $0.id == spaceID }) else { return }
        let file = SpaceFile(
            id: UUID(),
            name: name,
            size: size,
            type: type,
            uploaderID: UUID(),
            timestamp: Date(),
            localPath: localPath
        )
        manager.spaces[index].sharedFiles.append(file)
        manager.saveData()
        refresh()
    }

    // MARK: - Members

    func addMember(spaceID: UUID, name: String, email: String, role: SpaceRole) {
        guard let index = manager.spaces.firstIndex(where: { $0.id == spaceID }) else { return }
        let member = SpaceMember(id: UUID(), name: name, email: email, role: role)
        manager.spaces[index].members.append(member)
        manager.saveData()
        refresh()
    }
}
