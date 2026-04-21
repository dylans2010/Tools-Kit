import Foundation

actor InboxAIAnalysisCache {
    static let shared = InboxAIAnalysisCache()

    private var lastWarmDate: Date?

    func warmCacheIfNeeded(force: Bool) async {
        let now = Date()
        if !force, let lastWarmDate, now.timeIntervalSince(lastWarmDate) < 300 {
            return
        }

        lastWarmDate = now
        await MainActor.run {
            _ = AIService.shared
        }
    }
}
