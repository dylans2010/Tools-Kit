import SwiftUI

struct HandRaiseView: View {
    let participants: [MeetingParticipant]
    let localParticipantID: String?
    let canManageOthers: Bool
    let onToggleLocalHand: () -> Void
    let onLowerHand: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(localIsRaised ? "Lower Hand" : "Raise Hand", action: onToggleLocalHand)
                .buttonStyle(.borderedProminent)

            if raisedParticipants.isEmpty {
                Text("No raised hands")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(raisedParticipants) { participant in
                    HStack {
                        Text("✋ \(participant.displayName)")
                            .font(.caption)
                        Spacer()
                        if canManageOthers {
                            Button("Lower") { onLowerHand(participant.id) }
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var raisedParticipants: [MeetingParticipant] {
        participants.filter(\.isHandRaised)
    }

    private var localIsRaised: Bool {
        guard let localParticipantID else { return false }
        return participants.first(where: { $0.id == localParticipantID })?.isHandRaised ?? false
    }
}
