import SwiftUI

struct ParticipantsView: View {
    let participants: [MeetingParticipant]
    var onSelectParticipant: ((MeetingParticipant) -> Void)? = nil
    var canManageParticipant: ((MeetingParticipant) -> Bool)? = nil
    var onToggleParticipantHand: ((String) -> Void)? = nil

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
                                Text(participant.role.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if participant.isHandRaised {
                                Text("✋")
                                    .font(.caption)
                            }
                            if participant.isSpeaking {
                                Label("Speaking", systemImage: "waveform")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            Text(participant.networkQuality.label)
                                .font(.caption2)
                                .foregroundStyle(participant.networkQuality == .poor ? .orange : .secondary)
                            Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                                .foregroundStyle(participant.isMuted ? .red : .green)
                            Image(systemName: participant.hasVideo ? "video.fill" : "video.slash.fill")
                                .foregroundStyle(participant.hasVideo ? .green : .secondary)
                            if participant.isHandRaised, let onToggleParticipantHand, canManage {
                                Button("Lower") {
                                    onToggleParticipantHand(participant.id)
                                }
                                .font(.caption2)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(onSelectParticipant != nil && !canManage)
                    .accessibilityLabel("\(canManage ? "Manage" : "View") participant \(participant.displayName)")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
