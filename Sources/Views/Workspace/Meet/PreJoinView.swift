import SwiftUI

struct PreJoinView: View {
    @ObservedObject var manager: MeetingStateManager
    let onJoin: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                VStack(spacing: 6) {
                    Image(systemName: manager.isCameraEnabled ? "video.fill" : "video.slash.fill")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Camera Preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 150)

            TextField("Enter Your Name", text: $manager.displayNameInput)
                .textFieldStyle(.roundedBorder)

            Toggle("Microphone", isOn: Binding(get: { !manager.isMicrophoneMuted }, set: { _ in manager.toggleMute() }))
            Toggle("Camera", isOn: Binding(get: { manager.isCameraEnabled }, set: { _ in manager.toggleCamera() }))

            Picker("Microphone Device", selection: Binding(get: { manager.settings.selectedAudioDevice }, set: { manager.setAudioDevice($0) })) {
                ForEach(manager.availableAudioDevices, id: \.self) { device in
                    Text(device).tag(device)
                }
            }

            Picker("Camera Device", selection: Binding(get: { manager.settings.selectedVideoDevice }, set: { manager.setVideoDevice($0) })) {
                ForEach(manager.availableVideoDevices, id: \.self) { device in
                    Text(device).tag(device)
                }
            }

            Button(action: onJoin) {
                if manager.isJoining {
                    ProgressView()
                } else {
                    Label("Join", systemImage: "arrow.right.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(manager.displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.isJoining || manager.isBusy)
        }
    }
}
