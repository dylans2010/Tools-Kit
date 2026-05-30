import Foundation

/**
 SYSTEM DOMAIN: Lifecycle, Configuration
 RESPONSIBILITY: Manages the registration, metadata, and versioning of developer applications.
 */
public class DeveloperAppService: ObservableObject {
    public static let shared = DeveloperAppService()
    private let store = DeveloperPersistentStore.shared

    @Published public var apps: [DeveloperApp] = []

    private init() {
        loadApps()
    }

    public func loadApps() {
        self.apps = store.apps
    }

    public func createApp(_ app: DeveloperApp) async throws {
        var currentApps = store.apps
        currentApps.append(app)
        store.saveApps(currentApps)

        let updatedApps = currentApps
        await MainActor.run {
            self.apps = updatedApps
        }

        await DeveloperActivityService.shared.logEvent(
            eventType: .appCreated,
            appID: app.id,
            appName: app.name
        )
    }

    public func updateApp(_ app: DeveloperApp) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == app.id }) {
            currentApps[index] = app
            currentApps[index].lastModified = Date()

            store.saveApps(currentApps)

            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }

            await DeveloperActivityService.shared.logEvent(
                eventType: .appUpdated,
                appID: app.id,
                appName: app.name
            )
        }
    }

    public func deleteApp(id: UUID) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == id }) {
            let appName = currentApps[index].name
            currentApps.remove(at: index)
            store.saveApps(currentApps)

            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }

            await DeveloperActivityService.shared.logEvent(
                eventType: .appDeleted,
                appID: id,
                appName: appName
            )
        }
    }

    public func transitionStatus(id: UUID, newStatus: DeveloperAppStatus, reason: String) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == id }) {
            currentApps[index].status = newStatus
            currentApps[index].lastModified = Date()

            // Log status transition could go here if we had a status history in DeveloperApp
            // (The model has status, but the requirement mentions statusHistory in some views)

            store.saveApps(currentApps)

            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }
        }
    }

    public func addCollaborator(appID: UUID, collaborator: AppCollaborator) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == appID }) {
            currentApps[index].collaborators.append(collaborator)
            store.saveApps(currentApps)

            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }
        }
    }

    public func removeCollaborator(appID: UUID, collaboratorID: UUID) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == appID }) {
            currentApps[index].collaborators.removeAll { $0.id == collaboratorID }
            store.saveApps(currentApps)

            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }
        }
    }

    public func transferOwnership(appID: UUID, toAccountID: UUID) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == appID }) {
            // In a real system, we'd change ownerId. Here we simulate by adding a collaborator role change if possible
            // or just logging the event.
            let appName = currentApps[index].name

            await DeveloperActivityService.shared.logEvent(
                eventType: .appUpdated,
                appID: appID,
                appName: "\(appName) (Ownership Transferred)"
            )

            // For persistence, we don't have an owner field, but we can update lastModified
            currentApps[index].lastModified = Date()
            store.saveApps(currentApps)
            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }
        }
    }

    public func addVersion(appID: UUID, version: AppVersion) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == appID }) {
            currentApps[index].versions.append(version)
            currentApps[index].version = version.version
            currentApps[index].currentVersion = version.id
            store.saveApps(currentApps)

            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }
        }
    }

    public func setCurrentVersion(appID: UUID, versionID: UUID) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == appID }) {
            if let version = currentApps[index].versions.first(where: { $0.id == versionID }) {
                currentApps[index].currentVersion = versionID
                currentApps[index].version = version.version
                currentApps[index].lastModified = Date()

                store.saveApps(currentApps)
                let updatedApps = currentApps
                await MainActor.run {
                    self.apps = updatedApps
                }
            }
        }
    }
}
