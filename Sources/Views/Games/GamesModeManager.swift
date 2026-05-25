import Foundation
import Combine

final class GamesModeManager: ObservableObject {
    static let shared = GamesModeManager()

    private let key = "gamesModeEnabled"

    @Published var isGamesModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGamesModeEnabled, forKey: key)
        }
    }

    private init() {
        self.isGamesModeEnabled = UserDefaults.standard.bool(forKey: key)
    }
}
