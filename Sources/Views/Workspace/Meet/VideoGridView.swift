import SwiftUI

struct VideoGridView: View {
    let participants: [MeetingParticipant]
    let videoTracks: [String: MeetingVideoTrack]
    let screenShareTracks: [String: MeetingVideoTrack]
    let activeScreenShareParticipantID: String?
    let spotlightedParticipantID: String?
    let pinnedParticipantID: String?

    var body: some View {
        GeometryReader { geo in
            let columns = participants.count > 4 ? 3 : (participants.count > 1 ? 2 : 1)
            let layout = Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)

            LazyVGrid(columns: layout, spacing: 12) {
                ForEach(participants) { participant in
                    VideoTileView(participant: participant, track: videoTracks[participant.id])
                        .frame(height: geo.size.height / CGFloat((participants.count + columns - 1) / columns) - 12)
                }
            }
        }
    }
}

struct VideoTileView: View {
    let participant: MeetingParticipant
    let track: MeetingVideoTrack?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.workspaceSurface)

            if participant.hasVideo {
                // Actual video implementation would go here
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(Text(participant.displayName.prefix(1).uppercased()).font(.title.bold()))
            }

            HStack {
                Text(participant.displayName)
                    .font(.caption.bold())
                if participant.isMuted {
                    Image(systemName: "mic.slash.fill").font(.caption2).foregroundStyle(.red)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(participant.isSpeaking ? Color.blue : Color.clear, lineWidth: 2))
    }
}
