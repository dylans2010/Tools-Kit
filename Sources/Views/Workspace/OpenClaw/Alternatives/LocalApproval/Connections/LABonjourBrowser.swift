import Foundation
import Network

public actor LABonjourBrowser {
    public static let shared = LABonjourBrowser()
    private var browser: NWBrowser?

    private init() {}

    public func startBrowsing() {
        browser = NWBrowser(for: .bonjour(type: "_openclaw._tcp", domain: nil), using: .tcp)
        browser?.start(queue: .global())
    }

    public func stopBrowsing() {
        browser?.cancel()
        browser = nil
    }
}
