import Foundation
import CloudKit
import Combine
import OSLog

public final class CloudKitSyncEngine: ObservableObject {
    public static let shared = CloudKitSyncEngine()

    private let service = CloudKitService.shared
    private let logger = Logger(subsystem: "com.toolskit.app", category: "CloudKitSyncEngine")

    @Published public private(set) var isSyncing = false
    @Published public private(set) var lastSyncDate: Date?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.lastSyncDate = UserDefaults.standard.object(forKey: "CloudKitLastSyncDate") as? Date
    }

    public func sync() async {
        guard !isSyncing else { return }

        await MainActor.run { isSyncing = true }
        logger.info("Starting CloudKit sync...")

        var retryCount = 0
        let maxRetries = 3
        var success = false

        while retryCount < maxRetries && !success {
            do {
                try await pushChanges()
                try await fetchChanges()

                await MainActor.run {
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(self.lastSyncDate, forKey: "CloudKitLastSyncDate")
                    self.isSyncing = false
                }
                logger.info("CloudKit sync completed successfully.")
                success = true
            } catch {
                retryCount += 1
                logger.error("CloudKit sync failed (attempt \(retryCount)): \(error.localizedDescription)")
                if retryCount < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount))) * 1_000_000_000)
                }
            }
        }

        if !success {
            await MainActor.run { isSyncing = false }
        }
    }

    private func pushChanges() async throws {
        logger.info("Pushing local changes to CloudKit...")

        var recordsToSave: [CKRecord] = []

        // 1. Push Projects
        let projects = await SDKProjectManager.shared.projects
        recordsToSave.append(contentsOf: projects.map { $0.toCKRecord() })

        // 2. Push Notes
        // We need to access a central Notes store.
        // Since NotesBackend is not a singleton, we'll use a temporary instance or
        // ideally NotesBackend should be refactored to use a shared store.
        // For now, we'll assume a shared access pattern.
        let notesBackend = await MainActor.run { NotesBackend() }
        recordsToSave.append(contentsOf: notesBackend.notes.map { $0.toCKRecord() })

        // 3. Push Tasks
        let tasks = await TasksManager.shared.tasks
        recordsToSave.append(contentsOf: tasks.map { $0.toCKRecord() })

        if !recordsToSave.isEmpty {
            try await service.batchSave(recordsToSave)
            logger.info("Successfully pushed \(recordsToSave.count) records.")
        }
    }

    private func fetchChanges() async throws {
        logger.info("Fetching remote changes from CloudKit...")

        // Fetch Workspaces
        let remoteWorkspaces = try await service.fetchRecords(ofType: CloudKitSchema.RecordType.workspace)
        for record in remoteWorkspaces {
            if let remoteProject = SDKProject.fromCKRecord(record) {
                await resolveProjectConflict(remote: remoteProject)
            }
        }

        // Fetch Notes
        let remoteNotes = try await service.fetchRecords(ofType: CloudKitSchema.RecordType.note)
        for record in remoteNotes {
            if let remoteNote = Note.fromCKRecord(record) {
                await resolveNoteConflict(remote: remoteNote)
            }
        }

        // Fetch Tasks
        let remoteTasks = try await service.fetchRecords(ofType: CloudKitSchema.RecordType.task)
        for record in remoteTasks {
            if let remoteTask = WorkspaceTask.fromCKRecord(record) {
                await resolveTaskConflict(remote: remoteTask)
            }
        }
    }

    @MainActor
    private func resolveProjectConflict(remote: SDKProject) {
        let projectManager = SDKProjectManager.shared
        if let local = projectManager.projects.first(where: { $0.id == remote.id }) {
            if remote.updatedAt > local.updatedAt {
                logger.info("Remote project '\(remote.name)' is newer. Updating local.")
                projectManager.updateProject(remote)
            }
        } else {
            logger.info("New remote project '\(remote.name)' found. Adding to local.")
            projectManager.projects.append(remote)
            try? projectManager.save()
        }
    }

    @MainActor
    private func resolveNoteConflict(remote: Note) {
        let backend = NotesBackend() // Temporary instance to access and save
        if let local = backend.notes.first(where: { $0.id == remote.id }) {
            if remote.updatedAt > local.updatedAt {
                logger.info("Remote note '\(remote.title)' is newer. Updating local.")
                backend.updateNote(remote)
            }
        } else {
            logger.info("New remote note '\(remote.title)' found. Adding to local.")
            backend.notes.append(remote)
            backend.saveNotes()
        }
    }

    @MainActor
    private func resolveTaskConflict(remote: WorkspaceTask) {
        let manager = TasksManager.shared
        if let local = manager.tasks.first(where: { $0.id == remote.id }) {
            // WorkspaceTask doesn't have updatedAt, we'll use createdAt or assume remote is newer if it exists
            // In production, we should add updatedAt to WorkspaceTask
            manager.updateTask(remote)
        } else {
            logger.info("New remote task '\(remote.title)' found. Adding to local.")
            manager.addTask(remote)
        }
    }

    public func resetCloudData() async throws {
        logger.warning("Resetting CloudKit data...")

        let recordTypes = [
            CloudKitSchema.RecordType.note,
            CloudKitSchema.RecordType.task,
            CloudKitSchema.RecordType.workspace
        ]

        for type in recordTypes {
            let records = try await service.fetchRecords(ofType: type)
            for record in records {
                try await service.deleteRecord(id: record.recordID)
            }
        }

        logger.info("CloudKit data reset completed.")
    }
}
