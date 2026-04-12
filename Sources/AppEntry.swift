import SwiftUI
import AVFoundation

@main
struct ToolsKitApp: App {
    init() {
        // Configure AVAudioSession early so background audio is ready before first frame
        _ = MusicPlayerManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}