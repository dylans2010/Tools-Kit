import SwiftUI

enum SpeechFocusMode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case review = "Review"
    case study = "Study"
    case action = "Action"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .standard: return "square.grid.2x2"
        case .review: return "eye"
        case .study: return "book"
        case .action: return "bolt"
        }
    }
}

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
    @State private var focusMode: SpeechFocusMode = .standard
    @State private var isSyncModeEnabled = false
    @State private var dataDensity: Double = 0.5 // 0.0 to 1.0

    // Waveform state
    @State private var waveformLevels: [CGFloat] = Array(repeating: 10, count: 12)
    @State private var timer: Timer?

    var onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dynamicHeader

                adaptiveContent
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { mainToolbarContent }
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
                    processingOverlay
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

    // MARK: - Components

    @ToolbarContentBuilder
    private var mainToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") { dismiss() }
        }

        ToolbarItem(placement: .confirmationAction) {
            exportMenu
        }
    }

    private var dynamicHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if isEditingTitle {
                        TextField("Title", text: $recordingTitle, onCommit: { isEditingTitle = false })
                            .textFieldStyle(.plain)
                            .font(.headline)
                    } else {
                        Text(recordingTitle)
                            .font(.headline)
                            .onTapGesture { isEditingTitle = true }
                    }

                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    Menu {
                        Picker("Focus Mode", selection: $focusMode) {
                            ForEach(SpeechFocusMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                            }
                        }
                    } label: {
                        Image(systemName: focusMode.icon)
                            .font(.title3)
                            .padding(8)
                            .background(Color.accentColor.opacity(0.1), in: Circle())
                    }

                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if focusMode == .standard {
                Picker("View", selection: $selectedTab) {
                    Text("Record").tag(0)
                    Text("Analysis").tag(1)
                    Text("Chat").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var adaptiveContent: some View {
        ZStack {
            if focusMode != .standard {
                focusModeContent
            } else {
                standardTabContent
            }
        }
    }

    private var standardTabContent: some View {
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

    private var focusModeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch focusMode {
                case .review:
                    reviewModeContent
                case .study:
                    studyModeContent
                case .action:
                    actionModeContent
                default:
                    EmptyView()
                }
            }
            .padding()
        }
    }

    private var reviewModeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Review Highlights")
                    .font(.title2.bold())
                Spacer()
                Toggle(isOn: $isSyncModeEnabled) {
                    Label("Sync Playback", systemImage: "clock.arrow.2.circlepath")
                }
                .toggleStyle(.button)
                .controlSize(.small)
            }

            if let analysis = speechManager.analysis {
                ForEach(analysis.highlights) { highlight in
                    HighlightCard(highlight: highlight) {
                        speechManager.seek(to: highlight.startTime)
                        speechManager.startPlayback()
                    }
                    .opacity(!isSyncModeEnabled || (speechManager.playbackProgress >= highlight.startTime && speechManager.playbackProgress <= highlight.endTime) ? 1.0 : 0.5)
                    .scaleEffect(!isSyncModeEnabled || (speechManager.playbackProgress >= highlight.startTime && speechManager.playbackProgress <= highlight.endTime) ? 1.0 : 0.98)
                }
            } else {
                Text("Analyze to see highlights")
            }
        }
    }

    private var studyModeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Learning Insights")
                .font(.title2.bold())

            if let analysis = speechManager.analysis {
                ForEach(analysis.insights) { insight in
                    InsightView(insight: insight)
                }
            }
        }
    }

    private var actionModeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Action Items")
                .font(.title2.bold())

            if let analysis = speechManager.analysis {
                ForEach(analysis.actionItems, id: \.self) { item in
                    HStack {
                        Image(systemName: "circle")
                        Text(item)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var exportMenu: some View {
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

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("AI Is Thinking...")
                    .font(.subheadline.weight(.medium))
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Tabs (Original logic mostly preserved for standard tab)

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
                    .foregroundStyle(Color.accentColor)
                Text("Ready To Record")
                    .font(.headline)
            }

            ScrollView {
                Text(speechManager.transcription.isEmpty ? "Transcription will appear here" : speechManager.transcription)
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
                    suggestionsSection

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

                    summarySection(analysis)
                    keyPointsSection(analysis)
                    insightsSection(analysis)
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

    @ViewBuilder
    private var suggestionsSection: some View {
        if !speechManager.suggestions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(speechManager.suggestions) { suggestion in
                        Button {
                            Task { await speechManager.applySuggestion(suggestion) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.category)
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.accentColor)
                                Text(suggestion.text)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func summarySection(_ analysis: NotebookSpeechAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Summary", systemImage: "text.alignleft")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation {
                        dataDensity = dataDensity > 0.5 ? 0.3 : 0.8
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(dataDensity > 0.5 ? Color.accentColor : .secondary)
                }
            }

            Text(analysis.summary)
                .font(.body)
                .lineLimit(dataDensity < 0.5 ? 3 : nil)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private func keyPointsSection(_ analysis: NotebookSpeechAnalysis) -> some View {
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
    }

    private func insightsSection(_ analysis: NotebookSpeechAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Insights", systemImage: "lightbulb")
                .font(.headline)
            ForEach(analysis.insights) { insight in
                InsightView(insight: insight)
            }
        }
        .padding(.horizontal)
    }

    private var chatTab: some View {
        VStack(spacing: 0) {
            chatMessageList
            Divider()
            chatInputArea
        }
    }

    private var chatMessageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(speechManager.chatHistory) { message in
                        SpeechChatBubble(message: message)
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
    }

    private var chatInputArea: some View {
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

                TextField("Ask Assist", text: $chatInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

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
            Task { @MainActor in
                let isRecording = speechManager.isRecording
                if isRecording {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        for i in 0..<12 {
                            waveformLevels[i] = CGFloat.random(in: 10...60)
                        }
                    }
                } else if waveformLevels.first != 10 {
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

        let recording = NotebookSpeechRecording(
            title: recordingTitle,
            duration: speechManager.playbackDuration,
            audioFilename: url.lastPathComponent,
            transcriptSegments: speechManager.transcriptSegments,
            analysis: speechManager.analysis,
            chatHistory: speechManager.chatHistory,
            tags: speechManager.tags,
            versions: speechManager.versions,
            pins: speechManager.pins,
            executionHistory: speechManager.executionHistory
        )

        historyStore.saveRecording(recording)
    }

    private func loadRecording(_ recording: NotebookSpeechRecording) {
        recordingTitle = recording.title
        speechManager.transcription = recording.analysis?.fullTranscript ?? ""
        speechManager.transcriptSegments = recording.transcriptSegments
        speechManager.analysis = recording.analysis
        speechManager.chatHistory = recording.chatHistory
        speechManager.tags = recording.tags
        speechManager.versions = recording.versions
        speechManager.pins = recording.pins
        speechManager.executionHistory = recording.executionHistory
        speechManager.suggestions = recording.analysis?.suggestions ?? []

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        speechManager.currentRecordingURL = documentsPath.appendingPathComponent(recording.audioFilename)

        selectedTab = 1
    }
}

struct HighlightCard: View {
    let highlight: NotebookSpeechHighlight
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: typeIcon)
                    Text(highlight.type)
                }
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1), in: Capsule())

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.needle")
                    Text("\(Int(highlight.confidence * 100))%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(formatTime(highlight.startTime))
                    .font(.caption.monospacedDigit())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(highlight.title)
                    .font(.headline)

                Text(highlight.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: onTap) {
                    Label("Replay", systemImage: "play.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    // Action: Expand
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button {
                    // Action: Pin
                } label: {
                    Image(systemName: "pin")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.1), lineWidth: 1)
        )
    }

    private var typeIcon: String {
        switch highlight.type.lowercased() {
        case "decision": return "gavel"
        case "insight": return "lightbulb"
        case "task": return "checkmark.circle"
        default: return "sparkles"
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct InsightView: View {
    let insight: NotebookSpeechInsight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insightIcon)
                .foregroundStyle(Color.accentColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.text)
                    .font(.body)
                Text(insight.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var insightIcon: String {
        switch insight.type.lowercased() {
        case "sentiment": return "face.smiling"
        case "intent": return "target"
        default: return "lightbulb"
        }
    }
}

struct SpeechChatBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.role == "user" { Spacer() }

                VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                    if message.role == "user" {
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        SDKMarkdownView(text: message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                .frame(maxWidth: 300, alignment: message.role == "user" ? .trailing : .leading)

                if message.role != "user" { Spacer() }
            }
        }
    }
}
