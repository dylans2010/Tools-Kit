import SwiftUI

struct MeetingChatView: View {
    let threads: [MeetingChatThread]
    let messages: [MeetingMessage]

    @State private var selectedThreadID: String = "general"
    @State private var composerText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(threads) { thread in
                                Button { selectedThreadID = thread.id } label: {
                                    Text(thread.title)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedThreadID == thread.id ? Color.blue : Color.white.opacity(0.1), in: Capsule())
                                        .foregroundStyle(selectedThreadID == thread.id ? Color.white : Color.secondary)
                                }
                            }
                        }
                        .padding()
                    }

                    Divider().opacity(0.1)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(messages.filter { $0.threadId == selectedThreadID }) { message in
                                    ChatMessageRow(message: message)
                                }
                            }
                            .padding()
                        }
                    }

                    chatInput
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var chatInput: some View {
        HStack {
            TextField("Message...", text: $composerText)
                .padding(12)
                .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))

            Button {
                // Send logic
                composerText = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.blue)
            }
            .disabled(composerText.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct ChatMessageRow: View {
    let message: MeetingMessage
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(Text(message.senderName.prefix(1).uppercased()).font(.caption.bold()))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.senderName).font(.caption.bold())
                    Text(message.sentAt.formatted(.dateTime.hour().minute())).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Text(message.text)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
        }
    }
}
