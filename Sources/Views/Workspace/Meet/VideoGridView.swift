import SwiftUI

struct VideoGridView: View {
    let participants: [MeetingParticipant]
    let videoTracks: [String: MeetingVideoTrack]

    private var liveVideoParticipants: [MeetingParticipant] {
        participants.filter { participant in
            participant.hasVideo && videoTracks[participant.id] != nil
        }
    }

    private var columns: [GridItem] {
        let count = max(1, liveVideoParticipants.count)
        if count <= 1 { return [GridItem(.flexible())] }
        if count <= 4 { return [GridItem(.flexible()), GridItem(.flexible())] }
        return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            if liveVideoParticipants.isEmpty {
                ContentUnavailableView(
                    "No live Daily video tracks",
                    systemImage: "video.slash",
                    description: Text("Tiles render only active Daily media tracks.")
                )
                .padding(.top, 16)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(liveVideoParticipants) { participant in
                        VideoTileView(participant: participant, track: videoTracks[participant.id])
                    }
                }
            }
            .padding(8)
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
