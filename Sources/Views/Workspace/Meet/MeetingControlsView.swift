import SwiftUI

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
                Button(isMuted ? "Unmute" : "Mute", action: onToggleMute)
                    .buttonStyle(.bordered)
                Button(isCameraEnabled ? "Disable Camera" : "Enable Camera", action: onToggleCamera)
                    .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button(isScreenSharing ? "Stop Share" : "Share Screen", action: onToggleScreenShare)
                    .buttonStyle(.bordered)

                Button("Leave", role: .destructive, action: onLeaveMeeting)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
