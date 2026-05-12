import Foundation
import Combine

/// Central system that connects ALL workspace data.
/// Indexes workspace objects and manages relationships between them.
final class CollaborationFramework: ObservableObject {
    nonisolated(unsafe) static let shared = CollaborationFramework()

    @Published var indexedObjects: [UUID: WorkspaceObjectType] = [:]

    enum WorkspaceObjectType: String, Codable, Sendable {
        case notebook
        case slideDeck
        case meeting
        case form
        case spreadsheet
        case mediaProject
    }

    private init() {}

    /// Normalizes and indexes a workspace object.
    func indexObject(id: UUID, type: WorkspaceObjectType) {
        indexedObjects[id] = type
    }

    /// Unindexes a workspace object.
    func unindexObject(id: UUID) {
        indexedObjects.removeValue(forKey: id)
    }

    /// Global search across all collaboration spaces and indexed objects.
    func globalSearch(query: String) -> [UUID] {
        // Implementation for searching titles/descriptions/content
        return []
    }

    /// Manages cross-system linking between Collaboration and other modules.
    func linkObject(objectID: UUID, to spaceID: UUID) {
        guard let type = indexedObjects[objectID] else { return }
        guard let spaceIndex = CollaborationManager.shared.spaces.firstIndex(where: { $0.id == spaceID }) else { return }

        switch type {
        case .notebook:
            if !CollaborationManager.shared.spaces[spaceIndex].notebookIDs.contains(objectID) {
                CollaborationManager.shared.spaces[spaceIndex].notebookIDs.append(objectID)
            }
        case .slideDeck:
            if !CollaborationManager.shared.spaces[spaceIndex].slideDeckIDs.contains(objectID) {
                CollaborationManager.shared.spaces[spaceIndex].slideDeckIDs.append(objectID)
            }
        case .meeting:
            if !CollaborationManager.shared.spaces[spaceIndex].meetingIDs.contains(objectID) {
                CollaborationManager.shared.spaces[spaceIndex].meetingIDs.append(objectID)
            }
        case .form:
            if !CollaborationManager.shared.spaces[spaceIndex].formIDs.contains(objectID) {
                CollaborationManager.shared.spaces[spaceIndex].formIDs.append(objectID)
            }
        case .spreadsheet:
            if !CollaborationManager.shared.spaces[spaceIndex].spreadsheetIDs.contains(objectID) {
                CollaborationManager.shared.spaces[spaceIndex].spreadsheetIDs.append(objectID)
            }
        case .mediaProject:
            if !CollaborationManager.shared.spaces[spaceIndex].mediaProjectIDs.contains(objectID) {
                CollaborationManager.shared.spaces[spaceIndex].mediaProjectIDs.append(objectID)
            }
        }

        // Notify of update
        CollaborationManager.shared.objectWillChange.send()
    }
}
