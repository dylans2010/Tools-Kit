import SwiftUI

struct BreakoutRoomCardView: View {
    let room: MeetingBreakoutRoom
    let participants: [MeetingParticipant]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(room.name)
                .font(.headline)
            if room.participantIds.isEmpty {
                Text("No Participants Assigned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(room.participantIds, id: \.self) { participantID in
                    if let participant = participants.first(where: { $0.id == participantID }) {
                        Text(participant.displayName)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
