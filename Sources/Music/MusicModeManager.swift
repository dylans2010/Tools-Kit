import Foundation
import Combine

final class MusicModeManager: ObservableObject {
    static let shared = MusicModeManager()

    private let key = "app.musicModeEnabled"

    @Published var isMusicModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicModeEnabled, forKey: key)
            if isMusicModeEnabled {
                MusicPlayerManager.shared.setupAudioSession()
            }
        }
    }

    private init() {
        isMusicModeEnabled = UserDefaults.standard.bool(forKey: "app.musicModeEnabled")
    }
}
