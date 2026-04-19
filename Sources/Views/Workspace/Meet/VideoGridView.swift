import SwiftUI

struct VideoGridView: View {
    let participants: [MeetingParticipant]

    private var columns: [GridItem] {
        let count = max(1, participants.count)
        if count <= 1 { return [GridItem(.flexible())] }
        if count <= 4 { return [GridItem(.flexible()), GridItem(.flexible())] }
        return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(participants) { participant in
                    VideoTileView(participant: participant)
                }
            }
            .padding(8)
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
