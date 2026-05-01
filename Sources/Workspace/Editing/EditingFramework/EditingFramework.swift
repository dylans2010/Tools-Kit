import Foundation

struct EditingOperation: Identifiable {
    let id: UUID
    let projectID: UUID
    let name: String
    let metadata: [String: String]
    let createdAt: Date
}

final class EditingFramework {
    static let shared = EditingFramework()
    private(set) var operations: [EditingOperation] = []

    func record(projectID: UUID, name: String, metadata: [String: String] = [:]) {
        operations.append(.init(id: UUID(), projectID: projectID, name: name, metadata: metadata, createdAt: Date()))
    }
}
