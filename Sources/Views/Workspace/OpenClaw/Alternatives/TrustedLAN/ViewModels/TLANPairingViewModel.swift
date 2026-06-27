import Foundation
import Observation
import OSLog
@Observable @MainActor public final class TLANPairingViewModel {
    public var state: TLANPairingState = .idle; public var lastError: String?
    private let pairingEngine = TLANPairingEngine()
    public init() {}
    public func pair(with result: Network.NWBrowser.Result) async { state = .connecting }
}
