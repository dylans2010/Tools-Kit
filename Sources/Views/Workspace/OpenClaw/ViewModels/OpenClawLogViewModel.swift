import SwiftUI
import Observation

@MainActor @Observable
final class OpenClawLogViewModel {
    var logs: [String] {
        OpenClawDiagnosticsManager.shared.logs
    }

    init() {
    }

    func clear() {
        OpenClawDiagnosticsManager.shared.logs.removeAll()
    }
}
