import SwiftUI

struct ParticipantsView: View {
    let participants: [MeetingParticipant]
    var onSelectParticipant: ((MeetingParticipant) -> Void)? = nil
    var canManageParticipant: ((MeetingParticipant) -> Bool)? = nil

    var body: some View {
        List {
            if participants.isEmpty {
                ContentUnavailableView(
                    "No Participants Yet",
                    systemImage: "person.3.sequence",
                    description: Text("Participants will appear once people join the meeting.")
                )
            } else {
                ForEach(participants) { participant in
                    let canManage = canManageParticipant?(participant) ?? false
                    Button {
                        onSelectParticipant?(participant)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(participant.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text(participant.role.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if participant.isSpeaking {
                                Label("Speaking", systemImage: "waveform")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                                .foregroundStyle(participant.isMuted ? .red : .green)
                            Image(systemName: participant.hasVideo ? "video.fill" : "video.slash.fill")
                                .foregroundStyle(participant.hasVideo ? .green : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(onSelectParticipant != nil && !canManage)
                    .accessibilityLabel((canManage ? "Manage participant " : "View participant ") + participant.displayName)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
