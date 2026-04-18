import SwiftUI
import Daily

struct ParticipantsView: View {
    let participants: [MeetingParticipant]

    var body: some View {
        List(participants) { participant in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(participant.joinedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if participant.isSpeaking {
                    Label("Speaking", systemImage: "waveform")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                    .foregroundColor(participant.isMuted ? .red : .green)
                Image(systemName: participant.hasVideo ? "video.fill" : "video.slash.fill")
                    .foregroundColor(participant.hasVideo ? .green : .secondary)
            }
        }
    }
}
