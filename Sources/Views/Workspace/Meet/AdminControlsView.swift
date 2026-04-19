import SwiftUI

struct AdminControlsView: View {
    @ObservedObject var manager: MeetingStateManager
    @State private var showingBreakoutManager = false
    @State private var selectedSpotlightParticipantID: String?
    @State private var selectedPinnedParticipantID: String?

    var body: some View {
        List {
            Section(header: Text("Global Controls")) {
                Button("Mute All Participants") {
                    Task { await manager.muteAllParticipants() }
                }
                .buttonStyle(.bordered)
                Toggle("Lock Meeting", isOn: Binding(
                    get: { manager.isMeetingLocked },
                    set: { newValue, _ in Task { await manager.setMeetingLocked(newValue) } }
                ))
                Toggle("Enable Chat", isOn: Binding(
                    get: { manager.isChatEnabled },
                    set: { newValue, _ in Task { await manager.setChatEnabled(newValue) } }
                ))
                Toggle("Allow Screen Sharing", isOn: Binding(
                    get: { manager.isScreenShareAllowed },
                    set: { newValue, _ in Task { await manager.setScreenShareAllowed(newValue) } }
                ))
                if manager.isCurrentUserHost {
                    Button("End Meeting for All", role: .destructive) {
                        Task { await manager.endMeetingForEveryone() }
                    }
                }
            }

            Section(header: Text("Participants")) {
                ForEach(manager.participants.filter { $0.role != .host }) { participant in
                    NavigationLink(participant.displayName) {
                        ParticipantAdminPanelView(manager: manager, participant: participant)
                    }
                }
            }

            Section(header: Text("Spotlight / Pin")) {
                Picker("Spotlight", selection: Binding(
                    get: { selectedSpotlightParticipantID },
                    set: {
                        selectedSpotlightParticipantID = $0
                        Task { await manager.spotlightParticipant($0) }
                    }
                )) {
                    Text("None").tag(String?.none)
                    ForEach(spotlightCandidates) { participant in
                        Text(participant.displayName).tag(String?.some(participant.id))
                    }
                }
                Picker("Pin", selection: Binding(
                    get: { selectedPinnedParticipantID },
                    set: {
                        selectedPinnedParticipantID = $0
                        Task { await manager.pinParticipant($0) }
                    }
                )) {
                    Text("None").tag(String?.none)
                    ForEach(manager.participants) { participant in
                        Text(participant.displayName).tag(String?.some(participant.id))
                    }
                }
            }

            Section(header: Text("Breakout Rooms")) {
                Button("Manage Breakout Rooms") {
                    showingBreakoutManager = true
                }
                .buttonStyle(.borderedProminent)
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
