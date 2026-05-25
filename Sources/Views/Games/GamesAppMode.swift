import Foundation
import Combine

final class GamesAppMode: ObservableObject {
    static let shared = GamesAppMode()

    private let key = "gamesModeEnabled"

    @Published var isGamesModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGamesModeEnabled, forKey: key)
        }
    }

    private init() {
        isGamesModeEnabled = UserDefaults.standard.bool(forKey: key)
    }
}
