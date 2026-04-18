import SwiftUI
import Daily

struct MeetingChatView: View {
    let threads: [MeetingChatThread]
    let messages: [MeetingMessage]
    let onAddThread: (String) -> Void
    let onSendMessage: (String, String) -> Void

    @State private var selectedThreadID = "general"
    @State private var composerText = ""
    @State private var newThreadTitle = ""

    var body: some View {
        VStack(spacing: 10) {
            Picker("Thread", selection: $selectedThreadID) {
                ForEach(threads) { thread in
                    Text(thread.title).tag(thread.id)
                }
            }
            .pickerStyle(.segmented)

            List(filteredMessages) { message in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.senderName)
                            .font(.caption.bold())
                            .foregroundColor(message.isSystem ? .orange : .primary)
                        Spacer()
                        Text(message.sentAt, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(message.text)
                        .font(.subheadline)
                }
            }

            HStack {
                TextField("New thread", text: $newThreadTitle)
                Button("Add") {
                    let title = newThreadTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !title.isEmpty else { return }
                    onAddThread(title)
                    newThreadTitle = ""
                }
            }

            HStack {
                TextField("Message", text: $composerText)
                Button("Send") {
                    let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    onSendMessage(text, selectedThreadID)
                    composerText = ""
                }
            }
        }
        .padding(.horizontal)
        .navigationTitle("Meeting Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredMessages: [MeetingMessage] {
        messages.filter { $0.threadId == selectedThreadID }
    }
}
