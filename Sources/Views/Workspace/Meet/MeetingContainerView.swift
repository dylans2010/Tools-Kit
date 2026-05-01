import SwiftUI

struct MeetingContainerView: View {
    @ObservedObject var manager: MeetingStateManager

    @State private var showChat = false
    @State private var showParticipants = false
    @State private var showSettings = false
    @State private var showSummary = false
    @State private var showAssistant = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    meetingHeader

                    VideoGridView(
                        participants: manager.participants,
                        videoTracks: manager.participantVideoTracks,
                        screenShareTracks: manager.participantScreenShareTracks,
                        activeScreenShareParticipantID: manager.activeScreenShareParticipantID,
                        spotlightedParticipantID: manager.spotlightedParticipantID,
                        pinnedParticipantID: manager.pinnedParticipantID
                    )
                    .padding()

                    meetingFooter
                }
            }
            .navigationTitle("Live Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAssistant.toggle() } label: { Image(systemName: "sparkles").foregroundStyle(.purple) }
                }
            }
            .sheet(isPresented: $showChat) { MeetingChatView(threads: manager.chatThreads, messages: manager.messages) }
            .sheet(isPresented: $showParticipants) { ParticipantsView(participants: manager.participants) }
            .sheet(isPresented: $showSettings) { MeetingSettingsView(manager: manager) }
            .sheet(isPresented: $showAssistant) { MeetingSummaryView(manager: manager) }
        }
    }

    private var meetingHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Engineering Sync").font(.headline)
                HStack {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Recording & Live Transcribing").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()

            HStack(spacing: 12) {
                sentimentIndicator
                engagementPill
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var sentimentIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "face.smiling.fill").foregroundStyle(.yellow)
            Text("\(Int(manager.sentimentScore * 100))%").font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.1), in: Capsule())
    }

    private var engagementPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill").foregroundStyle(.blue)
            Text("High Engagement").font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1), in: Capsule())
    }

    private var meetingFooter: some View {
        VStack {
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
                onOpenSettings: { showSettings = true }
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
}
