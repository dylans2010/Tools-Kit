import Foundation
import Combine

/// Manages forking operations for Collaboration Spaces.
final class ForkManager: ObservableObject {
    static let shared = ForkManager()

    /// Represents a fork relationship.
    struct ForkInfo: Identifiable, Codable {
        let id: UUID
        let originalSpaceID: UUID
        let forkSpaceID: UUID
        let forkDate: Date
        var upstreamSyncDate: Date?
    }

    @Published var forks: [ForkInfo] = []
    private let storageKey = "com.tools-kit.collaboration.forks"

    private init() {
        loadForks()
    }

    func forkSpace(id: UUID, newName: String) -> CollaborationSpace? {
        guard let originalSpace = CollaborationManager.shared.spaces.first(where: { $0.id == id }) else { return nil }

        // Create deep copy of space
        var forkedSpace = originalSpace
        forkedSpace = CollaborationSpace(
            id: UUID(),
            name: newName,
            description: "Forked from \(originalSpace.name)",
            icon: originalSpace.icon,
            visibility: .privateSpace,
            members: [],
            branches: originalSpace.branches,
            currentBranchID: originalSpace.currentBranchID,
            activityFeed: [],
            notebookIDs: originalSpace.notebookIDs,
            slideDeckIDs: originalSpace.slideDeckIDs,
            meetingIDs: originalSpace.meetingIDs,
            formIDs: originalSpace.formIDs,
            spreadsheetIDs: originalSpace.spreadsheetIDs,
            mediaProjectIDs: originalSpace.mediaProjectIDs,
            createdAt: Date(),
            updatedAt: Date()
        )

        CollaborationManager.shared.spaces.append(forkedSpace)

        let forkInfo = ForkInfo(
            id: UUID(),
            originalSpaceID: originalSpace.id,
            forkSpaceID: forkedSpace.id,
            forkDate: Date()
        )
        forks.append(forkInfo)
        saveForks()

        return forkedSpace
    }

    func syncWithUpstream(forkID: UUID) async throws {
        // Logic to fetch changes from originalSpace and apply to fork
        if let index = forks.firstIndex(where: { $0.id == forkID }) {
            forks[index].upstreamSyncDate = Date()
            saveForks()
        }
    }

    // MARK: - Persistence

    private func saveForks() {
        if let encoded = try? JSONEncoder().encode(forks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadForks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ForkInfo].self, from: data) {
            forks = decoded
        }
    }
}
