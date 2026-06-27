import Foundation
import Observation
@Observable @MainActor public final class LADiagnosticsViewModel {
    public var approvalLogs: [String] = []
    public init() {}
}
