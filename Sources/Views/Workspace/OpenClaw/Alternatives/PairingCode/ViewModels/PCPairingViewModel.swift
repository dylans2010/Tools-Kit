import Foundation
import Observation
import OSLog

@Observable @MainActor
public final class PCPairingViewModel {
    public var state: PCPairingState = .idle
    private let engine = PCPairingEngine()
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "pc-viewmodel")

    public init() {}

    public func submitCode(_ code: String, host: String, port: Int) async {
        self.state = .validating
        do {
            try await engine.submitCode(code, host: host, port: port)
            self.state = .paired
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }
}
