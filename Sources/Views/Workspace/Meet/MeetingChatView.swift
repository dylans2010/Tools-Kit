import SwiftUI

struct MeetingChatView: View {
    let threads: [MeetingChatThread]
    let messages: [MeetingMessage]
    let isChatEnabled: Bool
    let onAddThread: (String) -> Void
    let onSendMessage: (String, String) -> Void

    @State private var selectedThreadID: String?
    @State private var composerText = ""
    @State private var newThreadTitle = ""

    var body: some View {
        VStack(spacing: 12) {
            if threads.isEmpty {
                ContentUnavailableView(
                    "No chat threads from Daily",
                    systemImage: "message.badge",
                    description: Text("Threads appear only when received from live session events.")
                )
            } else {
                Picker("Thread", selection: selectedThreadBinding(defaultID: threads[0].id)) {
                    ForEach(threads) { thread in
                        Text(thread.title).tag(thread.id)
                    }
                }
                .pickerStyle(.segmented)
            }

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
                .disabled(threads.isEmpty || !isChatEnabled)
            }
            .padding(.horizontal)
            if !isChatEnabled {
                Text("Chat is disabled by an admin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            ChatInputView(text: $composerText, isEnabled: isChatEnabled) {
                let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                guard let selectedThreadID else { return }
                onSendMessage(text, selectedThreadID)
                composerText = ""
            }
        }
        .navigationTitle("Meeting Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ensureSelectedThreadIsValid(for: threadIDs)
        }
        .onChange(of: threadIDs, initial: false) { _, ids in
            ensureSelectedThreadIsValid(for: ids)
        }
    }

    private var filteredMessages: [MeetingMessage] {
        guard let selectedThreadID else { return [] }
        return messages.filter { $0.threadId == selectedThreadID }
    }

    private func selectedThreadBinding(defaultID: String) -> Binding<String> {
        Binding<String>(
            get: { selectedThreadID ?? defaultID },
            set: { selectedThreadID = $0 }
        )
    }

    private var threadIDs: [String] {
        threads.map(\.id)
    }

    private func ensureSelectedThreadIsValid(for ids: [String]) {
        if let selectedThreadID, ids.contains(selectedThreadID) {
            return
        }
        selectedThreadID = ids.first
    }
}
