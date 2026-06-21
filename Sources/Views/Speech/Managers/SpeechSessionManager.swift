import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
class SpeechSessionManager: NSObject, ObservableObject {
    static let shared = SpeechSessionManager()

    @Published var messages: [SpeechMessage] = []
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var currentTranscription: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var speechState: SpeechState = .idle
    @Published var errorMessage: String?
    @Published var mode: SpeechSessionMode = .voice {
        didSet {
            handleModeChange()
        }
    }

    let cameraManager = CameraManager()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Stores the latest captured frame data for vision+voice queries
    private var latestFrameData: Data?

    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        setupAudioSession()
        setupVisionCallback()
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
    }

    // MARK: - Recording

    func startRecording() throws {
        guard !isRecording else { return }

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
        stopRecordingProcess()

        if !currentTranscription.isEmpty {
            let transcription = currentTranscription
            Task {
                await processUserMessage(transcription)
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
    }

    // MARK: - Send Text Message

    func sendTextMessage(_ text: String) {
        guard !text.isEmpty else { return }
        Task {
            await processUserMessage(text)
        }
    }

    // MARK: - Core Message Processing

    private func processUserMessage(_ text: String) async {
        let userMessage = SpeechMessage(role: .user, content: text)
        messages.append(userMessage)

        isProcessing = true
        speechState = .processing
        errorMessage = nil

        do {
            // Build ChatMessage array for AIService
            let aiMessages = messages.map { ChatMessage(role: $0.role.rawValue, content: $0.content) }

            // Call AIService — this is the main AI backend
            let response = try await AIService.shared.processMessages(messages: aiMessages)

            guard !response.isEmpty else {
                throw SpeechError.aiServiceError("Received empty response from AI")
            }

            let assistantMessage = SpeechMessage(role: .assistant, content: response)
            messages.append(assistantMessage)

            isProcessing = false

            // In voice mode, speak the response via TTS (ElevenLabs or Apple)
            if mode == .voice || mode == .vision {
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
                let assistantMessage = SpeechMessage(role: .assistant, content: response)
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

                let assistantMessage = SpeechMessage(role: .assistant, content: response)
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
        isSpeaking = true
        speechState = .speaking
        do {
            try await TTSService.shared.speak(text: text)
        } catch {
            print("TTS Error: \(error)")
            // Don't escalate TTS errors to the user in voice mode —
            // the response is already in the chat as text
        }
        isSpeaking = false

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
        let speechError: SpeechError
        if let se = error as? SpeechError {
            speechError = se
        } else if let ae = error as? AIError {
            switch ae {
            case .missingAPIKey:
                speechError = .missingAIProvider
            case .unknownProvider(let p):
                speechError = .missingAIProvider
            case .networkError(let msg):
                speechError = .aiServiceError(msg)
            case .invalidResponse:
                speechError = .aiServiceError("Invalid response from AI service")
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
                // Try to speak the error using Apple TTS (fallback, more reliable)
                let utterance = AVSpeechUtterance(string: speechError.spokenMessage)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterance)

                // Wait a moment then reset state
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if case .error = speechState {
                    speechState = .idle
                }
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
