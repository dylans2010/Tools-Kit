import Foundation
import Appwrite

enum AuthDatabaseError: LocalizedError {
    case missingConfig

    var errorDescription: String? {
        switch self {
        case .missingConfig:
            return "Missing Appwrite auth database configuration in Config.plist"
        }
    }
}

final class AuthDatabaseService {
    static let shared = AuthDatabaseService()

    private let databases = Databases(client)
    private let databaseId: String?
    private let usersCollectionId: String?

    private init() {
        self.databaseId = Self.configValue(forKey: "APPWRITE_AUTH_DATABASE_ID")
        self.usersCollectionId = Self.configValue(forKey: "APPWRITE_AUTH_USERS_COLLECTION_ID")
    }

    func upsertUserProfile(userId: String, email: String, name: String?, provider: String) async throws {
        guard let databaseId, let usersCollectionId else {
            throw AuthDatabaseError.missingConfig
        }

        let payload: [String: Any] = [
            "email": email,
            "name": name ?? "",
            "provider": provider,
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]

        _ = try await databases.upsertDocument(
            databaseId: databaseId,
            collectionId: usersCollectionId,
            documentId: userId,
            data: payload
        )
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
