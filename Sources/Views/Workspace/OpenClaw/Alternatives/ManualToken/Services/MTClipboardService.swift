import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Observation

@Observable
public final class MTClipboardService {
    public static let shared = MTClipboardService()
    public private(set) var currentClipboardContent: String?

    private init() {}

    public func monitorClipboard() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: UIPasteboard.changedNotification,
                object: nil,
                queue: .main
            ) { _ in
                let content = UIPasteboard.general.string
                continuation.yield(content)
            }
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
            continuation.yield(UIPasteboard.general.string)
        }
    }

    public func clearClipboard() {
        UIPasteboard.general.string = ""
    }
}
