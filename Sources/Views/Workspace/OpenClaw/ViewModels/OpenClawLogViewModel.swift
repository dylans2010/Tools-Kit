import SwiftUI

@MainActor
final class OpenClawLogViewModel: ObservableObject {
    @Published var logs: [String] = []

    init() {
        // Observe OpenClawDiagnosticsManager logs
    }

    func clear() {
        OpenClawDiagnosticsManager.shared.logs.removeAll()
        logs = []
    }
}
