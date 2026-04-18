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

    private var muteControl: (title: String, icon: String) {
        isMuted ? ("Unmute", "mic.slash.fill") : ("Mute", "mic.fill")
    }

    private var cameraControl: (title: String, icon: String) {
        isCameraEnabled ? ("Disable Camera", "video.slash.fill") : ("Enable Camera", "video.fill")
    }

    private var screenShareControl: (title: String, icon: String) {
        isScreenSharing ? ("Stop Share", "rectangle.on.rectangle.slash") : ("Share Screen", "rectangle.on.rectangle")
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onToggleMute) {
                    Label(muteControl.title, systemImage: muteControl.icon)
                }
                    .buttonStyle(.bordered)

                Button(action: onToggleCamera) {
                    Label(cameraControl.title, systemImage: cameraControl.icon)
                }
                    .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button(action: onToggleScreenShare) {
                    Label(screenShareControl.title, systemImage: screenShareControl.icon)
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
