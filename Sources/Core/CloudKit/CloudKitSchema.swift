import Foundation

enum CloudKitSchema {
    enum RecordType {
        static let note = "Note"
        static let task = "Task"
        static let workspace = "Workspace"
    }

    enum NoteKeys {
        static let title = "title"
        static let content = "content"
        static let folder = "folder"
        static let tags = "tags"
        static let isPinned = "isPinned"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    enum TaskKeys {
        static let title = "title"
        static let taskDescription = "taskDescription"
        static let dueDate = "dueDate"
        static let priority = "priority"
        static let completed = "completed"
        static let createdAt = "createdAt"
    }

    enum WorkspaceKeys {
        static let name = "name"
        static let workspaceDescription = "workspaceDescription"
        static let status = "status"
        static let version = "version"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }
}
