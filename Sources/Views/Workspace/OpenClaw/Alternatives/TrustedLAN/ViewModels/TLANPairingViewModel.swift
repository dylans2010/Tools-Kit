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
            let stream = try await pairingEngine.startPairing(endpoint: result.endpoint)
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
