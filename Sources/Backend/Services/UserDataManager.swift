import Foundation
import Appwrite

final class UserDataManager {
    nonisolated(unsafe) static let shared = UserDataManager()

    private let databases = Databases(AppwriteService.client)
    private let appwriteAccount = AppwriteService.account

    private let databaseId: String?
    private let collectionId: String?

    private init() {
        self.databaseId = Self.configValue(forKey: "APPWRITE_USERDATA_DATABASE_ID")
        self.collectionId = Self.configValue(forKey: "APPWRITE_USERDATA_COLLECTION_ID")
    }

    func syncAfterLogin() async {
        do {
            _ = try await restoreCurrentUserData()
        } catch {
            print("UserDataManager restore failed: \(error.localizedDescription)")
        }

        do {
            try await uploadCurrentUserData()
        } catch {
            print("UserDataManager upload failed: \(error.localizedDescription)")
        }
    }

    func uploadCurrentUserData() async throws {
        guard let databaseId, let collectionId else { return }

        let user = try await appwriteAccount.get()
        let snapshot = try buildSnapshot()
        let data = try JSONEncoder().encode(snapshot)
        let payload = data.base64EncodedString()

        let documentData: [String: Any] = [
            "snapshot": payload,
            "updatedAt": ISO8601DateFormatter().string(from: Date()),
            "platform": "ios"
        ]

        do {
            _ = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: collectionId,
                documentId: user.id
            )
            _ = try await databases.updateDocument(
                databaseId: databaseId,
                collectionId: collectionId,
                documentId: user.id,
                data: documentData
            )
        } catch {
            _ = try await databases.createDocument(
                databaseId: databaseId,
                collectionId: collectionId,
                documentId: user.id,
                data: documentData
            )
        }
    }

    @discardableResult
    func restoreCurrentUserData() async throws -> Bool {
        guard let databaseId, let collectionId else { return false }

        let user = try await appwriteAccount.get()
        let document = try await databases.getDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: user.id
        )

        let encodedDoc = try JSONEncoder().encode(document)
        guard
            let root = try JSONSerialization.jsonObject(with: encodedDoc) as? [String: Any],
            let data = root["data"] as? [String: Any],
            let snapshotBase64 = data["snapshot"] as? String,
            let snapshotData = Data(base64Encoded: snapshotBase64),
            let snapshot = try? JSONDecoder().decode(UserDataSnapshot.self, from: snapshotData)
        else {
            return false
        }

        try apply(snapshot: snapshot)
        return true
    }

    private func buildSnapshot() throws -> UserDataSnapshot {
        let workspaceDir = workspaceDirectory
        let files = try collectFiles(in: workspaceDir)

        let aiSettingsData = UserDefaults.standard.data(forKey: "AIChatSettings")
        let aiSettingsBase64 = aiSettingsData?.base64EncodedString()

        return UserDataSnapshot(
            version: 1,
            capturedAt: Date(),
            files: files,
            aiSettingsBase64: aiSettingsBase64
        )
    }

    private func apply(snapshot: UserDataSnapshot) throws {
        for file in snapshot.files {
            guard let data = Data(base64Encoded: file.base64Data) else { continue }
            let destination = workspaceDirectory.appendingPathComponent(file.relativePath)
            let parent = destination.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try data.write(to: destination, options: .atomic)
        }

        if
            let aiSettingsBase64 = snapshot.aiSettingsBase64,
            let aiSettingsData = Data(base64Encoded: aiSettingsBase64)
        {
            UserDefaults.standard.set(aiSettingsData, forKey: "AIChatSettings")
        }
    }

    private func collectFiles(in directory: URL) throws -> [CloudWorkspaceFile] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }

        let urls = try FileManager.default.subpathsOfDirectory(atPath: directory.path)
        var result: [CloudWorkspaceFile] = []

        for relative in urls {
            let fileURL = directory.appendingPathComponent(relative)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue else {
                continue
            }

            guard let data = try? Data(contentsOf: fileURL) else { continue }
            result.append(CloudWorkspaceFile(relativePath: relative, base64Data: data.base64EncodedString()))
        }

        return result
    }

    private var workspaceDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func configValue(forKey key: String) -> String? {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return value
    }
}

private struct UserDataSnapshot: Codable, Sendable {
    let version: Int
    let capturedAt: Date
    let files: [CloudWorkspaceFile]
    let aiSettingsBase64: String?
}

private struct CloudWorkspaceFile: Codable, Sendable {
    let relativePath: String
    let base64Data: String
}
