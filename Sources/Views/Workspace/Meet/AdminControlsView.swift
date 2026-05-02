import SwiftUI

struct AdminControlsView: View {
    @ObservedObject var manager: MeetingStateManager
    @State private var showingBreakoutManager = false
    @State private var selectedSpotlightParticipantID: String?
    @State private var selectedPinnedParticipantID: String?

    var body: some View {
        List {
            Section {
                Button("Mute All Participants") {
                    Task { await manager.muteAllParticipants() }
                }
                .buttonStyle(.bordered)
                Toggle("Lock Meeting", isOn: Binding(
                    get: { manager.isMeetingLocked },
                    set: { newValue in Task { await manager.setMeetingLocked(newValue) } }
                ))
                Toggle("Enable Chat", isOn: Binding(
                    get: { manager.isChatEnabled },
                    set: { newValue in Task { await manager.setChatEnabled(newValue) } }
                ))
                Toggle("Allow Screen Sharing", isOn: Binding(
                    get: { manager.isScreenShareAllowed },
                    set: { newValue in Task { await manager.setScreenShareAllowed(newValue) } }
                ))
                if manager.isCurrentUserHost {
                    Button("End Meeting for All", role: .destructive) {
                        Task { await manager.endMeetingForEveryone() }
                    }
                }
            } header: {
                Text("Global Controls")
            }

            Section {
                ForEach(manager.participants.filter { $0.role != .host }) { participant in
                    NavigationLink(participant.displayName) {
                        ParticipantAdminPanelView(manager: manager, participant: participant)
                    }
                }
            } header: {
                Text("Participants")
            }

            Section {
                Picker("Spotlight", selection: Binding(
                    get: { selectedSpotlightParticipantID },
                    set: { newValue in
                        selectedSpotlightParticipantID = newValue
                        Task { await manager.spotlightParticipant(newValue) }
                    }
                )) {
                    Text("None").tag(String?.none)
                    ForEach(spotlightCandidates) { participant in
                        Text(participant.displayName).tag(String?.some(participant.id))
                    }
                }
                Picker("Pin", selection: Binding(
                    get: { selectedPinnedParticipantID },
                    set: { newValue in
                        selectedPinnedParticipantID = newValue
                        Task { await manager.pinParticipant(newValue) }
                    }
                )) {
                    Text("None").tag(String?.none)
                    ForEach(manager.participants) { participant in
                        Text(participant.displayName).tag(String?.some(participant.id))
                    }
                }
            } header: {
                Text("Spotlight / Pin")
            }

            Section {
                Button("Manage Breakout Rooms") {
                    showingBreakoutManager = true
                }
                .buttonStyle(.borderedProminent)
            } header: {
                Text("Breakout Rooms")
            }
        }
        .navigationTitle("Admin Controls")
        .onAppear {
            selectedSpotlightParticipantID = manager.spotlightedParticipantID
            selectedPinnedParticipantID = manager.pinnedParticipantID
        }
        .sheet(isPresented: $showingBreakoutManager) {
            NavigationStack {
                BreakoutRoomManagerView(manager: manager)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var spotlightCandidates: [MeetingParticipant] {
        // Keep active screen-share presenters out of spotlight picker to avoid conflicting
        // dominant layout intents between presenter mode and spotlight mode.
        manager.participants.filter { !$0.isScreenSharing }
    }
}
