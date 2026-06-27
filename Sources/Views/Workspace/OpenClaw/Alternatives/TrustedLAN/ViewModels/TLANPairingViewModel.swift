import Foundation
import Observation
import Network

@Observable @MainActor public final class TLANPairingViewModel {
    public var state: PairingState = .idle
    public var lastError: String?
    private let engine = TLANPairingEngine()

    public init() {}

    public func startPairing(endpoint: NWEndpoint) async {
        guard case .hostPort(let host, let port) = endpoint else { return }
        let urlString = "ws://\(host.debugDescription):\(port.rawValue)"
        guard let url = URL(string: urlString) else { return }

        do {
            let stream = try await engine.startPairing(url: url)
            for await newState in stream {
                self.state = newState
            }
        } catch {
            self.state = .failed(error.localizedDescription)
            self.lastError = error.localizedDescription
        }
    }
}
