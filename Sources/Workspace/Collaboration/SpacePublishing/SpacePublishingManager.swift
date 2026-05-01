import Foundation

/// Defines a release of a published space.
struct SpaceRelease: Identifiable, Codable {
    let id: UUID
    let version: String
    let commitID: UUID
    let releaseNotes: String
    let timestamp: Date
}

/// Manages publishing collaboration spaces for external or public consumption.
final class SpacePublishingManager: ObservableObject {
    static let shared = SpacePublishingManager()

    @Published var publishedSpaces: Set<UUID> = []
    @Published var releases: [UUID: [SpaceRelease]] = [:] // SpaceID: Releases

    private let storageKey = "com.tools-kit.collaboration.publishing"

    private init() {
        loadPublishedData()
    }

    func publishSpace(id: UUID) {
        publishedSpaces.insert(id)
        savePublishedData()
    }

    func unpublishSpace(id: UUID) {
        publishedSpaces.remove(id)
        savePublishedData()
    }

    func createRelease(spaceID: UUID, version: String, notes: String, commitID: UUID) {
        let release = SpaceRelease(id: UUID(), version: version, commitID: commitID, releaseNotes: notes, timestamp: Date())
        var current = releases[spaceID] ?? []
        current.insert(release, at: 0)
        releases[spaceID] = current
        savePublishedData()
    }

    private func savePublishedData() {
        // Persist publishedIDs and releases
    }

    private func loadPublishedData() {
        // Load persisted data
    }
}
