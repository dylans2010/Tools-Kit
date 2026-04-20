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
    @State private var showAssistantTools = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerSummary

                VideoGridView(
                    participants: manager.participants,
                    videoTracks: manager.participantVideoTracks,
                    screenShareTracks: manager.participantScreenShareTracks,
                    activeScreenShareParticipantID: manager.activeScreenShareParticipantID,
                    spotlightedParticipantID: manager.spotlightedParticipantID,
                    pinnedParticipantID: manager.pinnedParticipantID
                )
                .frame(minHeight: 240, maxHeight: 430)

                surfaceCard {
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
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    surfaceCard {
                        NoiseControlView(
                            isEnabled: manager.isNoiseCancellationEnabled,
                            processingState: manager.activeAudioProcessingState,
                            onToggle: { manager.setNoiseCancellationEnabled($0) }
                        )
                    }
                    surfaceCard {
                        NetworkStatusView(
                            quality: manager.networkQuality,
                            latencyMs: manager.diagnostics.latencyMs,
                            packetLossPercent: manager.diagnostics.packetLossPercent
                        )
                    }
                    surfaceCard {
                        PiPOverlayView(
                            isEnabled: manager.isPiPEnabled,
                            isActive: manager.isPiPActive,
                            onToggle: { manager.setPiPEnabled($0) }
                        )
                    }
                    surfaceCard {
                        BackgroundEffectsView(
                            selectedEffect: manager.backgroundEffect,
                            onSelectEffect: { manager.setBackgroundEffect($0) }
                        )
                    }
                }

                DisclosureGroup(isExpanded: $showAssistantTools) {
                    VStack(spacing: 10) {
                        surfaceCard {
                            ReactionsOverlayView(
                                reactions: manager.reactions,
                                onSendReaction: { manager.sendReaction($0) }
                            )
                        }
                        surfaceCard {
                            HandRaiseView(
                                participants: manager.participants,
                                localParticipantID: manager.localParticipantID,
                                canManageOthers: manager.canAccessAdminControls,
                                onToggleLocalHand: { manager.toggleRaiseHand() },
                                onLowerHand: { manager.setHandRaised(participantID: $0, raised: false) }
                            )
                        }
                        surfaceCard {
                            LiveCaptionsView(
                                isEnabled: manager.isCaptionsEnabled,
                                captions: manager.captions,
                                onToggleVisibility: { manager.setCaptionsEnabled($0) }
                            )
                        }
                        if !manager.cpuWarnings.isEmpty {
                            surfaceCard {
                                PerformanceWarningView(warnings: manager.cpuWarnings, onDismiss: manager.dismissCPUWarning)
                            }
                        }
                        surfaceCard {
                            MeetingStateView(manager: manager)
                        }
                        surfaceCard {
                            MeetingDiagnosticsView(diagnostics: manager.diagnostics)
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Label("More meeting tools", systemImage: "wand.and.stars")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Meeting")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showChat) {
            NavigationStack {
                MeetingChatView(
                    threads: manager.chatThreads,
                    messages: manager.messages,
                    isChatEnabled: manager.isChatEnabled || manager.canAccessAdminControls,
                    onAddThread: { manager.addThread(named: $0) },
                    onSendMessage: { text, threadID in manager.sendMessage(text, threadId: threadID) },
                    onReactToMessage: { messageID, emoji in manager.reactToMessage(messageID: messageID, emoji: emoji) }
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
                    },
                    onToggleParticipantHand: { participantID in
                        manager.setHandRaised(participantID: participantID, raised: false)
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
                WorkspaceMeetingNotesView(manager: manager)
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
        .animation(.easeInOut(duration: 0.2), value: showAssistantTools)
    }

    private var headerSummary: some View {
        HStack(spacing: 10) {
            summaryChip(title: "Participants", value: "\(manager.participants.count)", symbol: "person.3.fill")
            summaryChip(title: "Network", value: manager.networkQuality.label, symbol: "antenna.radiowaves.left.and.right")
            summaryChip(title: "Mic", value: manager.isMicrophoneMuted ? "Muted" : "Live", symbol: manager.isMicrophoneMuted ? "mic.slash.fill" : "mic.fill")
        }
    }

    private func summaryChip(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func surfaceCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
