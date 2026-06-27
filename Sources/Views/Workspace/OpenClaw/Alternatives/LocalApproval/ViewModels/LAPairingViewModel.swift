import Foundation
import Network
import Observation
import OSLog

@Observable @MainActor
public final class LAPairingViewModel {
    public var state: LAPairingState = .idle
    public var discoveredResults: [NWBrowser.Result] = []
    private let engine = LAPairingEngine()
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "la-viewmodel")

    public init() {}

    public func startDiscovery() async {
        let stream = await LABonjourBrowser.shared.startBrowsing()
        for await results in stream {
            self.discoveredResults = results
        }
    }

    public func startPairing(with result: NWBrowser.Result) async {
        state = .connecting

        do {
            // Convert endpoint to URL-like structure for the engine
            // Or better, update engine to accept endpoint.
            // For now, let's assume engine can handle basic WebSocket URL from endpoint.
            let host = result.endpoint.debugDescription.split(separator: ":").first.map(String.init) ?? "MacBook-Pro.local"
            guard let url = URL(string: "ws://\(host):9876") else { return }

            let stream = try await engine.requestApproval(url: url)
            for await newState in stream {
                self.state = newState
            }
        } catch {
            self.state = .exchangeFailed(error.localizedDescription)
        }
    }

    public func stopDiscovery() async {
        await LABonjourBrowser.shared.stopBrowsing()
    }
}
