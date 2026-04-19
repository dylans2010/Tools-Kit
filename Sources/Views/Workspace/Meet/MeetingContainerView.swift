import SwiftUI

struct MeetingContainerView: View {
    @ObservedObject var manager: MeetingStateManager

    @State private var showChat = false
    @State private var showParticipants = false
    @State private var showSettings = false
    @State private var showAdmin = false

    var body: some View {
        VStack(spacing: 12) {
            VideoGridView(participants: manager.participants)
                .frame(maxHeight: 340)

            MeetingControlsView(
                isMuted: manager.isMicrophoneMuted,
                isCameraEnabled: manager.isCameraEnabled,
                isScreenSharing: manager.isScreenSharing,
                onToggleMute: { manager.toggleMute() },
                onToggleCamera: { manager.toggleCamera() },
                onToggleScreenShare: { manager.toggleScreenShare() },
                onLeaveMeeting: { Task { await manager.leaveMeeting() } },
                onOpenChat: { showChat = true },
                onOpenParticipants: { showParticipants = true },
                onOpenSettings: { showSettings = true },
                onOpenAdmin: manager.isCurrentUserHost ? { showAdmin = true } : nil
            )

            MeetingStateView(manager: manager)
            MeetingDiagnosticsView(diagnostics: manager.diagnostics)
        }
        .padding()
        .navigationTitle("Meeting")
        .sheet(isPresented: $showChat) {
            NavigationStack {
                MeetingChatView(
                    threads: manager.chatThreads,
                    messages: manager.messages,
                    onAddThread: { manager.addThread(named: $0) },
                    onSendMessage: { text, threadID in manager.sendMessage(text, threadId: threadID) }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showParticipants) {
            NavigationStack {
                ParticipantsView(participants: manager.participants)
                    .navigationTitle("Participants")
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                List {
                    AudioSettingsView(manager: manager)
                    VideoSettingsView(manager: manager)
                }
                .navigationTitle("Meeting Settings")
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAdmin) {
            NavigationStack {
                AdminControlsView(manager: manager)
            }
            .presentationDetents([.medium, .large])
        }
    }
}
