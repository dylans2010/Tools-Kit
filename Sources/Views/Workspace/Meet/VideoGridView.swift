import SwiftUI

struct VideoGridView: View {
    let participants: [MeetingParticipant]
    let videoTracks: [String: MeetingVideoTrack]
    let screenShareTracks: [String: MeetingVideoTrack]
    let activeScreenShareParticipantID: String?
    let spotlightedParticipantID: String?
    let pinnedParticipantID: String?

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
            if let activeScreenShareParticipantID,
               let sharer = participants.first(where: { $0.id == activeScreenShareParticipantID }),
               let screenTrack = screenShareTracks[activeScreenShareParticipantID] {
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(sharer.displayName) is sharing screen", systemImage: "rectangle.on.rectangle")
                        .font(.caption.weight(.semibold))
                    VideoTileView(participant: sharer, track: screenTrack)
                }
                .padding(8)
            }
            if liveVideoParticipants.isEmpty {
                ContentUnavailableView(
                    "No live Daily video tracks",
                    systemImage: "video.slash",
                    description: Text("Tiles render only active Daily media tracks.")
                )
                .padding(.top, 16)
                .padding(8)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(orderedParticipants) { participant in
                        VideoTileView(participant: participant, track: videoTracks[participant.id])
                    }
                }
                .padding(8)
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var orderedParticipants: [MeetingParticipant] {
        liveVideoParticipants.sorted { lhs, rhs in
            let lhsPriority = sortPriority(for: lhs.id)
            let rhsPriority = sortPriority(for: rhs.id)
            if lhsPriority != rhsPriority {
                return lhsPriority > rhsPriority
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    private func sortPriority(for participantID: String) -> Int {
        if participantID == pinnedParticipantID { return 3 }
        if participantID == spotlightedParticipantID { return 2 }
        if participantID == activeScreenShareParticipantID { return 1 }
        return 0
    }
}
