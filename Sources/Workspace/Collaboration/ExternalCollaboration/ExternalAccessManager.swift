import Foundation

/// Represents an external guest user with temporary access.
struct GuestUser: Identifiable, Codable {
    let id: UUID
    let email: String
    var role: SpaceRole
    let invitedAt: Date
    var expiresAt: Date?
    let inviteToken: String
}

/// Manages external guest access and temporary invite links.
final class ExternalAccessManager: ObservableObject {
    static let shared = ExternalAccessManager()

    @Published var guestsBySpace: [UUID: [GuestUser]] = [:] // SpaceID: Guests

    private init() {}

    func inviteGuest(spaceID: UUID, email: String, role: SpaceRole, duration: TimeInterval?) -> String {
        let token = UUID().uuidString
        let guest = GuestUser(
            id: UUID(),
            email: email,
            role: role,
            invitedAt: Date(),
            expiresAt: duration != nil ? Date().addingTimeInterval(duration!) : nil,
            inviteToken: token
        )

        var current = guestsBySpace[spaceID] ?? []
        current.append(guest)
        guestsBySpace[spaceID] = current
        return "tools-kit.app/join/\(token)"
    }

    func revokeAccess(spaceID: UUID, guestID: UUID) {
        guestsBySpace[spaceID]?.removeAll { $0.id == guestID }
    }
}
