import SwiftUI

struct AdminControlsView: View {
    @ObservedObject var manager: MeetingStateManager
    @State private var showingBreakoutManager = false

    var body: some View {
        List {
            Section("Global Controls") {
                Button("Mute All Participants") {
                    Task { await manager.muteAllParticipants() }
                }
                .buttonStyle(.bordered)
            }

            Section("Participants") {
                ForEach(manager.participants.filter { $0.role != .host }) { participant in
                    NavigationLink(participant.displayName) {
                        ParticipantAdminPanelView(manager: manager, participant: participant)
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
        .sheet(isPresented: $showingBreakoutManager) {
            NavigationStack {
                BreakoutRoomManagerView(manager: manager)
            }
            .presentationDetents([.medium, .large])
        }
    }
}
