import Foundation
import UIKit
import os

@MainActor
final class AppDeepLinkRouter {
    static let shared = AppDeepLinkRouter()
    private init() {}

    func handle(_ url: URL) {
        LMLinkLogger.deeplink.info("Router received URL scheme: \(url.scheme ?? "nil", privacy: .public)")
        LMLinkLogger.deeplink.info("App state at callback: \(UIApplication.shared.applicationState.rawValue, privacy: .public)")

        switch url.scheme {
        case "toolskit":
            guard url.host == "lm-callback" else {
                LMLinkLogger.deeplink.info("Ignoring toolskit URL with unrecognised host: \(url.host ?? "nil", privacy: .public)")
                return
            }
            Task {
                await LMLinkAuthManager.shared.handleCallback(url: url)
            }
        default:
            LMLinkLogger.deeplink.info("URL not claimed by LM Link router — ignoring")
        }
    }
}
