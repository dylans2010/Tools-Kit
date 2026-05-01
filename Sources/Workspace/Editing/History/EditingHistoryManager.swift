import Foundation
import Combine

/// Represents a single change state in the editing history.
struct EditingState: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let projectSnapshot: EditingProject
    let description: String
}

/// Manages non-destructive editing history and branching edit states.
final class EditingHistoryManager: ObservableObject {
    @Published var history: [EditingState] = []
    @Published var currentIndex: Int = -1

    private let projectID: UUID

    init(projectID: UUID) {
        self.projectID = projectID
    }

    /// Adds a new state to the history.
    func pushState(_ project: EditingProject, description: String) {
        // If we are in the middle of history, discard future states
        if currentIndex < history.count - 1 {
            history.removeSubrange((currentIndex + 1)...)
        }

        let state = EditingState(id: UUID(), timestamp: Date(), projectSnapshot: project, description: description)
        history.append(state)
        currentIndex = history.count - 1
    }

    /// Reverts to the previous state.
    func undo() -> EditingProject? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return history[currentIndex].projectSnapshot
    }

    /// Moves forward to the next state.
    func redo() -> EditingProject? {
        guard currentIndex < history.count - 1 else { return nil }
        currentIndex += 1
        return history[currentIndex].projectSnapshot
    }

    /// Jumps to a specific historical snapshot.
    func jumpTo(index: Int) -> EditingProject? {
        guard index >= 0 && index < history.count else { return nil }
        currentIndex = index
        return history[currentIndex].projectSnapshot
    }
}
