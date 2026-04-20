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
            HStack(spacing: 14) {
                controlIconButton(
                    title: isMuted ? "Unmute" : "Mute",
                    icon: isMuted ? "mic.slash.fill" : "mic.fill",
                    tint: isMuted ? .orange : .green,
                    action: onToggleMute
                )
                controlIconButton(
                    title: isCameraEnabled ? "Camera Off" : "Camera On",
                    icon: isCameraEnabled ? "video.slash.fill" : "video.fill",
                    tint: isCameraEnabled ? .orange : .green,
                    action: onToggleCamera
                )
                controlIconButton(
                    title: isScreenSharing ? "Stop Share" : "Share",
                    icon: isScreenSharing ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle",
                    tint: .blue,
                    action: onToggleScreenShare
                )

                if let onOpenChat {
                    controlIconButton(title: "Chat", icon: "message.fill", tint: .indigo, action: onOpenChat)
                }
                if let onOpenParticipants {
                    controlIconButton(title: "People", icon: "person.3.fill", tint: .teal, action: onOpenParticipants)
                }
                if let onOpenSettings {
                    controlIconButton(title: "Settings", icon: "slider.horizontal.3", tint: .gray, action: onOpenSettings)
                }
                if let onOpenAdmin {
                    controlIconButton(title: "Admin", icon: "person.badge.shield.checkmark.fill", tint: .purple, action: onOpenAdmin)
                }
                if let onOpenNotes {
                    controlIconButton(title: "Notes", icon: "note.text", tint: .mint, action: onOpenNotes)
                }

                Button(role: .destructive, action: onLeaveMeeting) {
                    Label("Leave", systemImage: "phone.down.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
        }
    }

    private func controlIconButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: Circle())
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
