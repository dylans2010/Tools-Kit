import Foundation

@MainActor
final class AIModelCatalog: ObservableObject {
    nonisolated(unsafe) static let shared = AIModelCatalog()

    @Published private(set) var modelsByProvider: [String: [AIModel]] = [:]
    @Published private(set) var loadingProviders: Set<String> = []

    private let registry = AIProviderRegistry.shared
    private let keyManager = APIKeyManager.shared

    func models(for providerID: String) -> [AIModel] {
        modelsByProvider[providerID] ?? []
    }

    func loadModels(for providerID: String, force: Bool = false) async {
        if !force, modelsByProvider[providerID] != nil { return }
        guard let provider = registry.provider(for: providerID),
              let key = keyManager.getKey(for: providerID),
              !key.isEmpty else {
            modelsByProvider[providerID] = []
            return
        }

        loadingProviders.insert(providerID)
        defer { loadingProviders.remove(providerID) }

        do {
            let models = try await provider.fetchModels(apiKey: key)
            modelsByProvider[providerID] = models
        } catch {
            modelsByProvider[providerID] = []
        }
    }
}
