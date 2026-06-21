import SwiftUI

struct SpeechMainView: View {
    @StateObject private var sessionManager = SpeechSessionManager.shared
    @State private var textInput: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(sessionManager.messages) { message in
                            SpeechMessageBubble(message: message)
                                .id(message.id)
                        }

                        if sessionManager.isProcessing {
                            HStack {
                                TypingIndicator()
                                    .padding(.horizontal)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: sessionManager.messages) { _ in
                    if let lastMessage = sessionManager.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Audio Level / Transcription Area
            if sessionManager.isRecording {
                VStack(spacing: 8) {
                    AudioLevelIndicator(level: sessionManager.audioLevel)
                        .frame(height: 40)

                    Text(sessionManager.currentTranscription.isEmpty ? "Listening..." : sessionManager.currentTranscription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground).shadow(radius: 2))
            }

            // Input Area
            HStack(spacing: 12) {
                // Mode Toggle
                Button(action: {
                    withAnimation {
                        sessionManager.mode = sessionManager.mode == .voice ? .text : .voice
                        if sessionManager.mode == .text {
                            sessionManager.stopRecording()
                        }
                    }
                }) {
                    Image(systemName: sessionManager.mode == .voice ? "mic.fill" : "keyboard")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }

                if sessionManager.mode == .text {
                    TextField("Type a message...", text: $textInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .disabled(textInput.isEmpty)
                } else {
                    Button(action: {
                        if sessionManager.isRecording {
                            sessionManager.stopRecording()
                        } else {
                            try? sessionManager.startRecording()
                        }
                    }) {
                        Text(sessionManager.isRecording ? "Stop Recording" : "Tap to Speak")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(sessionManager.isRecording ? Color.red : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .navigationTitle("AI Speech")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SpeechSettingsView()) {
                    Image(systemName: "gear")
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button("Reset") {
                    sessionManager.resetSession()
                }
            }
        }
    }

    private func sendMessage() {
        sessionManager.sendTextMessage(textInput)
        textInput = ""
        isTextFieldFocused = false
    }
}

struct SpeechMessageBubble: View {
    let message: SpeechMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .bottom) {
                    if message.role == .assistant {
                        Button(action: {
                            Task {
                                await SpeechSessionManager.shared.speak(text: message.content)
                            }
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.bottom, 10)
                    }

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
            }

            if message.role == .assistant { Spacer() }
        }
    }
}

struct AudioLevelIndicator: View {
    let level: Float

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(Double(level) > Double(index) / 10.0 ? 1.0 : 0.2))
                    .frame(width: 6, height: 10 + (20 * CGFloat(sin(Double(index) * 0.5 + Date().timeIntervalSince1970 * 5))))
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .offset(y: dotOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: dotOffset
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(15)
        .onAppear {
            dotOffset = -5
        }
    }
}
