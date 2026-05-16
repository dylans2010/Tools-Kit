import Foundation
import Combine

/// Manages real-time notifications for the Collaboration system.
final class CollaborationNotificationService: ObservableObject {
    static let shared = CollaborationNotificationService()

    @Published var unreadCounts: [UUID: Int] = [:]
    @Published var mutedChannels: Set<UUID> = []

    private init() {}

    func incrementUnread(for channelID: UUID) {
        guard !mutedChannels.contains(channelID) else { return }
        unreadCounts[channelID, default: 0] += 1
    }

    func clearUnreads(for channelID: UUID) {
        unreadCounts[channelID] = 0
    }

    func toggleMute(for channelID: UUID) {
        if mutedChannels.contains(channelID) {
            mutedChannels.remove(channelID)
        } else {
            mutedChannels.insert(channelID)
            clearUnreads(for: channelID)
        }
    }

    func getBadgeCount(for workspaceID: UUID) -> Int {
        // Logic to sum unreads for all channels in a workspace
        return unreadCounts.values.reduce(0, +)
    }
}
