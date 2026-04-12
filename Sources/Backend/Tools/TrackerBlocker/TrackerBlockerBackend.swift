import Foundation

@MainActor
final class TrackerBlockerBackend: ObservableObject {
    @Published var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "trackerBlockerEnabled")
            applyToNetworkClient()
        }
    }
    @Published var blockedCount: Int = 0
    @Published var customBlocklist: [String] = []
    @Published var recentlyBlocked: [String] = []

    static let defaultTrackers: Set<String> = [
        "doubleclick.net", "googlesyndication.com", "googletagmanager.com",
        "facebook.com", "connect.facebook.net", "analytics.google.com",
        "hotjar.com", "mixpanel.com", "amplitude.com", "segment.com",
        "intercom.io", "intercomcdn.com", "ads.twitter.com",
        "scorecardresearch.com", "quantserve.com", "outbrain.com",
        "taboola.com", "criteo.com", "rubiconproject.com",
        "pubmatic.com", "appnexus.com", "openx.net",
        "amazon-adsystem.com", "adnxs.com", "moatads.com"
    ]

    private var middleware: TrackerBlockingMiddleware?

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: "trackerBlockerEnabled")
        loadCustomBlocklist()
        blockedCount = UserDefaults.standard.integer(forKey: "trackerBlockedCount")
    }

    var allTrackers: Set<String> {
        Self.defaultTrackers.union(Set(customBlocklist))
    }

    func addCustomDomain(_ domain: String) {
        let trimmed = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !customBlocklist.contains(trimmed) else { return }
        customBlocklist.insert(trimmed, at: 0)
        saveCustomBlocklist()
        if isEnabled { applyToNetworkClient() }
    }

    func removeCustomDomain(_ domain: String) {
        customBlocklist.removeAll { $0 == domain }
        saveCustomBlocklist()
        if isEnabled { applyToNetworkClient() }
    }

    func recordBlock(domain: String) {
        blockedCount += 1
        UserDefaults.standard.set(blockedCount, forKey: "trackerBlockedCount")
        if !recentlyBlocked.contains(domain) {
            recentlyBlocked.insert(domain, at: 0)
            if recentlyBlocked.count > 20 { recentlyBlocked.removeLast() }
        }
    }

    func reset() {
        blockedCount = 0
        recentlyBlocked = []
        UserDefaults.standard.set(0, forKey: "trackerBlockedCount")
    }

    private func applyToNetworkClient() {
        NetworkClient.shared.removeAllMiddlewares()
        if isEnabled {
            let m = TrackerBlockingMiddleware(blocklist: allTrackers)
            middleware = m
            NetworkClient.shared.addMiddleware(m)
        }
        NetworkClient.shared.addMiddleware(LoggingMiddleware())
    }

    private func saveCustomBlocklist() {
        UserDefaults.standard.set(customBlocklist, forKey: "trackerCustomBlocklist")
    }

    private func loadCustomBlocklist() {
        customBlocklist = UserDefaults.standard.stringArray(forKey: "trackerCustomBlocklist") ?? []
    }
}
