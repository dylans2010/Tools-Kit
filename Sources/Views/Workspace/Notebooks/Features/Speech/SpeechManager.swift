import Foundation
import AVFoundation
import Speech

@MainActor
class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcription: String = ""
    @Published var isRecording: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var permissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var micPermission: Bool = false

    // Playback state
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: TimeInterval = 0
    @Published var playbackDuration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var isSilenceSkippingEnabled: Bool = false
    @Published var isFillerSkippingEnabled: Bool = false

    // Transcription segments
    @Published var transcriptSegments: [SpeechTranscriptSegment] = []

    // AI State
    @Published var analysis: SpeechAnalysis?
    @Published var chatHistory: [ChatMessage] = []
    @Published var isProcessingAI: Bool = false
    @Published var isLiveEnhancing: Bool = false

    // Advanced Intelligence State
    @Published var currentVersion: UUID?
    @Published var versions: [SpeechVersion] = []
    @Published var pins: [ContextMemoryPin] = []
    @Published var tags: [SpeechTag] = []
    @Published var executionHistory: [PromptExecutionRecord] = []
    @Published var suggestions: [SmartSuggestion] = []

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // Audio recording for playback
    private var audioRecorder: AVAudioRecorder?
    var currentRecordingURL: URL?

    // Audio player
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var enhancementTimer: Timer?

    override init() {
        super.init()
        speechRecognizer?.delegate = self
        checkPermissions()
    }

    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.permissionStatus = status
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            Task { @MainActor in
                self.micPermission = granted
            }
        }
    }

    func startRecording() throws {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        transcriptSegments = []
        transcription = ""
        analysis = nil
        chatHistory = []
        suggestions = []
        versions = []
        pins = []
        tags = []
        executionHistory = []

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Setup file recording
        let fileName = "recording-\(UUID().uuidString).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        currentRecordingURL = documentsPath.appendingPathComponent(fileName)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: currentRecordingURL!, settings: settings)
        audioRecorder?.record()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("DEBUG: Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                Task { @MainActor in
                    self.transcription = result.bestTranscription.formattedString
                    self.transcriptSegments = result.bestTranscription.segments.map { segment in
                        SpeechTranscriptSegment(
                            startTime: segment.timestamp,
                            endTime: segment.timestamp + segment.duration,
                            text: segment.substring
                        )
                    }
                }
            }

            if error != nil || result?.isFinal == true {
                self.stopRecordingProcess()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)

            // Calculate audio level
            guard let channelData = buffer.floatChannelData else { return }
            let channelDataValue = channelData.pointee
            let channelDataArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)

            var rms: Float = 0
            for i in channelDataArray {
                rms += channelDataValue[i] * channelDataValue[i]
            }
            rms = sqrt(rms / Float(buffer.frameLength))

            let avgPower = 20 * log10(rms)
            let meterLevel = self.scaledPower(power: avgPower)

            Task { @MainActor in
                self.audioLevel = meterLevel
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }

    func stopRecording() {
        stopRecordingProcess()
        startLiveEnhancement()
    }

    private func stopRecordingProcess() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }

        audioRecorder?.stop()
        isRecording = false

        recognitionRequest = nil
        recognitionTask = nil
    }

    func reset() {
        stopRecording()
        stopPlayback()
        stopLiveEnhancement()
        transcription = ""
        transcriptSegments = []
        currentRecordingURL = nil
        analysis = nil
        chatHistory = []
        suggestions = []
        versions = []
        pins = []
        tags = []
        executionHistory = []
    }

    // MARK: - Playback

    func startPlayback(url: URL? = nil) {
        let playbackURL = url ?? currentRecordingURL
        guard let url = playbackURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackRate
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            playbackDuration = audioPlayer?.duration ?? 0

            startPlaybackTimer()
        } catch {
            print("Playback error: \(error)")
        }
    }

    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackTimer()
    }

    func resumePlayback() {
        audioPlayer?.rate = playbackRate
        audioPlayer?.play()
        isPlaying = true
        startPlaybackTimer()
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        playbackProgress = 0
        stopPlaybackTimer()
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        playbackProgress = time
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
    }

    func toggleSilenceSkipping() {
        isSilenceSkippingEnabled.toggle()
    }

    func toggleFillerSkipping() {
        isFillerSkippingEnabled.toggle()
    }

    func jumpToNextHighlight() {
        guard let analysis = analysis else { return }
        let nextHighlight = analysis.highlights
            .filter { $0.startTime > playbackProgress }
            .sorted { $0.startTime < $1.startTime }
            .first

        if let highlight = nextHighlight {
            seek(to: highlight.startTime)
        }
    }

    func jumpToPreviousHighlight() {
        guard let analysis = analysis else { return }
        let prevHighlight = analysis.highlights
            .filter { $0.startTime < playbackProgress - 2 } // Small buffer
            .sorted { $0.startTime > $1.startTime }
            .first

        if let highlight = prevHighlight {
            seek(to: highlight.startTime)
        }
    }

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                guard let player = self.audioPlayer else { return }
                self.playbackProgress = player.currentTime

                if self.isSilenceSkippingEnabled {
                    
                }

                if self.playbackProgress >= self.playbackDuration {
                    self.stopPlayback()
                }
            }
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: - AI Analysis & Audio Intelligence Layer

    func performStructuredAnalysis() async {
        guard !transcription.isEmpty else { return }
        isProcessingAI = true

        let schema = """
        {
            "summary": "String",
            "keyPoints": ["String"],
            "actionItems": ["String"],
            "topics": [
                { "title": "String", "startTime": "Number", "endTime": "Number" }
            ],
            "insights": [
                { "text": "String", "type": "String", "importance": "Number", "sourceSegmentIds": ["UUID"] }
            ],
            "highlights": [
                { "title": "String", "summary": "String", "startTime": "Number", "endTime": "Number", "confidence": "Number", "type": "String" }
            ],
            "suggestions": [
                { "text": "String", "action": "String", "category": "String" }
            ],
            "sentiment": "String",
            "intentClassification": "String",
            "priorityScore": "Number"
        }
        """

        let prompt = """
        Analyze this transcript deeply. Provide:
        1. Concise summary, key points, action items.
        2. Segment into topics.
        3. Extract deep insights (semantic tagging).
        4. Detect key moments (highlights) with confidence and type.
        5. Detect sentiment and intent.
        6. Provide 3 smart suggestions for follow-up.
        7. Assign a priority score (1-100).

        Transcript:
        \(transcription)
        """

        do {
            let jsonString = try await AIService.shared.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
            if let data = jsonString.data(using: String.Encoding.utf8) {
                let decoded = try JSONDecoder().decode(SpeechAnalysis.self, from: data)
                self.analysis = decoded
                self.analysis?.fullTranscript = transcription
                self.suggestions = decoded.suggestions

                // Save initial version
                saveVersion(name: "Initial Analysis")
            }
        } catch {
            print("AI Analysis error: \(error)")
        }

        isProcessingAI = false
    }

    func startLiveEnhancement() {
        isLiveEnhancing = true
        enhancementTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performBackgroundEnrichment()
            }
        }
    }

    func stopLiveEnhancement() {
        isLiveEnhancing = false
        enhancementTimer?.invalidate()
        enhancementTimer = nil
    }

    private func performBackgroundEnrichment() async {
        guard analysis != nil, !transcription.isEmpty else { return }

        // Deep enrichment for sentiment, intent, and recurring themes
        let prompt = "Refine the current analysis for this recording. Look for deeper semantic connections, subtle sentiment shifts, and missed action items. Current Summary: \(analysis?.summary ?? "")"

        do {
            // Simplified for background - just update suggestions and insights
            let result = try await AIService.shared.processMessages(messages: [ChatMessage(role: "user", content: prompt)], model: nil)
            // Update suggestions based on refinement
            print("Background enhancement completed")
        } catch {
            print("Background enhancement error: \(error)")
        }
    }

    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }

        // Slash command handling
        if text.starts(with: "/") {
            await handleSlashCommand(text)
            return
        }

        let userMessage = ChatMessage(role: "user", content: text)
        chatHistory.append(userMessage)

        isProcessingAI = true

        let systemPrompt = """
        You are a highly advanced AI analyzing speech recordings.
        Reference transcript, analysis, insights, and highlights.
        Use Markdown formatting. Provide source mapping (timestamps) where possible.

        Transcript: \(transcription)
        Analysis: \(analysis?.summary ?? "None")
        Insights: \(analysis?.insights.map { $0.text }.joined(separator: ", ") ?? "None")
        """

        do {
            let response = try await AIService.shared.processMessages(messages: chatHistory, model: nil)
            let aiMessage = ChatMessage(role: "assistant", content: response)
            chatHistory.append(aiMessage)

            // Record execution
            executionHistory.append(PromptExecutionRecord(prompt: text, response: response))
        } catch {
            print("AI Chat error: \(error)")
        }

        isProcessingAI = false
    }

    private func handleSlashCommand(_ command: String) async {
        let cmd = command.lowercased()
        if cmd == "/summarize" {
            await sendMessage("Summarize this recording.")
        } else if cmd == "/tasks" {
            await sendMessage("Extract all tasks and action items.")
        } else if cmd == "/highlights" {
            await sendMessage("Identify the top 5 highlights.")
        } else if cmd == "/chain" {
            await runAutomationChain(["Summarize", "Extract Tasks", "Draft Email"])
        } else if cmd == "/export" {
            await sendMessage("Format everything for export as a professional report.")
        }
    }

    // MARK: - Advanced Logic (Step 3 & 4)

    func detectIncompleteIdeas() async {
        let prompt = "Analyze the transcript for incomplete ideas, unanswered questions, or ambiguous statements. Transcript: \(transcription)"
        do {
            let result = try await AIService.shared.processMessages(messages: [ChatMessage(role: "user", content: prompt)], model: nil)
            // Add to suggestions
            let suggestion = SmartSuggestion(text: "Unanswered Questions detected", action: "Review unanswered questions: \(result)", category: "Follow-up")
            self.suggestions.append(suggestion)
        } catch {
            print("Incomplete ideas detection error: \(error)")
        }
    }

    func runAutomationChain(_ actions: [String]) async {
        for action in actions {
            await sendMessage("Step in chain: \(action)")
        }
    }

    func generateProactiveSuggestions() async {
        guard !transcription.isEmpty else { return }
        let prompt = "Based on the transcript, suggest 3 highly relevant follow-up actions. Transcript: \(transcription)"
        do {
            let schema = """
            { "suggestions": [ { "text": "String", "action": "String", "category": "String" } ] }
            """
            let jsonString = try await AIService.shared.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
            if let data = jsonString.data(using: .utf8) {
                let decoded = try JSONDecoder().decode([String: [SmartSuggestion]].self, from: data)
                if let newSuggestions = decoded["suggestions"] {
                    self.suggestions.append(contentsOf: newSuggestions)
                }
            }
        } catch {
            print("Proactive suggestions error: \(error) ")
        }
    }

    func saveVersion(name: String) {
        let version = SpeechVersion(name: name, transcript: transcription, analysis: analysis, parentId: currentVersion)
        versions.append(version)
        currentVersion = version.id
    }

    func restoreVersion(_ version: SpeechVersion) {
        transcription = version.transcript
        analysis = version.analysis
        currentVersion = version.id
    }

    func branchVersion(name: String, from versionId: UUID) {
        if let parent = versions.first(where: { $0.id == versionId }) {
            let branchedVersion = SpeechVersion(name: name, transcript: parent.transcript, analysis: parent.analysis, parentId: versionId)
            versions.append(branchedVersion)
            currentVersion = branchedVersion.id
        }
    }

    func pinItem(content: String, type: String) {
        pins.append(ContextMemoryPin(content: content, type: type))
    }

    func applySuggestion(_ suggestion: SmartSuggestion) async {
        await sendMessage(suggestion.action)
    }

    func getSessionIntelligence() -> [SmartSuggestion] {
        // Return suggestions based on unfinished tasks or recent history
        return suggestions
    }

    private func scaledPower(power: Float) -> Float {
        guard power.isFinite else { return 0.0 }
        if power < -60.0 {
            return 0.0
        } else if power >= 0.0 {
            return 1.0
        } else {
            return (abs(-60.0) - abs(power)) / abs(-60.0)
        }
    }
}
