import Foundation

public class SecretService: ObservableObject {
    public static let shared = SecretService()
    private let store = DeveloperPersistentStore.shared

    @Published public var secrets: [Secret] = []

    private init() { loadSecrets() }

    public func loadSecrets() { self.secrets = store.secrets }

    public func saveSecret(_ secret: Secret) async throws {
        var current = store.secrets
        current.insert(secret, at: 0)
        store.saveSecrets(current)
        await MainActor.run { self.secrets = current }
    }
}
