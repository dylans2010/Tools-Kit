import SwiftUI

struct MeetingSettingsView: View {
    @Binding var settings: MeetingSettingsState

    private let audioDevices = ["Default Microphone", "Built-in Microphone", "Bluetooth Microphone"]
    private let videoDevices = ["Default Camera", "Front Camera", "Back Camera"]

    var body: some View {
        Form {
            Section("Devices") {
                Picker("Audio", selection: $settings.selectedAudioDevice) {
                    ForEach(audioDevices, id: \.self) { Text($0) }
                }
                Picker("Video", selection: $settings.selectedVideoDevice) {
                    ForEach(videoDevices, id: \.self) { Text($0) }
                }
            }

            Section("Preferences") {
                Picker("Layout", selection: $settings.layoutPreference) {
                    ForEach(MeetingLayoutPreference.allCases) { preference in
                        Text(preference.rawValue).tag(preference)
                    }
                }
                Picker("Quality", selection: $settings.qualitySetting) {
                    ForEach(MeetingQualitySetting.allCases) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
            }
        }
        .navigationTitle("Meeting Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
