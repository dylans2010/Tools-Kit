import Foundation
import AVFoundation
import Speech

@MainActor
class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcription: String = ""
    @Published var isRecording: Bool = false
    @Published var permissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var micPermission: Bool = false

    // Playback state
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: TimeInterval = 0
    @Published var playbackDuration: TimeInterval = 0

    // Transcription segments
    @Published var transcriptSegments: [SpeechTranscriptSegment] = []

    // AI State
    @Published var analysis: SpeechAnalysis?
    @Published var chatHistory: [ChatMessage] = []
    @Published var isProcessingAI: Bool = false

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
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
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
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }

    func stopRecording() {
        stopRecordingProcess()
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
        transcription = ""
        transcriptSegments = []
        currentRecordingURL = nil
        analysis = nil
        chatHistory = []
    }

    // MARK: - Playback

    func startPlayback(url: URL? = nil) {
        let playbackURL = url ?? currentRecordingURL
        guard let url = playbackURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
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

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.playbackProgress = self.audioPlayer?.currentTime ?? 0
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

    // MARK: - AI Analysis

    func performStructuredAnalysis() async {
        guard !transcription.isEmpty else { return }
        isProcessingAI = true

        let schema = """
        {
            "summary": "String",
            "keyPoints": ["String"],
            "actionItems": ["String"],
            "topics": [
                {
                    "title": "String",
                    "startTime": "Number (seconds)",
                    "endTime": "Number (seconds)"
                }
            ]
        }
        """

        let prompt = """
        Analyze the following transcript from a speech recording.
        Provide a concise summary, key points, action items, and segment the transcript into topics with timestamps.
        The recording duration is \(playbackDuration) seconds.

        Transcript:
        \(transcription)
        """

        do {
            let jsonString = try await AIService.shared.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
            if let data = jsonString.data(using: String.Encoding.utf8) {
                let decoded = try JSONDecoder().decode(SpeechAnalysis.self, from: data)
                self.analysis = decoded
                self.analysis?.fullTranscript = transcription
            }
        } catch {
            print("AI Analysis error: \(error)")
        }

        isProcessingAI = false
    }

    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        chatHistory.append(userMessage)

        isProcessingAI = true

        let systemPrompt = """
        You are a helpful assistant analyzing a speech recording.
        Reference the transcript and analysis provided.
        If the user asks about specific moments, refer to the transcript segments and timestamps.

        Transcript:
        \(transcription)

        Analysis:
        \(analysis?.summary ?? "None")
        """

        do {
            let response = try await AIService.shared.processMessages(messages: chatHistory, model: nil)
            let aiMessage = ChatMessage(role: "assistant", content: response)
            chatHistory.append(aiMessage)
        } catch {
            print("AI Chat error: \(error)")
        }

        isProcessingAI = false
    }
}
