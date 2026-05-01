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
