import Foundation
import AVFoundation
import Speech
import Combine
import UIKit

@MainActor
class SpeechSessionManager: NSObject, ObservableObject {
    static let shared = SpeechSessionManager()

    @Published var messages: [SpeechMessage] = []
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var currentTranscription: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var speechState: SpeechState = .idle {
        didSet {
            SDKLogStore.shared.log("Speech State changed to \(speechState.statusText)", source: "SpeechSessionManager", level: .info)
        }
    }
    @Published var errorMessage: String?
    @Published var mode: SpeechSessionMode = .voice {
        didSet {
            SDKLogStore.shared.log("Speech Mode changed to \(mode)", source: "SpeechSessionManager", level: .info)
            handleModeChange()
        }
    }
    @Published var currentSessionID: UUID = UUID()
    private var currentRecordingFeature: SpeechInteractionFeature?
    @Published var continueListeningInBackground: Bool = false {
        didSet {
            UserDefaults.standard.set(continueListeningInBackground, forKey: "continue_listening_in_background")
        }
    }

    let cameraManager = CameraManager()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Stores the latest captured frame data for vision+voice queries
    private var latestFrameData: Data?
    private var levelTimer: Timer?

    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        self.continueListeningInBackground = UserDefaults.standard.bool(forKey: "continue_listening_in_background")
        setupAudioSession()
        setupVisionCallback()
        setupBackgroundObservers()
    }

    private func setupBackgroundObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            if !self.continueListeningInBackground && self.isRecording {
                self.stopRecording()
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            // Optional: Auto-resume if needed, or just stay paused
        }
    }

    private func setupVisionCallback() {
        cameraManager.onFrameCaptured = { [weak self] buffer in
            // Process the frame on a background-safe path, then hop to MainActor
            let frameData = FrameProcessor.process(buffer)
            Task { @MainActor in
                guard let data = frameData else { return }
                self?.latestFrameData = data
                await self?.processVisionFrame(data)
            }
        }
    }

    private func handleModeChange() {
        // Stop any current activities
        stopRecording()
        speechState = .idle
        errorMessage = nil

        if mode == .vision {
            cameraManager.start()
        } else {
            cameraManager.stop()
        }
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])

        // Ensure TTS is synced with settings
        syncWithSettings()
    }

    private func syncWithSettings() {
        // This ensures the singleton instances are reading their latest saved states
        // CloudVisionService and TTSService already have self-loading logic in their init,
        // but we can trigger any re-sync if needed here.
    }

    // MARK: - Recording

    func startRecording() throws {
        try startRecordingWithFeature(nil)
    }

    func startRecordingWithFeature(_ feature: SpeechInteractionFeature?) throws {
        guard !isRecording else { return }

        SDKLogStore.shared.log("Starting recording with feature: \(feature?.rawValue ?? "none")...", source: "SpeechSessionManager", level: .info)
        currentRecordingFeature = feature

        // Stop any current speech
        TTSService.shared.stop()
        isSpeaking = false

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.updateAudioLevel(buffer: buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        speechState = .listening
        currentTranscription = ""

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                Task { @MainActor in
                    self?.currentTranscription = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self?.stopRecordingProcess()
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        SDKLogStore.shared.log("Stopping recording. Transcription: \(currentTranscription)", source: "SpeechSessionManager", level: .info)
        let feature = currentRecordingFeature
        stopRecordingProcess()

        if !currentTranscription.isEmpty {
            let transcription = currentTranscription
            Task {
                await processUserMessage(transcription, feature: feature)
            }
        } else {
            speechState = .idle
        }
    }

    private func stopRecordingProcess() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        currentRecordingFeature = nil
    }

    // MARK: - Send Text Message

    func sendTextMessage(_ text: String) {
        guard !text.isEmpty else { return }
        Task {
            await processUserMessage(text, feature: .textInput)
        }
    }

    // MARK: - Core Message Processing

    private func processUserMessage(_ text: String, feature: SpeechInteractionFeature? = nil) async {
        let isVoiceMode = mode == .voice
        let inputType: SpeechInputType = (feature == .textInput) ? .text : .speech

        let userMessage = SpeechMessage(role: .user, content: text, isSpokenOnly: isVoiceMode)
        messages.append(userMessage)

        isProcessing = true
        speechState = .processing
        errorMessage = nil

        do {
            // Incorporate SpeechSystem.md instructions and interaction context
            let systemInstructions = SpeechSystemInstructions.instructions

            var features: Set<SpeechInteractionFeature> = []
            if let f = feature { features.insert(f) }
            if continueListeningInBackground { features.insert(.backgroundListening) }
            if inputType == .speech { features.insert(.speechInput) }

            let context = SpeechSystemContext(
                activeFeatures: features,
                isInterrupted: feature == .interruptionTrigger,
                inputType: inputType
            )

            let contextString = "\n\nInteraction Context: \(String(describing: context))"

            // Build ChatMessage array for AIService
            var aiMessages = [ChatMessage(role: "system", content: systemInstructions + contextString)]
            aiMessages.append(contentsOf: messages.map { ChatMessage(role: $0.role.rawValue, content: $0.content) })

            // Call AIService — this is the main AI backend
            let response = try await AIService.shared.processMessages(messages: aiMessages)

            // Save to history
            let currentSession = SpeechHistorySession(
                id: currentSessionID,
                title: messages.first?.content.prefix(30).description ?? "New Conversation",
                createdAt: Date(), // This will be overwritten if updating existing, or use a separate field
                messages: messages
            )
            SpeechHistoryManager.shared.saveSession(currentSession)

            guard !response.isEmpty else {
                throw SpeechError.aiServiceError("Received empty response from AI")
            }

            let assistantMessage = SpeechMessage(
                role: .assistant,
                content: response,
                isSpokenOnly: isVoiceMode
            )
            messages.append(assistantMessage)

            isProcessing = false

            // In voice mode or vision mode, speak the response via TTS
            if isVoiceMode || mode == .vision {
                await speak(text: response)
            } else {
                speechState = .idle
            }
        } catch {
            isProcessing = false
            handleError(error)
        }
    }

    // MARK: - Vision Frame Processing

    private func processVisionFrame(_ imageData: Data) async {
        guard mode == .vision, !isProcessing, !CloudVisionService.shared.isProcessing else { return }

        let startTime = CACurrentMediaTime()
        do {
            let response = try await CloudVisionService.shared.analyzeFrame(imageData, history: messages)
            let duration = CACurrentMediaTime() - startTime
            cameraManager.reportProcessingComplete(duration: duration)
            
            if !response.isEmpty {
                let assistantMessage = SpeechMessage(
                    role: .assistant,
                    content: response,
                    isSpokenOnly: false // Automated vision frames are always visible in vision mode
                )
                messages.append(assistantMessage)
                await speak(text: response)
            }
        } catch {
            let duration = CACurrentMediaTime() - startTime
            cameraManager.reportProcessingComplete(duration: duration)
            
            // Log vision errors but don't spam — only show if it's a config issue
            if case VisionError.missingAPIKey = error {
                handleError(SpeechError.missingAPIKey("Vision Provider"))
            } else {
                print("Vision Error: \(error)")
                // Surface the error once, then let it recover
                if errorMessage == nil {
                    handleError(SpeechError.visionError(error.localizedDescription))
                }
            }
        }
    }

    /// Send a user question about the current camera view
    func sendVisionQuestion(_ question: String) {
        guard mode == .vision else { return }
        guard let frameData = latestFrameData else {
            handleError(SpeechError.visionError("No camera frame available"))
            return
        }

        let userMessage = SpeechMessage(role: .user, content: question)
        messages.append(userMessage)

        isProcessing = true
        speechState = .processing
        errorMessage = nil

        Task {
            do {
                let response = try await CloudVisionService.shared.analyzeFrameWithPrompt(frameData, prompt: question, history: messages)

                guard !response.isEmpty else {
                    throw SpeechError.visionError("Empty response from vision service")
                }

                let assistantMessage = SpeechMessage(
                    role: .assistant,
                    content: response,
                    isSpokenOnly: false // Vision mode questions are always visible
                )
                messages.append(assistantMessage)

                isProcessing = false
                await speak(text: response)
            } catch {
                isProcessing = false
                handleError(error)
            }
        }
    }

    // MARK: - TTS (Text-to-Speech via ElevenLabs or Apple)

    func speak(text: String) async {
        guard !text.isEmpty else {
            speechState = .idle
            return
        }

        SDKLogStore.shared.log("Speaking: \(text.prefix(50))...", source: "SpeechSessionManager", level: .info)

        isSpeaking = true
        speechState = .speaking
        startLevelTimer()
        do {
            try await TTSService.shared.speak(text: text)
        } catch {
            print("TTS Error: \(error)")
        }
        isSpeaking = false
        stopLevelTimer()

        // Auto-resume recording if in voice mode
        if mode == .voice && !isRecording {
            speechState = .idle
            // Small delay before auto-listen so the mic doesn't pick up lingering audio
            try? await Task.sleep(nanoseconds: 500_000_000)
            if mode == .voice && !isRecording && !isSpeaking {
                try? startRecording()
            }
        } else {
            speechState = .idle
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        // If it's a TTS failure and fallback is disabled, reveal the text message
        if TTSService.shared.provider == .elevenLabs && !TTSService.shared.useSystemFallback {
            for i in 0..<messages.count {
                if messages[i].role == .assistant && messages[i].isSpokenOnly {
                    let updated = SpeechMessage(
                        id: messages[i].id,
                        role: .assistant,
                        content: messages[i].content,
                        timestamp: messages[i].timestamp,
                        audioURL: messages[i].audioURL,
                        isSpokenOnly: false
                    )
                    messages[i] = updated
                }
            }
        }

        var speechError: SpeechError
        if let se = error as? SpeechError {
            speechError = se
        } else if let ae = error as? AIError {
            switch ae {
            case .missingAPIKey:
                speechError = .missingAIProvider
            case .unknownProvider:
                speechError = .missingAIProvider
            case .networkError(let msg):
                speechError = .aiServiceError(msg)
            case .invalidResponse:
                speechError = .aiServiceError("Invalid response from AI service")
            case .noProviderSelected:
                speechError = .missingAIProvider
            case .noModelSelected:
                speechError = .aiServiceError("No AI model selected. Please choose a model in settings.")
            // --- Additional cases inserted here ---
            case .deviceOffline:
                speechError = .aiServiceError("Device is offline. Check your internet connection.")
            case .invalidEndpoint:
                speechError = .aiServiceError("Invalid API endpoint configuration.")
            case .requestFailed(let msg):
                speechError = .aiServiceError(msg)
            case .decodingFailed:
                speechError = .aiServiceError("Failed to decode response from AI service.")
            }
        } else {
            speechError = .aiServiceError(error.localizedDescription)
        }

        print("Speech Error: \(speechError.errorDescription ?? "Unknown")")

        if mode == .voice {
            // In voice mode, speak the error instead of showing text
            speechState = .error(speechError.spokenMessage)
            errorMessage = speechError.spokenMessage
            Task {
                await speak(text: speechError.spokenMessage)
            }
        } else {
            // In text/vision mode, show the error as a system message
            speechState = .error(speechError.errorDescription ?? "Unknown error")
            errorMessage = speechError.errorDescription

            let errorMsg = SpeechMessage(
                role: .system,
                content: "⚠️ \(speechError.errorDescription ?? "An error occurred")"
            )
            messages.append(errorMsg)

            // Clear error state after delay
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if errorMessage == speechError.errorDescription {
                    errorMessage = nil
                    if case .error = speechState {
                        speechState = .idle
                    }
                }
            }
        }
    }

    // MARK: - Audio Level Metering

    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let channelDataArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)

        var rms: Float = 0
        for i in channelDataArray {
            rms += channelDataValue[i] * channelDataValue[i]
        }
        rms = sqrt(rms / Float(buffer.frameLength))

        let avgPower = 20 * log10(rms)
        let meterLevel = scaledPower(power: avgPower)

        Task { @MainActor in
            self.audioLevel = meterLevel
        }
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

    private func startLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isSpeaking else { return }
                self.audioLevel = TTSService.shared.currentLevel
            }
        }
    }

    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
        Task { @MainActor in
            self.audioLevel = 0
        }
    }

    // MARK: - Reset

    func resetSession() {
        messages = []
        stopRecording()
        cameraManager.stop()
        TTSService.shared.stop()
        isSpeaking = false
        isProcessing = false
        currentTranscription = ""
        speechState = .idle
        errorMessage = nil
        latestFrameData = nil
    }
}
