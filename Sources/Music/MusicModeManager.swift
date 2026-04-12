import Foundation
import Combine

final class MusicModeManager: ObservableObject {
    static let shared = MusicModeManager()

    private let key = "app.musicModeEnabled"
    private let forcedByBundle: Bool

    @Published private(set) var isLocked: Bool
    @Published var isMusicModeEnabled: Bool {
        didSet {
            if forcedByBundle && isMusicModeEnabled == false {
                isMusicModeEnabled = true
                return
            }
            UserDefaults.standard.set(isMusicModeEnabled, forKey: key)
            if isMusicModeEnabled {
                MusicPlayerManager.shared.setupAudioSession()
            }
        }
    }

    private init() {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        forcedByBundle = bundleID.range(of: "music", options: .caseInsensitive) != nil
        isLocked = forcedByBundle
        let stored = UserDefaults.standard.bool(forKey: key)
        isMusicModeEnabled = forcedByBundle ? true : stored
        if isMusicModeEnabled {
            MusicPlayerManager.shared.setupAudioSession()
        }
    }
}
