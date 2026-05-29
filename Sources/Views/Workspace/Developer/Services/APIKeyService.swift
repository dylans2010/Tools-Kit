import Foundation

public class APIKeyService: ObservableObject {
    public static let shared = APIKeyService()

    @Published public var keys: [APIKey] = []

    private init() {
        loadKeys()
    }

    public func loadKeys() {
        // Awaiting backend integration
    }

    public func createKey(
        label: String,
        type: APIKeyType,
        environment: KeyEnvironment,
        scopeIdentifiers: [String] = [],
        appID: UUID? = nil,
        ttl: TimeInterval? = nil
    ) async throws -> String {
        let payload = generateSecureRandomPayload()
        let prefix = type == .cli ? "tkcli_" : "tk_"
        let envSuffix = environment == .test ? "_test" : ""
        let fullKey = "\(prefix)\(payload)\(envSuffix)"

        let masked = "\(prefix)\(payload.prefix(4))••••••••\(payload.suffix(4))\(envSuffix)"

        let newKey = APIKey(
            maskedValue: masked,
            label: label,
            type: type,
            environment: environment,
            appID: appID,
            scopeIdentifiers: scopeIdentifiers,
            expiresAt: ttl != nil ? Date().addingTimeInterval(ttl!) : nil
        )

        keys.append(newKey)
        // Awaiting backend integration

        return fullKey
    }

    public func revokeKey(id: UUID, reason: DeveloperKeyRevocationReason) async throws {
        if let index = keys.firstIndex(where: { $0.id == id }) {
            keys[index].isRevoked = true
            keys[index].revokedAt = Date()
            keys[index].revokedReason = reason
        }
        // Awaiting backend integration
    }

    public func rotateKey(id: UUID) async throws -> String {
        guard let oldKey = keys.first(where: { $0.id == id }) else {
            throw NSError(domain: "APIKeyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Key not found"])
        }

        try await revokeKey(id: id, reason: .rotated)

        return try await createKey(
            label: oldKey.label,
            type: oldKey.type,
            environment: oldKey.environment,
            scopeIdentifiers: oldKey.scopeIdentifiers,
            appID: oldKey.appID
        )
    }

    public func bulkRevoke(ids: [UUID], reason: DeveloperKeyRevocationReason) async throws {
        for id in ids {
            try await revokeKey(id: id, reason: reason)
        }
    }

    private func generateSecureRandomPayload() -> String {
        let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in alphabet.randomElement()! })
    }
}
