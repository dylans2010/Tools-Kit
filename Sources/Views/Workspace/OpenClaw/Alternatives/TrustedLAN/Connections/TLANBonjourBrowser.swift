import Foundation
import Network
public actor TLANBonjourBrowser {
    public static let shared = TLANBonjourBrowser(); private var browser: NWBrowser?; private var resultsContinuation: AsyncStream<[NWBrowser.Result]>.Continuation?
    private init() {}
    public func startBrowsing() -> AsyncStream<[NWBrowser.Result]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [NWBrowser.Result].self); self.resultsContinuation = continuation
        let p = NWParameters(); p.includePeerToPeer = true
        let b = NWBrowser(for: .bonjour(type: TLANConstants.serviceType, domain: nil), using: p); self.browser = b
        b.browseResultsChangedHandler = { [weak self] r, c in Task { await self?.resultsContinuation?.yield(Array(r)) } }
        b.start(queue: .global(qos: .userInitiated)); return stream
    }
    public func stopBrowsing() { browser?.cancel(); browser = nil; resultsContinuation?.finish() }
}
