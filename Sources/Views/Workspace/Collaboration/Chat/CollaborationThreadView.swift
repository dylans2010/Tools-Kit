import SwiftUI

struct CollaborationThreadView: View {
    let workspace: CollaborationWorkspace
    let channel: CollaborationChannel
    let parentMessage: CollaborationMessage
    let onClose: () -> Void

    @State private var replyText = ""
    @StateObject private var manager = CollaborationManager.shared

    private var replies: [CollaborationMessage] {
        manager.workspaces
            .first(where: { $0.id == workspace.id })?
            .channels.first(where: { $0.id == channel.id })?
            .messages.first(where: { $0.id == parentMessage.id })?
            .thread?.replies ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thread")
                        .font(.headline)
                    Text(channel.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))

            Divider()

            // Parent Message Preview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(parentMessage.senderName)
                        .font(.subheadline.bold())
                    Text(parentMessage.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(parentMessage.content)
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemGroupedBackground).opacity(0.5))

            Divider()

            // Replies List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if replies.isEmpty {
                        Text("No replies yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(replies) { reply in
                            ThreadReplyBubble(reply: reply)
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Input
            HStack(spacing: 10) {
                TextField("Reply...", text: $replyText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .lineLimit(1...5)

                Button {
                    sendReply()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(replyText.isEmpty ? .secondary : .blue)
                }
                .disabled(replyText.isEmpty)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func sendReply() {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        manager.sendReply(
            content: trimmed,
            parentMessageID: parentMessage.id,
            channelID: channel.id,
            workspaceID: workspace.id
        )
        replyText = ""
    }
}

private struct ThreadReplyBubble: View {
    let reply: CollaborationMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reply.senderName)
                        .font(.caption.bold())
                    Text(reply.timestamp, style: .time)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Text(reply.content)
                    .font(.caption)
            }
        }
    }
}
