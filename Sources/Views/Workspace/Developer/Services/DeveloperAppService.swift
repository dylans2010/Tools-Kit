import Foundation

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

    public func transferOwnership(appID: UUID, toEmail: String) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == appID }) {
            let appName = currentApps[index].name

            // Real mutation: in a multi-user system we'd change ownerID.
            // Here we'll add the new owner as a collaborator with 'Owner' role
            // and log the event.
            let newOwner = AppCollaborator(accountID: UUID(), name: toEmail.components(separatedBy: "@").first ?? "New Owner", email: toEmail, role: "Owner")
            currentApps[index].collaborators.append(newOwner)

            store.saveApps(currentApps)
            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }

            await DeveloperActivityService.shared.logEvent(
                eventType: .appUpdated,
                appID: appID,
                appName: "\(appName) (Ownership Transferred to \(toEmail))"
            )
        }
    }

    public func addVersion(appID: UUID, version: AppVersion) async throws {
        var currentApps = store.apps
        if let index = currentApps.firstIndex(where: { $0.id == appID }) {
            currentApps[index].versions.append(version)
            currentApps[index].version = version.version
            store.saveApps(currentApps)

            let updatedApps = currentApps
            await MainActor.run {
                self.apps = updatedApps
            }
        }
    }
}
