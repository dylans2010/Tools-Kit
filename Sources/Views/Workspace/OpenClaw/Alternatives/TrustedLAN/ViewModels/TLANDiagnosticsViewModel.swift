import Foundation
import Observation
@Observable @MainActor public final class TLANDiagnosticsViewModel {
    public var logs: [String] = []; public init() {}
    public func exportLogs() {}
}
