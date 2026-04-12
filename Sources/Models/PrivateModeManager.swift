import Foundation
import Combine

final class PrivateModeManager: ObservableObject {
    static let shared = PrivateModeManager()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "privateModeEnabled")
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "privateModeEnabled")
    }
}
