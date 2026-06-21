import SwiftUI

struct SpeechTranscriptView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var sessionManager = SpeechSessionManager.shared
    @StateObject private var historyManager = SpeechHistoryManager.shared
    @State private var textInput: String = ""
    @State private var showHistory = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sessionManager.messages) { message in
                                TranscriptBubble(message: message)
                                    .id(message.id)
                            }

                            if sessionManager.isProcessing {
                                HStack {
                                    TypingIndicator()
                                        .padding(.leading)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: sessionManager.messages) { _ in
                        if let last = sessionManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Area
                HStack(spacing: 12) {
                    TextField("Message", text: $textInput)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($isFocused)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(textInput.isEmpty ? .gray : .accentColor)
                    }
                    .disabled(textInput.isEmpty || sessionManager.isProcessing)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                SpeechHistoryView()
            }
        }
    }

    private func sendMessage() {
        guard !textInput.isEmpty else { return }
        let text = textInput
        textInput = ""
        sessionManager.sendTextMessage(text)
    }
}

struct TranscriptBubble: View {
    let message: SpeechMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let markdown = try? AttributedString(markdown: message.content, options: .init(allowsExtendedAttributes: true, interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedAttributedString)) {
                    Text(markdown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(message.role == .user ? Color.accentColor : Color(.systemGray5))
                        .foregroundColor(message.role == .user ? .white : .primary)
                        .cornerRadius(18)
                } else {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(message.role == .user ? Color.accentColor : Color(.systemGray5))
                        .foregroundColor(message.role == .user ? .white : .primary)
                        .cornerRadius(18)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.role != .user { Spacer() }
        }
    }
}

struct SpeechHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var historyManager = SpeechHistoryManager.shared
    @State private var editingSessionID: UUID?
    @State private var newTitle: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(historyManager.history) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            if editingSessionID == session.id {
                                TextField("Session Title", text: $newTitle, onCommit: {
                                    historyManager.renameSession(id: session.id, newTitle: newTitle)
                                    editingSessionID = nil
                                })
                                .textFieldStyle(.roundedBorder)
                            } else {
                                Text(session.title)
                                    .font(.headline)
                                Text("\(session.messages.count) messages • \(session.createdAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            SpeechSessionManager.shared.messages = session.messages
                            SpeechSessionManager.shared.currentSessionID = session.id
                            dismiss()
                        }) {
                            Image(systemName: "arrow.up.right.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            historyManager.deleteSession(id: session.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            editingSessionID = session.id
                            newTitle = session.title
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
