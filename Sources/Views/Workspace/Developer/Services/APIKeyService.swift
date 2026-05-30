import Foundation

/**
 SYSTEM DOMAIN: Network, Configuration
 RESPONSIBILITY: Manages API keys, rotation, and revocation for application authentication.
 */
public class APIKeyService: ObservableObject {
    public static let shared = APIKeyService()
    private let store = DeveloperPersistentStore.shared

    @Published public var keys: [APIKey] = []

    private init() {
        loadKeys()
    }

    public func loadKeys() {
        self.keys = store.keys
    }

    public func createKey(
        label: String,
        type: APIKeyType,
        environment: KeyEnvironment,
        scopeIdentifiers: [String] = [],
        appID: UUID? = nil,
        expiresAt: Date? = nil
    ) async throws -> String {
        let payload = generateSecureRandomPayload()
        let prefix = type == .cli ? "tkcli" : "tk"
        let envString = environment == .test ? "test" : "live"

        // Pattern: {prefix}_{environment}_{base62payload}_{checksum}
        let payloadWithEnv = "\(prefix)_\(envString)_\(payload)"
        let checksum = computeChecksum(for: payloadWithEnv)
        let fullKey = "\(payloadWithEnv)_\(checksum)"

        let masked = "\(prefix)_\(envString)_\(payload.prefix(4))••••••••\(payload.suffix(4))_\(checksum)"

        let newKey = APIKey(
            maskedValue: masked,
            label: label,
            type: type,
            environment: environment,
            appID: appID,
            scopeIdentifiers: scopeIdentifiers,
            expiresAt: expiresAt
        )

        var currentKeys = store.keys
        currentKeys.insert(newKey, at: 0)
        store.saveKeys(currentKeys)

        let updatedKeys = currentKeys
        await MainActor.run {
            self.keys = updatedKeys
        }

        await DeveloperActivityService.shared.logEvent(
            eventType: .keyGenerated,
            appID: appID,
            recordID: newKey.id
        )

        return fullKey
    }

    public func revokeKey(id: UUID, reason: DeveloperKeyRevocationReason, description: String = "") async throws {
        var currentKeys = store.keys
        if let index = currentKeys.firstIndex(where: { $0.id == id }) {
            currentKeys[index].isRevoked = true
            currentKeys[index].revokedAt = Date()
            currentKeys[index].revokedReason = reason
            currentKeys[index].notes = description

            store.saveKeys(currentKeys)

            let updatedKeys = currentKeys
            await MainActor.run {
                self.keys = updatedKeys
            }

            await DeveloperActivityService.shared.logEvent(
                eventType: .keyRevoked,
                appID: currentKeys[index].appID,
                recordID: id
            )
        }
    }

    public func rotateKey(id: UUID) async throws -> String {
        guard let oldKey = store.keys.first(where: { $0.id == id }) else {
            throw NSError(domain: "APIKeyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Key not found"])
        }

        try await revokeKey(id: id, reason: .rotated)

        let newKeyString = try await createKey(
            label: oldKey.label,
            type: oldKey.type,
            environment: oldKey.environment,
            scopeIdentifiers: oldKey.scopeIdentifiers,
            appID: oldKey.appID,
            expiresAt: oldKey.expiresAt
        )

        if let newKeyRecordIndex = store.keys.firstIndex(where: { $0.label == oldKey.label && !$0.isRevoked }) {
            var updatedKeys = store.keys
            let rotationRecord = KeyRotationRecord(previousKeyMasked: oldKey.maskedValue)
            updatedKeys[newKeyRecordIndex].rotationHistory.append(rotationRecord)
            store.saveKeys(updatedKeys)
            let refreshedKeys = updatedKeys
            await MainActor.run {
                self.keys = refreshedKeys
            }
        }

        await DeveloperActivityService.shared.logEvent(
            eventType: .keyRotated,
            appID: oldKey.appID,
            recordID: oldKey.id
        )

        return newKeyString
    }

    public func updateKeyMetadata(id: UUID, label: String, notes: String, ipAllowlist: [String]) async throws {
        var currentKeys = store.keys
        if let index = currentKeys.firstIndex(where: { $0.id == id }) {
            currentKeys[index].label = label
            currentKeys[index].notes = notes
            currentKeys[index].ipAllowlist = ipAllowlist

            store.saveKeys(currentKeys)
            let updatedKeys = currentKeys
            await MainActor.run {
                self.keys = updatedKeys
            }
        }
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

    private func computeChecksum(for input: String) -> String {
        // Deterministic checksum from preceding segments
        let hash = input.hash
        let checksumBase62 = String(abs(hash), radix: 36)
        return String(checksumBase62.suffix(6))
    }
}
