import Foundation
import Network
import OSLog

public actor TLANBonjourBrowser {
    public static let shared = TLANBonjourBrowser()
    private var browser: NWBrowser?
    private var resultsContinuation: AsyncStream<[NWBrowser.Result]>.Continuation?

    private init() {}

    public func startBrowsing() -> AsyncStream<[NWBrowser.Result]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [NWBrowser.Result].self)
        self.resultsContinuation = continuation

        let p = NWParameters()
        p.includePeerToPeer = true

        let b = NWBrowser(for: .bonjour(type: TLANConstants.serviceType, domain: "local."), using: p)
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

actor OpenClawBonjourDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private let browser = NetServiceBrowser()
    private var pendingContinuation: CheckedContinuation<NetService, Error>?
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "bonjour")

    func discover(serviceType: String) async throws -> NetService {
        return try await withCheckedThrowingContinuation { continuation in
            self.pendingContinuation = continuation
            browser.delegate = self
            browser.searchForServices(ofType: serviceType, inDomain: "local.")
            logger.info("Started Bonjour search for \(serviceType)")
        }
    }

    nonisolated func netServiceBrowser(_ browser: NetServiceBrowser,
                                       didFind service: NetService,
                                       moreComing: Bool) {
        logger.info("Found service: \(service.name)")
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }

    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        logger.info("Resolved service at \(sender.hostName ?? "unknown")")
        Task { await self.complete(with: .success(sender)) }
    }

    nonisolated func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        let code = errorDict["NSNetServicesErrorCode"]?.intValue ?? -1
        let error = NSError(domain: "OpenClawBonjour", code: code)
        Task { await self.complete(with: .failure(error)) }
    }

    private func complete(with result: Result<NetService, Error>) {
        switch result {
        case .success(let service): pendingContinuation?.resume(returning: service)
        case .failure(let error): pendingContinuation?.resume(throwing: error)
        }
        pendingContinuation = nil
        browser.stop()
    }
}
