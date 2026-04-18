import SwiftUI
import Daily

struct MeetingControlsView: View {
    let isMuted: Bool
    let isCameraEnabled: Bool
    let isScreenSharing: Bool
    let onToggleMute: () -> Void
    let onToggleCamera: () -> Void
    let onToggleScreenShare: () -> Void
    let onLeaveMeeting: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onToggleMute) {
                    Label(isMuted ? "Unmute" : "Mute", systemImage: isMuted ? "mic.slash.fill" : "mic.fill")
                }
                    .buttonStyle(.bordered)

                Button(action: onToggleCamera) {
                    Label(
                        isCameraEnabled ? "Disable Camera" : "Enable Camera",
                        systemImage: isCameraEnabled ? "video.slash.fill" : "video.fill"
                    )
                }
                    .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button(action: onToggleScreenShare) {
                    Label(
                        isScreenSharing ? "Stop Share" : "Share Screen",
                        systemImage: isScreenSharing ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle"
                    )
                }
                    .buttonStyle(.bordered)

                Button(role: .destructive, action: onLeaveMeeting) {
                    Label("Leave", systemImage: "phone.down.fill")
                }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
