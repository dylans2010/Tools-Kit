import SwiftUI

struct VideoTileView: View {
    let participant: MeetingParticipant

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(participant.hasVideo ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(height: 120)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(participant.displayName)
                        .font(.caption.weight(.semibold))
                    if participant.isSpeaking {
                        Image(systemName: "waveform")
                            .foregroundStyle(.green)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                        .foregroundStyle(participant.isMuted ? .red : .green)
                    Text(participant.role.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
        }
    }
}
