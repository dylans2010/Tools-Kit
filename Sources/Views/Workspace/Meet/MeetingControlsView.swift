import SwiftUI

struct MeetingControlsView: View {
    let isMuted: Bool
    let isCameraEnabled: Bool
    let isScreenSharing: Bool
    let onToggleMute: () -> Void
    let onToggleCamera: () -> Void
    let onToggleScreenShare: () -> Void
    let onLeaveMeeting: () -> Void
    var onOpenChat: (() -> Void)?
    var onOpenParticipants: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    var body: some View {
        HStack(spacing: 20) {
            controlButton(icon: isMuted ? "mic.slash.fill" : "mic.fill", color: isMuted ? .red : .white.opacity(0.1), action: onToggleMute)
            controlButton(icon: isCameraEnabled ? "video.fill" : "video.slash.fill", color: isCameraEnabled ? .white.opacity(0.1) : .red, action: onToggleCamera)
            controlButton(icon: "screenview.fill", color: isScreenSharing ? .blue : .white.opacity(0.1), action: onToggleScreenShare)

            Spacer()

            HStack(spacing: 16) {
                actionButton(icon: "message.fill", action: onOpenChat)
                actionButton(icon: "person.2.fill", action: onOpenParticipants)
                actionButton(icon: "gearshape.fill", action: onOpenSettings)
            }

            Spacer()

            Button(action: onLeaveMeeting) {
                Image(systemName: "phone.down.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.red, in: Circle())
            }
        }
        .padding(.horizontal)
    }

    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 48, height: 48)
                .background(color, in: Circle())
        }
    }

    private func actionButton(icon: String, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
        }
    }
}
