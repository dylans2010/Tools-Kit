import Foundation
import Network
import OSLog

public actor LABonjourBrowser {
    public static let shared = LABonjourBrowser()
    private var browser: NWBrowser?
    private var resultsContinuation: AsyncStream<[NWBrowser.Result]>.Continuation?
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "la-bonjour")

    private init() {}

    public func startBrowsing() -> AsyncStream<[NWBrowser.Result]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [NWBrowser.Result].self)
        self.resultsContinuation = continuation

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: .bonjour(type: "_openclaw._tcp", domain: nil), using: parameters)
        self.browser = browser

        browser.browseResultsChangedHandler = { [weak self] results, changes in
            Task {
                await self?.resultsContinuation?.yield(Array(results))
            }
        }

        browser.start(queue: .global(qos: .userInitiated))
        return stream
    }

    public func stopBrowsing() {
        browser?.cancel()
        browser = nil
        resultsContinuation?.finish()
    }
}
