import SwiftUI

struct AISpeechTool: Tool {
    let name = "AI Speech"
    let icon = "waveform.circle.fill"
    let category: ToolCategory = .ai
    let complexity: ToolComplexity = .advanced
    let description = "Real-time AI voice conversation with high-quality TTS."
    let requiresAPI = true

    var view: AnyView {
        AnyView(SpeechToolRootView())
    }
}

struct SpeechToolRootView: View {
    @State private var hasCompletedSetup = UserDefaults.standard.bool(forKey: "speech_setup_completed")

    var body: some View {
        if hasCompletedSetup {
            SpeechMainView()
        } else {
            SpeechSetupView()
                .onDisappear {
                    hasCompletedSetup = UserDefaults.standard.bool(forKey: "speech_setup_completed")
                }
        }
    }
}
