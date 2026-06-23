import Foundation
import UIKit
import os

@MainActor
final class AppDeepLinkRouter {
    static let shared = AppDeepLinkRouter()
    private init() {}

    func handle(_ url: URL) {
        SDKLogStore.shared.log("LM Link: [ROUTER] Received raw URL: \(url.absoluteString)", source: "AppDeepLinkRouter", level: .info)
        LMLinkLogger.deeplink.info("Router received deep link: \(url.scheme ?? "nil", privacy: .public)://\(url.host ?? "nil", privacy: .public)")

        guard url.scheme == "toolskit" else {
            LMLinkLogger.deeplink.info("Ignoring URL with unrecognized scheme: \(url.scheme ?? "nil", privacy: .public)")
            return
        }

        guard url.host == "lm-callback" else {
            SDKLogStore.shared.log("LM Link: [ROUTER] Ignoring toolskit URL with unrecognized host: \(url.host ?? "nil")", source: "AppDeepLinkRouter", level: .info)
            LMLinkLogger.deeplink.info("Ignoring toolskit URL with unrecognized host: \(url.host ?? "nil", privacy: .public)")
            return
        }

        SDKLogStore.shared.log("LM Link: [ROUTER] Routing verified LM Link callback. App state: \(UIApplication.shared.applicationState.rawValue)", source: "AppDeepLinkRouter", level: .info)
        LMLinkLogger.deeplink.info("Routing verified LM Link callback. App state: \(UIApplication.shared.applicationState.rawValue, privacy: .public)")

        Task {
            await LMLinkAuthManager.shared.handleCallback(url: url)
        }
    }
}
