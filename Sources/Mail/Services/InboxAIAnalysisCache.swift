import Foundation

actor InboxAIAnalysisCache {
    static let shared = InboxAIAnalysisCache()
    private let cacheWarmupInterval: TimeInterval = 5 * 60

    private var lastWarmDate: Date?
    private var lastWarmProviderID: String?

    func warmCacheIfNeeded(force: Bool) async {
        let now = Date()
        if !force, let lastWarmDate, now.timeIntervalSince(lastWarmDate) < cacheWarmupInterval {
            return
        }

        let providerID = await MainActor.run { AIChatSettingsManager.shared.settings.selectedProviderID }
        if !force, providerID == lastWarmProviderID {
            lastWarmDate = now
            return
        }

        await MainActor.run {
            // Touch AI-related singletons once so the first user-triggered AI action has less setup latency.
            let featureCheck = AIFeatureCheck.shared
            featureCheck.refresh()
            _ = AIProviderRegistry.shared.provider(for: providerID) ?? AIProviderRegistry.shared.defaultProvider()
            _ = AIService.shared
        }

        lastWarmProviderID = providerID
        lastWarmDate = now
    }
}
