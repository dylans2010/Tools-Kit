import SwiftUI

struct MusicSettingsView: View {
    @StateObject private var modeManager = MusicModeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Turn ToolsKit Into Music", isOn: $modeManager.isMusicModeEnabled)
                } footer: {
                    Text("When enabled, the app displays a dedicated music player. Switching modes does not interrupt playback.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
