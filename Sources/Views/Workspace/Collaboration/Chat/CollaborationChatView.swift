import SwiftUI

struct CollaborationChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var selectedChannel: ChatChannel = .general

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChatChannel.allCases, id: \.self) { channel in
                        Button {
                            selectedChannel = channel
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: channel.icon)
                                Text(channel.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedChannel == channel ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedChannel == channel ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages.filter { $0.channel == selectedChannel }) { message in
                            messageView(message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            Divider()

            HStack(spacing: 8) {
                Button { } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                TextField("Message #\(selectedChannel.rawValue)", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(newMessage.isEmpty ? .secondary : .blue)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .task { loadMessages() }
    }

    private func messageView(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(message.author)
                        .font(.subheadline.bold())
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message.text)
                    .font(.subheadline)
                if !message.reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(message.reactions, id: \.self) { reaction in
                            Text(reaction)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            Spacer()
        }
    }

    private func sendMessage() {
        messages.append(ChatMessage(author: "You", text: newMessage, channel: selectedChannel, timestamp: Date()))
        newMessage = ""
    }

    private func loadMessages() {
        messages = [
            ChatMessage(author: "Alice", text: "Has anyone tested the new connector API?", channel: .general, timestamp: Date().addingTimeInterval(-3600)),
            ChatMessage(author: "Bob", text: "Yes, it works great. The health monitoring is really useful.", channel: .general, timestamp: Date().addingTimeInterval(-3200), reactions: ["thumbsup"]),
            ChatMessage(author: "Charlie", text: "Found a small bug in the plugin sandbox. Filing an issue.", channel: .general, timestamp: Date().addingTimeInterval(-2800)),
            ChatMessage(author: "Alice", text: "The deploy pipeline passed all checks.", channel: .deployments, timestamp: Date().addingTimeInterval(-1800)),
            ChatMessage(author: "Bob", text: "PR #42 ready for review.", channel: .reviews, timestamp: Date().addingTimeInterval(-900)),
        ]
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID()
    let author: String
    let text: String
    let channel: ChatChannel
    let timestamp: Date
    var reactions: [String] = []
}

private enum ChatChannel: String, CaseIterable {
    case general, reviews, deployments, alerts

    var icon: String {
        switch self {
        case .general: return "number"
        case .reviews: return "eye"
        case .deployments: return "shippingbox"
        case .alerts: return "bell"
        }
    }
}
