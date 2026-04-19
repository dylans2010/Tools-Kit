import SwiftUI

struct AudioSettingsView: View {
    @ObservedObject var manager: MeetingStateManager

    var body: some View {
        Section("Audio") {
            Picker("Microphone", selection: $manager.settings.selectedAudioDevice) {
                ForEach(manager.availableAudioDevices, id: \.self) { device in
                    Text(device).tag(device)
                }
            }

            VStack(alignment: .leading) {
                Text("Volume")
                Slider(value: $manager.settings.outputVolume, in: 0...1)
            }
        }
    }
}
