import SwiftUI

struct AdminControlsView: View {
    @ObservedObject var manager: MeetingStateManager
    @State private var showingBreakoutManager = false
    @State private var selectedSpotlightParticipantID: String?
    @State private var selectedPinnedParticipantID: String?

    var body: some View {
        List {
            Section("Global Controls") {
                Button("Mute All Participants") {
                    Task { await manager.muteAllParticipants() }
                }
                .buttonStyle(.bordered)
                Toggle("Lock Meeting", isOn: Binding(
                    get: { manager.isMeetingLocked },
                    set: { Task { await manager.setMeetingLocked($0) } }
                ))
                Toggle("Enable Chat", isOn: Binding(
                    get: { manager.isChatEnabled },
                    set: { Task { await manager.setChatEnabled($0) } }
                ))
                Toggle("Allow Screen Sharing", isOn: Binding(
                    get: { manager.isScreenShareAllowed },
                    set: { Task { await manager.setScreenShareAllowed($0) } }
                ))
                if manager.isCurrentUserHost {
                    Button("End Meeting for All", role: .destructive) {
                        Task { await manager.endMeetingForEveryone() }
                    }
                }
            }

            Section("Participants") {
                ForEach(manager.participants.filter { $0.role != .host }) { participant in
                    NavigationLink(participant.displayName) {
                        ParticipantAdminPanelView(manager: manager, participant: participant)
                    }
                }
            }

            Section("Spotlight / Pin") {
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

            Section("Breakout Rooms") {
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
        manager.participants.filter { !$0.isScreenSharing }
    }
}
