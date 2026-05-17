import SwiftUI

struct CollaborationChatView: View {
    let workspace: CollaborationWorkspace
    let channel: CollaborationChannel
    let onOpenThread: (CollaborationMessage) -> Void

    @State private var messageText = ""
    @StateObject private var manager = CollaborationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(channel.type == .privateChannel ? "🔒" : "#") \(channel.name)")
                        .font(.headline)
                    if !channel.description.isEmpty {
                        Text(channel.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()

                HStack(spacing: 16) {
                    Button { /* Search */ } label: { Image(systemName: "magnifyingglass") }
                    Button { /* Channel Info */ } label: { Image(systemName: "info.circle") }
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))

            Divider()

            // Messages List
            ScrollViewReader { proxy in
                List {
                    Group {
                        let messages = manager.workspaces
                            .first(where: { $0.id == workspace.id })?
                            .channels.first(where: { $0.id == channel.id })?
                            .messages ?? []

                        if messages.isEmpty {
                            EmptyChatState()
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(messages) { message in
                                ChatMessageBubble(
                                    message: message,
                                    onThreadTap: { onOpenThread(message) }
                                )
                                .id(message.id)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .onChange(of: channel.messages.count) { _, _ in
                    if let lastId = channel.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Input Area
            VStack(spacing: 0) {
                // Presence / Typing Indicator placeholder
                TypingIndicatorView(channelID: channel.id)

                HStack(spacing: 12) {
                    Button { /* Attachments */ } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Message \(channel.name)", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .lineLimit(1...8)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(messageText.isEmpty ? Color.secondary : Color.blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        manager.sendMessage(
            content: trimmed,
            channelID: channel.id,
            workspaceID: workspace.id
        )
        messageText = ""
    }
}

private struct ChatMessageBubble: View {
    let message: CollaborationMessage
    let onThreadTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.senderName)
                        .font(.subheadline.bold())
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(message.content)
                    .font(.subheadline)

                if let thread = message.thread, !thread.replies.isEmpty {
                    Button(action: onThreadTap) {
                        HStack {
                            Text("\(thread.replies.count) replies")
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                } else {
                    Button(action: onThreadTap) {
                        Label("Reply", systemImage: "bubble.left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                    .opacity(0) // Show on hover logic can be added later
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyChatState: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.3))
            Text("Beginning of the conversation")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Send a message to start collaborating.")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TypingIndicatorView: View {
    let channelID: UUID
    @StateObject private var manager = CollaborationManager.shared

    var body: some View {
        HStack {
            let typingUsers = manager.presence.values.filter { $0.status == .typing }
            if !typingUsers.isEmpty {
                Text("\(typingUsers.count) people typing...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
            }
            Spacer()
        }
        .frame(height: 20)
    }
}
