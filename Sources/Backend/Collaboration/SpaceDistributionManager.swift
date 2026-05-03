import Foundation
import Combine

/// Manages publishing of Collaboration Spaces and template creation.
final class SpaceDistributionManager: ObservableObject {
    static let shared = SpaceDistributionManager()

    @Published var publishedSpaces: [UUID: URL] = [:] // spaceID: publicURL
    @Published var templates: [CollaborationSpace] = []

    private init() {}

    /// Publishes a space to a public URL.
    func publishSpace(spaceID: UUID) -> URL {
        let url = URL(string: "https://tools-kit.com/spaces/\(spaceID.uuidString)")!
        publishedSpaces[spaceID] = url
        return url
    }

    /// Saves a space as a reusable template.
    func saveAsTemplate(spaceID: UUID) {
        guard let space = CollaborationManager.shared.spaces.first(where: { $0.id == spaceID }) else { return }
        var template = space
        template.id = UUID()
        template.name = "\(space.name) Template"
        templates.append(template)
    }
}

/// Manages guest access and temporary tokens for external collaboration.
final class ExternalCollaborationManager: ObservableObject {
    static let shared = ExternalCollaborationManager()

    struct GuestAccess: Codable, Identifiable {
        let id: UUID
        let spaceID: UUID
        let token: String
        let expiresAt: Date
        let role: SpaceRole
    }

    @Published var activeGuestAccess: [GuestAccess] = []

    private init() {}

    func generateInviteLink(spaceID: UUID, role: SpaceRole, duration: TimeInterval) -> String {
        let access = GuestAccess(
            id: UUID(),
            spaceID: spaceID,
            token: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(duration),
            role: role
        )
        activeGuestAccess.append(access)
        return "https://tools-kit.com/invite/\(access.token)"
    }
}
