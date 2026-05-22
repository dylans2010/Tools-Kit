import Foundation
import Combine

final class DiagnosticsModeManager: ObservableObject {
    static let shared = DiagnosticsModeManager()

    private let key = "diagnosticsModeEnabled"

    @Published var isDiagnosticsModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDiagnosticsModeEnabled, forKey: key)
        }
    }

    private init() {
        isDiagnosticsModeEnabled = UserDefaults.standard.bool(forKey: key)
    }
}
