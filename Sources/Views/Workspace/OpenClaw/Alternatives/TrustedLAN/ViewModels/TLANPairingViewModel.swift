import Foundation
import Network
import Observation
import OSLog

@Observable @MainActor
public final class TLANPairingViewModel {
    public var state: TLANPairingState = .idle
    public var lastError: String?
    private let pairingEngine = TLANPairingEngine()
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "tlan-viewmodel")

    public init() {}

    public func pair(with result: NWBrowser.Result) async {
        state = .connecting
        do {
            let endpoint = result.endpoint
            guard case let .hostPort(host, port) = endpoint else {
                throw TLANError.connectionFailed("Invalid endpoint")
            }
            // Use debugDescription for host, or if it's an IP/hostname it can be tricky.
            // A simple way to get string:
            let hostStr = switch host {
            case .name(let name, _): name
            case .ipv4(let ipv4): "\(ipv4)"
            case .ipv6(let ipv6): "[\(ipv6)]"
            @unknown default: "\(host)"
            }
            guard let url = URL(string: "ws://\(hostStr):\(port.rawValue)") else {
                throw TLANError.connectionFailed("Invalid URL")
            }
            let stream = try await pairingEngine.startPairing(url: url)
            for await newState in stream {
                self.state = newState
            }
        } catch {
            self.state = .failed(error.localizedDescription)
            self.lastError = error.localizedDescription
            logger.error("Pairing failed: \(error.localizedDescription)")
        }
    }
}
