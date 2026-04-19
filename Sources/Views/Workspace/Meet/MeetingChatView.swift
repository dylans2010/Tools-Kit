/*
 * Summary: Modern chat layout with emoji reactions.
 * Changes: Implemented bubble-style chat, message alignment, and emoji reaction support.
 */

import SwiftUI

/// Modern chat interface for meetings.
struct MeetingChatView: View {
    @ObservedObject var controller: MeetSessionController
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(controller.messages) { message in
                            ChatBubble(message: message) { emoji in
                                addReaction(to: message, emoji: emoji)
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: controller.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(controller.messages.last?.id, anchor: .bottom)
                    }
                }
            }

            messageInputArea
        }
        .background(Color(.systemGroupedBackground))
    }

    private var chatHeader: some View {
        HStack {
            Text("Meeting Chat")
                .font(.headline)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
        }
        .padding()
        .background(Material.ultraThinMaterial)
    }

    private var messageInputArea: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)

            Button {
                guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                controller.sendChatMessage(messageText)
                messageText = ""
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(messageText.isEmpty ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
        .background(Material.ultraThinMaterial)
    }

    private func addReaction(to message: MeetingMessage, emoji: String) {
        let payload: [String: Any] = [
            "type": "reaction",
            "messageID": message.id,
            "emoji": emoji
        ]
        Task { try? await controller.callManager.sendAppMessage(payload) }
    }
}

/// Individual chat bubble with reaction support.
struct ChatBubble: View {
    let message: MeetingMessage
    let onReact: (String) -> Void

    var isFromMe: Bool { message.senderName == "You" }

    var body: some View {
        HStack {
            if isFromMe { Spacer() }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                if !isFromMe {
                    Text(message.senderName)
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }

                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                    .foregroundColor(isFromMe ? .white : .primary)
                    .clipShape(ChatBubbleShape(isFromMe: isFromMe))

                Text(message.sentAt, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            if !isFromMe { Spacer() }
        }
        .contextMenu {
            Button { onReact("❤️") } label: { Label("Love", systemImage: "heart") }
            Button { onReact("😂") } label: { Label("Laugh", systemImage: "face.smiling") }
            Button { onReact("👍") } label: { Label("Thumbs Up", systemImage: "hand.thumbsup") }
        }
    }
}

/// Custom shape for chat bubbles.
struct ChatBubbleShape: Shape {
    let isFromMe: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                               byRoundingCorners: [.topLeft, .topRight, isFromMe ? .bottomLeft : .bottomRight],
                               cornerRadii: CGSize(width: 16, height: 16))
        return Path(path.cgPath)
    }
}
