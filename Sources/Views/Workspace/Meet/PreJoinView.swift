import SwiftUI

struct PreJoinView: View {
    @ObservedObject var manager: MeetingStateManager
    let onJoin: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 24) {
                    cameraPreview

                    VStack(spacing: 16) {
                        TextField("Display Name", text: $manager.localParticipantDisplayName)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 12) {
                            toggleButton(icon: manager.isMicrophoneMuted ? "mic.slash.fill" : "mic.fill", isOn: !manager.isMicrophoneMuted) { manager.toggleMute() }
                            toggleButton(icon: manager.isCameraEnabled ? "video.fill" : "video.slash.fill", isOn: manager.isCameraEnabled) { manager.toggleCamera() }
                        }
                    }

                    Spacer()

                    joinButton
                }
                .padding(24)
            }
            .navigationTitle("Ready to join?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var cameraPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 240)

            if manager.isCameraEnabled {
                Image(systemName: "person.fill").font(.system(size: 80)).foregroundStyle(.secondary)
            } else {
                Text("Camera is Off").font(.headline).foregroundStyle(.secondary)
            }
        }
    }

    private func toggleButton(icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isOn ? Color.blue.opacity(0.1) : Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(isOn ? .blue : .red)
        }
    }

    private var joinButton: some View {
        Button(action: onJoin) {
            Text("Join Meeting")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(manager.localParticipantDisplayName.isEmpty ? Color.gray : Color.blue, in: Capsule())
                .foregroundStyle(.white)
        }
        .disabled(manager.localParticipantDisplayName.isEmpty)
    }
}
