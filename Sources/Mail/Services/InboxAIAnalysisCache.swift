import Foundation

actor InboxAIAnalysisCache {
    static let shared = InboxAIAnalysisCache()
    private let warmInterval: TimeInterval = 300

    private var lastWarmDate: Date?
    private var lastWarmProviderID: String?

    func warmCacheIfNeeded(force: Bool) async {
        let now = Date()
        if !force, let lastWarmDate, now.timeIntervalSince(lastWarmDate) < warmInterval {
            return
        }

        let providerID = await MainActor.run { AIChatSettingsManager.shared.settings.selectedProviderID }
        if !force, providerID == lastWarmProviderID {
            lastWarmDate = now
            return
        }

        await MainActor.run {
            let featureCheck = AIFeatureCheck.shared
            featureCheck.refresh()
            _ = AIProviderRegistry.shared.provider(for: providerID) ?? AIProviderRegistry.shared.defaultProvider()
            _ = AIService.shared
        }

        lastWarmProviderID = providerID
        lastWarmDate = now
    }
}
