import Foundation

class RepoSyncService {
    static let shared = RepoSyncService()

    private init() {}

    func syncIssuesToTasks(repoID: String) async {
        // Mock sync logic
        print("Syncing GitHub issues to workspace tasks for \(repoID)")
    }
}
