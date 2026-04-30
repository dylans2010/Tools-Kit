import SwiftUI

struct MeetingSettingsView: View {
    @ObservedObject var manager: MeetingStateManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                Form {
                    Section("Devices") {
                        Picker("Microphone", selection: $manager.settings.selectedAudioDevice) {
                            Text("System Default").tag("default")
                        }
                        Picker("Camera", selection: $manager.settings.selectedVideoDevice) {
                            Text("FaceTime HD Camera").tag("facetime")
                        }
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section("Preferences") {
                        Picker("Layout", selection: $manager.settings.layoutPreference) {
                            ForEach(MeetingLayoutPreference.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Quality", selection: $manager.settings.qualitySetting) {
                            ForEach(MeetingQualitySetting.allCases) { Text($0.rawValue).tag($0) }
                        }
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section("Intelligence") {
                        Toggle("Noise Cancellation", isOn: $manager.isNoiseCancellationEnabled)
                        Toggle("Live Captions", isOn: $manager.isCaptionsEnabled)
                    }
                    .listRowBackground(Color.workspaceSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
