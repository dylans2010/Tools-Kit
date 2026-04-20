import SwiftUI

struct MeetingSettingsView: View {
    @Binding var settings: MeetingSettingsState

    let availableAudioDevices: [String]
    let availableVideoDevices: [String]

    var body: some View {
        Form {
            Section {
                if availableAudioDevices.isEmpty {
                    Text("No audio devices reported by runtime.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Audio Device", selection: $settings.selectedAudioDevice) {
                        ForEach(availableAudioDevices, id: \.self) { Text($0) }
                    }
                }
                if availableVideoDevices.isEmpty {
                    Text("No video devices reported by runtime.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Video Device", selection: $settings.selectedVideoDevice) {
                        ForEach(availableVideoDevices, id: \.self) { Text($0) }
                    }
                }
            } header: {
                Label("Devices", systemImage: "camera.metering.center.weighted")
            } footer: {
                Text("Pick active microphone and camera sources for this meeting.")
            }

            Section {
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
            } header: {
                Label("Preferences", systemImage: "slider.horizontal.3")
            } footer: {
                Text("Adjust layout and quality to balance clarity and performance.")
            }
        }
        .navigationTitle("Meeting Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
