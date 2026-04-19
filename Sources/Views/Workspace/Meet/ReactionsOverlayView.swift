import SwiftUI

struct ReactionsOverlayView: View {
    let reactions: [MeetingReactionEvent]
    let onSendReaction: (String) -> Void

    private let quickReactions = ["👍", "👏", "🎉", "❤️", "😂"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(quickReactions, id: \.self) { emoji in
                    Button(emoji) { onSendReaction(emoji) }
                        .buttonStyle(.bordered)
                }
            }
            if let recent = reactions.last {
                Text("\(recent.participantName) reacted \(recent.emoji)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
