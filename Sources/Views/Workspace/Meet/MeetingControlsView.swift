import SwiftUI

struct MeetingControlsView: View {
    let isMuted: Bool
    let isCameraEnabled: Bool
    let isScreenSharing: Bool
    let onToggleMute: () -> Void
    let onToggleCamera: () -> Void
    let onToggleScreenShare: () -> Void
    let onLeaveMeeting: () -> Void
    var onOpenChat: (() -> Void)? = nil
    var onOpenParticipants: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil
    var onOpenAdmin: (() -> Void)? = nil
    var onOpenNotes: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                controlButton(isMuted ? "Unmute" : "Mute", icon: isMuted ? "mic.slash.fill" : "mic.fill", action: onToggleMute)
                controlButton(isCameraEnabled ? "Camera Off" : "Camera On", icon: isCameraEnabled ? "video.slash.fill" : "video.fill", action: onToggleCamera)
                controlButton(isScreenSharing ? "Stop Share" : "Share", icon: isScreenSharing ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle", action: onToggleScreenShare)

                if let onOpenChat {
                    controlButton("Chat", icon: "message.fill", action: onOpenChat)
                }
                if let onOpenParticipants {
                    controlButton("People", icon: "person.3.fill", action: onOpenParticipants)
                }
                if let onOpenSettings {
                    controlButton("Settings", icon: "slider.horizontal.3", action: onOpenSettings)
                }
                if let onOpenAdmin {
                    controlButton("Admin", icon: "person.badge.shield.checkmark.fill", action: onOpenAdmin)
                }
                if let onOpenNotes {
                    controlButton("Notes", icon: "note.text", action: onOpenNotes)
                }

                Button(role: .destructive, action: onLeaveMeeting) {
                    Label("Leave", systemImage: "phone.down.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 4)
        }
    }

    private func controlButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
    }
}
