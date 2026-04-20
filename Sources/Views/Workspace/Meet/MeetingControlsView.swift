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
                    subtitle: isMuted ? "Audio is off" : "Audio is live",
                    icon: isMuted ? "mic.slash.fill" : "mic.fill",
                    tint: isMuted ? .red : .blue,
                    action: onToggleMute
                )
                controlIconButton(
                    title: isCameraEnabled ? "Camera Off" : "Camera On",
                    subtitle: isCameraEnabled ? "Video is live" : "Video is paused",
                    icon: isCameraEnabled ? "video.slash.fill" : "video.fill",
                    tint: isCameraEnabled ? .blue : .red,
                    action: onToggleCamera
                )
                controlIconButton(
                    title: isScreenSharing ? "Stop Share" : "Share",
                    subtitle: isScreenSharing ? "Screen is shared" : "Share your screen",
                    icon: isScreenSharing ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle",
                    tint: .blue,
                    action: onToggleScreenShare
                )

                if let onOpenChat {
                    controlIconButton(title: "Chat", subtitle: "Messages", icon: "message.fill", tint: .indigo, action: onOpenChat)
                }
                if let onOpenParticipants {
                    controlIconButton(title: "People", subtitle: "Attendees", icon: "person.3.fill", tint: .teal, action: onOpenParticipants)
                }
                if let onOpenSettings {
                    controlIconButton(title: "Settings", subtitle: "Devices", icon: "slider.horizontal.3", tint: .gray, action: onOpenSettings)
                }
                if let onOpenAdmin {
                    controlIconButton(title: "Admin", subtitle: "Host tools", icon: "person.badge.shield.checkmark.fill", tint: .purple, action: onOpenAdmin)
                }
                if let onOpenNotes {
                    controlIconButton(title: "Notes", subtitle: "Shared notes", icon: "note.text", tint: .mint, action: onOpenNotes)
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

    private func controlIconButton(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: Circle())
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 84)
        }
        .buttonStyle(.plain)
    }
}
