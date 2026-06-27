import Foundation
import Network
import Observation
import OSLog

@Observable @MainActor public final class TLANDiagnosticsViewModel {
    public var logs: [String] = []
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "tlan-diagnostics")

    public init() {}

    public func exportLogs() {
        let logString = logs.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("OpenClaw-TLAN-Diagnostics.log")
        try? logString.write(to: tempURL, atomically: true, encoding: .utf8)
        logger.info("Diagnostics exported to \(tempURL.path)")
    }

    public func resetAndUnpair() async {
        await TLANTokenService.shared.deleteToken(for: "all") // Simplification
        logger.info("TLAN Reset & Unpaired")
    }
}
