import SwiftUI

struct ChatMessageBubbleView: View {
    let message: MeetingMessage
    var onReact: ((String) -> Void)? = nil
    private let quickReactions = ["👍", "❤️", "😂"]

    var body: some View {
        HStack {
            if !message.isSystem && message.senderName == "You" {
                Spacer(minLength: 30)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption.bold())
                    .foregroundStyle(message.isSystem ? Color.orange : Color.secondary)
                Text(message.text)
                    .font(.subheadline)
                Text(message.sentAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if !message.isSystem {
                    Text(message.deliveryState.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if !message.reactions.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(message.reactions.keys.sorted(), id: \.self) { emoji in
                            Text("\(emoji) \(message.reactions[emoji, default: 0])")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(uiColor: .tertiarySystemBackground), in: Capsule())
                        }
                    }
                }
                if let onReact, !message.isSystem {
                    HStack(spacing: 4) {
                        ForEach(quickReactions, id: \.self) { emoji in
                            Button(emoji) { onReact(emoji) }
                                .font(.caption2)
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(message.isSystem ? Color.orange.opacity(0.15) : Color.blue.opacity(0.12))
            )
            if message.isSystem || message.senderName != "You" {
                Spacer(minLength: 30)
            }
        }
        .animation(.easeOut(duration: 0.2), value: message.id)
    }
}
