import Foundation
import Network

public actor LABonjourBrowser {
    public static let shared = LABonjourBrowser()
    private var browser: NWBrowser?
    private var resultsContinuation: AsyncStream<[NWBrowser.Result]>.Continuation?

    private init() {}

    public func startBrowsing() -> AsyncStream<[NWBrowser.Result]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [NWBrowser.Result].self)
        self.resultsContinuation = continuation

        let p = NWParameters()
        p.includePeerToPeer = true

        // Using same service type as Trusted LAN for consistency or specified in CIM
        let b = NWBrowser(for: .bonjour(type: "_openclaw._tcp", domain: "local."), using: p)
        self.browser = b

        b.browseResultsChangedHandler = { [weak self] r, c in
            Task {
                await self?.resultsContinuation?.yield(Array(r))
            }
        }

        b.start(queue: .global(qos: .userInitiated))
        return stream
    }

    public func stopBrowsing() {
        browser?.cancel()
        browser = nil
        resultsContinuation?.finish()
    }
}

public struct PairingRequest: Codable {
    let deviceName: String
    let requestID: String
    let timestamp: TimeInterval

    public init(deviceName: String, requestID: String = UUID().uuidString, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.deviceName = deviceName
        self.requestID = requestID
        self.timestamp = timestamp
    }
}
