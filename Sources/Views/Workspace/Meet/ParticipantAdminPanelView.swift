import SwiftUI

struct ParticipantAdminPanelView: View {
    @ObservedObject var manager: MeetingStateManager
    let participant: MeetingParticipant

    @State private var selectedRole: MeetingParticipantRole

    init(manager: MeetingStateManager, participant: MeetingParticipant) {
        self.manager = manager
        self.participant = participant
        _selectedRole = State(initialValue: participant.role)
    }

    var body: some View {
        List {
            Section("Participant") {
                Text(participant.displayName)
                Picker("Role", selection: $selectedRole) {
                    ForEach(MeetingParticipantRole.allCases.filter { $0 != .host }) { role in
                        Text(role.displayName).tag(role)
                    }
                }
                .onChange(of: selectedRole, initial: false) { _, newRole in
                    Task { await manager.assignRole(participantID: participant.id, role: newRole) }
                }
            }

            Section("Controls") {
                Button("Mute Participant") {
                    Task { await manager.setParticipantMuted(participantID: participant.id, muted: true) }
                }
                Button("Disable Camera") {
                    Task { await manager.setParticipantVideoEnabled(participantID: participant.id, enabled: false) }
                }
                Button("Kick Participant", role: .destructive) {
                    Task { await manager.removeParticipant(participantID: participant.id) }
                }
            }
        }
        .navigationTitle("Admin Controls")
    }
}
