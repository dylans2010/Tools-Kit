import SwiftUI

struct MeetingSettingsView: View {
    @Binding var settings: MeetingSettingsState

    let availableAudioDevices: [String]
    let availableVideoDevices: [String]

    var body: some View {
        Form {
            Section("Devices") {
                if availableAudioDevices.isEmpty {
                    Text("No audio devices reported by runtime.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Audio", selection: $settings.selectedAudioDevice) {
                        ForEach(availableAudioDevices, id: \.self) { Text($0) }
                    }
                }
                if availableVideoDevices.isEmpty {
                    Text("No video devices reported by runtime.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Video", selection: $settings.selectedVideoDevice) {
                        ForEach(availableVideoDevices, id: \.self) { Text($0) }
                    }
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
