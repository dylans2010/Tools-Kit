import Foundation
import Observation
import OSLog

@Observable @MainActor
public final class MTPairingViewModel {
    public var state: MTPairingState = .idle
    public var token: String = ""
    private let engine = MTPairingEngine()
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "mt-viewmodel")

    public init() {}

    public func pair(token: String, host: String, port: Int) async {
        self.state = .submitting
        do {
            try await engine.validateToken(token, host: host, port: port)
            self.state = .paired
        } catch {
            self.state = .networkError(error.localizedDescription)
        }
    }
}
