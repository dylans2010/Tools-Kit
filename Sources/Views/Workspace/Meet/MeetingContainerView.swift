import SwiftUI

struct MeetingContainerView: View {
    @ObservedObject var manager: MeetingStateManager

    @State private var showChat = false
    @State private var showParticipants = false
    @State private var showSettings = false
    @State private var showAdmin = false
    @State private var showNotes = false
    @State private var selectedParticipant: MeetingParticipant?
    @State private var showHostLeaveOptions = false

    var body: some View {
        VStack(spacing: 12) {
            VideoGridView(
                participants: manager.participants,
                videoTracks: manager.participantVideoTracks,
                screenShareTracks: manager.participantScreenShareTracks,
                activeScreenShareParticipantID: manager.activeScreenShareParticipantID,
                spotlightedParticipantID: manager.spotlightedParticipantID,
                pinnedParticipantID: manager.pinnedParticipantID
            )
                .frame(maxHeight: 340)

            MeetingControlsView(
                isMuted: manager.isMicrophoneMuted,
                isCameraEnabled: manager.isCameraEnabled,
                isScreenSharing: manager.isScreenSharing,
                onToggleMute: { manager.toggleMute() },
                onToggleCamera: { manager.toggleCamera() },
                onToggleScreenShare: { manager.toggleScreenShare() },
                onLeaveMeeting: {
                    if manager.isCurrentUserHost {
                        showHostLeaveOptions = true
                    } else {
                        Task { await manager.leaveMeeting() }
                    }
                },
                onOpenChat: { showChat = true },
                onOpenParticipants: { showParticipants = true },
                onOpenSettings: { showSettings = true },
                onOpenAdmin: manager.canAccessAdminControls ? { showAdmin = true } : nil,
                onOpenNotes: { showNotes = true }
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
                    isChatEnabled: manager.isChatEnabled || manager.canAccessAdminControls,
                    onAddThread: { manager.addThread(named: $0) },
                    onSendMessage: { text, threadID in manager.sendMessage(text, threadId: threadID) }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showParticipants) {
            NavigationStack {
                ParticipantsView(
                    participants: manager.participants,
                    onSelectParticipant: { participant in
                        guard manager.canAccessAdminControls, let localParticipantID = manager.localParticipantID, participant.id != localParticipantID else { return }
                        selectedParticipant = participant
                    },
                    canManageParticipant: { participant in
                        guard manager.canAccessAdminControls, let localParticipantID = manager.localParticipantID else { return false }
                        return participant.id != localParticipantID
                    }
                )
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
        .sheet(isPresented: $showNotes) {
            NavigationStack {
                MeetingNotesView(manager: manager)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedParticipant) { participant in
            NavigationStack {
                ParticipantAdminPanelView(manager: manager, participant: participant)
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Leave meeting", isPresented: $showHostLeaveOptions) {
            Button("Leave meeting", role: .cancel) {
                Task { await manager.leaveMeeting() }
            }
            Button("End meeting for everyone", role: .destructive) {
                Task { await manager.endMeetingForEveryone() }
            }
        } message: {
            Text("Leave meeting or end meeting for everyone.")
        }
    }
}
