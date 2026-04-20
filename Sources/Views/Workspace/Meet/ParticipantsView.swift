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
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(participant.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text(participant.role.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    Label(participant.networkQuality.label, systemImage: "antenna.radiowaves.left.and.right")
                                        .font(.caption2)
                                        .foregroundStyle(participant.networkQuality == .poor ? .orange : .secondary)
                                    Label(participant.isMuted ? "Muted" : "Unmuted", systemImage: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                                        .font(.caption2)
                                        .foregroundStyle(participant.isMuted ? .red : .green)
                                    Label(participant.hasVideo ? "Video On" : "Video Off", systemImage: participant.hasVideo ? "video.fill" : "video.slash.fill")
                                        .font(.caption2)
                                        .foregroundStyle(participant.hasVideo ? .green : .secondary)
                                }
                            }
                            Spacer()
                            if participant.isHandRaised {
                                Label("Hand", systemImage: "hand.raised.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            if participant.isSpeaking {
                                Label("Speaking", systemImage: "waveform")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            if participant.isHandRaised, let onToggleParticipantHand, canManage {
                                Button {
                                    onToggleParticipantHand(participant.id)
                                } label: {
                                    Label("Lower", systemImage: "hand.raised.slash")
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
