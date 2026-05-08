import SwiftUI

struct MeetingSettingsView: View {
    @ObservedObject var manager: MeetingStateManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                Form {
                    Section {
                        Picker("Microphone", selection: $manager.settings.selectedAudioDevice) {
                            Text("System Default").tag("default")
                        }
                        Picker("Camera", selection: $manager.settings.selectedVideoDevice) {
                            Text("FaceTime HD Camera").tag("facetime")
                        }
                    } header: {
                        Text("Devices")
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section {
                        Picker("Layout", selection: $manager.settings.layoutPreference) {
                            ForEach(MeetingLayoutPreference.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Quality", selection: $manager.settings.qualitySetting) {
                            ForEach(MeetingQualitySetting.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } header: {
                        Text("Preferences")
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section {
                        Toggle("Noise Cancellation", isOn: $manager.isNoiseCancellationEnabled)
                        Toggle("Live Captions", isOn: $manager.isCaptionsEnabled)
                    } header: {
                        Text("Intelligence")
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
