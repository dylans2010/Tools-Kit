import SwiftUI

struct MeetingChatView: View {
    let threads: [MeetingChatThread]
    let messages: [MeetingMessage]
    let onAddThread: (String) -> Void
    let onSendMessage: (String, String) -> Void

    @State private var selectedThreadID = "general"
    @State private var composerText = ""
    @State private var newThreadTitle = ""

    var body: some View {
        VStack(spacing: 12) {
            Picker("Thread", selection: $selectedThreadID) {
                ForEach(threads) { thread in
                    Text(thread.title).tag(thread.id)
                }
            }
            .pickerStyle(.segmented)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredMessages) { message in
                            ChatMessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
                .onChange(of: filteredMessages.count, initial: false) { _, _ in
                    if let last = filteredMessages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("New thread", text: $newThreadTitle)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let title = newThreadTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !title.isEmpty else { return }
                    onAddThread(title)
                    newThreadTitle = ""
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            ChatInputView(text: $composerText) {
                let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                onSendMessage(text, selectedThreadID)
                composerText = ""
            }
        }
        .navigationTitle("Meeting Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredMessages: [MeetingMessage] {
        messages.filter { $0.threadId == selectedThreadID }
    }
}
