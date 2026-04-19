import SwiftUI

struct VideoSettingsView: View {
    @ObservedObject var manager: MeetingStateManager

    var body: some View {
        Section("Video") {
            Picker("Camera", selection: $manager.settings.selectedVideoDevice) {
                ForEach(manager.availableVideoDevices, id: \.self) { device in
                    Text(device).tag(device)
                }
            }

            Picker("Quality", selection: $manager.settings.qualitySetting) {
                ForEach(MeetingQualitySetting.allCases) { quality in
                    Text(quality.rawValue).tag(quality)
                }
            }
        }
    }
}
