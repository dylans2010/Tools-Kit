import SwiftUI

struct SpeechNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var historyStore = SpeechHistoryStore.shared

    @State private var selectedTab = 0
    @State private var showingHistory = false
    @State private var showingPrompts = false
    @State private var chatInput = ""
    @State private var recordingTitle = "New Recording"
    @State private var isEditingTitle = false

    // Waveform state
    @State private var waveformLevels: [CGFloat] = Array(repeating: 10, count: 12)
    @State private var timer: Timer?

    var onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Recording Title
                HStack {
                    if isEditingTitle {
                        TextField("Title", text: $recordingTitle, onCommit: { isEditingTitle = false })
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(recordingTitle)
                            .font(.headline)
                            .onTapGesture { isEditingTitle = true }
                    }

                    Spacer()

                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                    }
                }
                .padding()

                // Tabs
                Picker("View", selection: $selectedTab) {
                    Text("Record").tag(0)
                    Text("Analysis").tag(1)
                    Text("Chat").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom)

                ZStack {
                    switch selectedTab {
                    case 0:
                        recordingTab
                    case 1:
                        analysisTab
                    case 2:
                        chatTab
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Speech Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button {
                            saveCurrentRecording()
                        } label: {
                            Label("Save to History", systemImage: "tray.and.arrow.down")
                        }

                        Button {
                            onComplete(speechManager.transcription)
                            dismiss()
                        } label: {
                            Label("Insert Transcript", systemImage: "doc.append")
                        }

                        if let analysis = speechManager.analysis {
                            Button {
                                onComplete(analysis.summary)
                                dismiss()
                            } label: {
                                Label("Insert Summary", systemImage: "text.alignleft")
                            }

                            Button {
                                let tasks = analysis.actionItems.map { "- [ ] \($0)" }.joined(separator: "\n")
                                onComplete(tasks)
                                dismiss()
                            } label: {
                                Label("Insert Action Items", systemImage: "checkmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                SpeechHistoryView { recording in
                    loadRecording(recording)
                }
            }
            .sheet(isPresented: $showingPrompts) {
                SpeechPresetPromptsSheet { prompt in
                    chatInput = prompt
                    Task {
                        await speechManager.sendMessage(prompt)
                        chatInput = ""
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .overlay {
                if speechManager.isProcessingAI {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("AI is thinking...")
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .onAppear {
                startWaveformTimer()
            }
            .onDisappear {
                stopWaveformTimer()
            }
        }
    }

    // MARK: - Tabs

    private var recordingTab: some View {
        VStack(spacing: 24) {
            Spacer()

            if speechManager.isRecording {
                waveformView
                Text("Listening...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else if speechManager.isPlaying {
                playbackView
            } else {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.accent)
                Text("Ready to Record")
                    .font(.headline)
            }

            ScrollView {
                Text(speechManager.transcription.isEmpty ? "Transcription will appear here..." : speechManager.transcription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundStyle(speechManager.transcription.isEmpty ? .secondary : .primary)
            }
            .frame(maxHeight: 250)

            Spacer()

            HStack(spacing: 40) {
                if !speechManager.transcription.isEmpty && !speechManager.isRecording {
                    Button {
                        if speechManager.isPlaying {
                            speechManager.stopPlayback()
                        } else {
                            speechManager.startPlayback()
                        }
                    } label: {
                        Image(systemName: speechManager.isPlaying ? "stop.fill" : "play.fill")
                            .font(.title)
                            .padding()
                            .background(Color.accentColor.opacity(0.1), in: Circle())
                    }
                }

                recordButton

                if !speechManager.transcription.isEmpty && !speechManager.isRecording {
                    Button {
                        Task {
                            await speechManager.performStructuredAnalysis()
                            selectedTab = 1
                        }
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.title)
                            .padding()
                            .background(Color.accentColor.opacity(0.1), in: Circle())
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    private var analysisTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let analysis = speechManager.analysis {
                    if !analysis.topics.isEmpty {
                        SpeechTimelineView(
                            topics: analysis.topics,
                            currentProgress: speechManager.playbackProgress,
                            duration: speechManager.playbackDuration
                        ) { time in
                            speechManager.seek(to: time)
                            speechManager.startPlayback()
                            selectedTab = 0
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Summary", systemImage: "text.alignleft")
                            .font(.headline)
                        Text(analysis.summary)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Key Points", systemImage: "list.bullet")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analysis.keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•").foregroundColor(.accentColor)
                                    Text(point)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Action Items", systemImage: "checkmark.circle")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analysis.actionItems, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "square")
                                        .foregroundColor(.secondary)
                                    Text(item)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                } else {
                    ContentUnavailableView(
                        "No Analysis",
                        systemImage: "sparkles",
                        description: Text("Analyze your recording to see summary, key points, and topics.")
                    )
                    .padding(.top, 40)

                    Button("Analyze Now") {
                        Task { await speechManager.performStructuredAnalysis() }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical)
        }
    }

    private var chatTab: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(speechManager.chatHistory) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: speechManager.chatHistory.count) { _, _ in
                    if let last = speechManager.chatHistory.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            VStack(spacing: 12) {
                HStack {
                    Button {
                        showingPrompts = true
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                            .padding(8)
                            .background(Color.accentColor.opacity(0.1), in: Circle())
                    }

                    TextField("Ask about the recording...", text: $chatInput)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        let text = chatInput
                        chatInput = ""
                        Task { await speechManager.sendMessage(text) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(chatInput.isEmpty || speechManager.isProcessingAI)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private var recordButton: some View {
        Button {
            if speechManager.isRecording {
                speechManager.stopRecording()
            } else {
                do {
                    try speechManager.startRecording()
                } catch {
                    print("Error starting recording: \(error)")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(speechManager.isRecording ? .red : .accentColor)
                    .frame(width: 70, height: 70)

                if speechManager.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
            }
            .shadow(radius: 5)
        }
    }

    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<12) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 4, height: waveformLevels[i])
            }
        }
        .frame(height: 60)
    }

    private var playbackView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    if speechManager.isPlaying {
                        speechManager.pausePlayback()
                    } else {
                        speechManager.resumePlayback()
                    }
                } label: {
                    Image(systemName: speechManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }

                Slider(value: Binding(get: {
                    speechManager.playbackProgress
                }, set: {
                    speechManager.seek(to: $0)
                }), in: 0...speechManager.playbackDuration)

                Text(formatTime(speechManager.playbackProgress))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
        }
    }

    private func startWaveformTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if speechManager.isRecording {
                withAnimation(.easeInOut(duration: 0.1)) {
                    for i in 0..<12 {
                        waveformLevels[i] = CGFloat.random(in: 10...60)
                    }
                }
            } else {
                if waveformLevels.first != 10 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        waveformLevels = Array(repeating: 10, count: 12)
                    }
                }
            }
        }
    }

    private func stopWaveformTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func saveCurrentRecording() {
        guard !speechManager.transcription.isEmpty, let url = speechManager.currentRecordingURL else { return }

        let recording = SpeechRecording(
            title: recordingTitle,
            duration: speechManager.playbackDuration,
            audioFilename: url.lastPathComponent,
            transcriptSegments: speechManager.transcriptSegments,
            analysis: speechManager.analysis,
            chatHistory: speechManager.chatHistory
        )

        historyStore.saveRecording(recording)
    }

    private func loadRecording(_ recording: SpeechRecording) {
        recordingTitle = recording.title
        speechManager.transcription = recording.analysis?.fullTranscript ?? ""
        speechManager.transcriptSegments = recording.transcriptSegments
        speechManager.analysis = recording.analysis
        speechManager.chatHistory = recording.chatHistory

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        speechManager.currentRecordingURL = documentsPath.appendingPathComponent(recording.audioFilename)

        selectedTab = 1
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }

            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    message.role == "user" ?
                    Color.accentColor :
                    Color(.secondarySystemBackground)
                )
                .foregroundColor(message.role == "user" ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: 280, alignment: message.role == "user" ? .trailing : .leading)

            if message.role != "user" { Spacer() }
        }
    }
}
