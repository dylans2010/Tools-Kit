import SwiftUI

struct ChatMessageBubbleView: View {
    let message: MeetingMessage

    var body: some View {
        HStack {
            if !message.isSystem && message.senderName == "You" {
                Spacer(minLength: 30)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption.bold())
                    .foregroundStyle(message.isSystem ? .orange : .secondary)
                Text(message.text)
                    .font(.subheadline)
                Text(message.sentAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
