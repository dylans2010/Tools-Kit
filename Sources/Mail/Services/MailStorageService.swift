import Foundation

class MailStorageService: ObservableObject {
    static let shared = MailStorageService()
    private let fileManager = FileManager.default
    @Published var threads: [MailThread] = []
    private var activeFolderId: String?

    private var baseDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mailDir = docs.appendingPathComponent("Workspace/Mail", isDirectory: true)
        if !fileManager.fileExists(atPath: mailDir.path) {
            try? fileManager.createDirectory(at: mailDir, withIntermediateDirectories: true)
        }
        return mailDir
    }

    func saveThreads(_ threads: [MailThread], for folderId: String) {
        let fileURL = baseDirectory.appendingPathComponent("threads_\(folderId).json")
        do {
            let data = try JSONEncoder().encode(threads)
            try data.write(to: fileURL)
            activeFolderId = folderId
            DispatchQueue.main.async {
                self.threads = threads
            }
        } catch {
            print("Failed to save threads: \(error)")
        }
    }

    func loadThreads(for folderId: String) -> [MailThread] {
        let fileURL = baseDirectory.appendingPathComponent("threads_\(folderId).json")
        guard fileManager.fileExists(atPath: fileURL.path) else {
            activeFolderId = folderId
            DispatchQueue.main.async { self.threads = [] }
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([MailThread].self, from: data)
            activeFolderId = folderId
            DispatchQueue.main.async {
                self.threads = decoded
            }
            return decoded
        } catch {
            print("Failed to load threads: \(error)")
            return []
        }
    }

    func saveAccounts(_ accounts: [MailAccount]) {
        let fileURL = baseDirectory.appendingPathComponent("accounts.json")
        do {
            let data = try JSONEncoder().encode(accounts)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save accounts: \(error)")
        }
    }

    func loadAccounts() -> [MailAccount] {
        let fileURL = baseDirectory.appendingPathComponent("accounts.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([MailAccount].self, from: data)
        } catch {
            print("Failed to load accounts: \(error)")
            return []
        }
    }
}
