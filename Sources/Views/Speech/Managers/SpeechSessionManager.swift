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

    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        setupAudioSession()
        setupVisionCallback()
    }

    private func setupVisionCallback() {
        cameraManager.onFrameCaptured = { [weak self] buffer in
            Task { @MainActor in
                await self?.processVisionFrame(buffer)
            }
        }
    }

    private func handleModeChange() {
        if mode == .vision {
            cameraManager.start()
        } else {
            cameraManager.stop()
        }

        if mode == .text {
            stopRecording()
        }
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
    }

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
            Task {
                await processUserMessage(currentTranscription)
            }
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

    func sendTextMessage(_ text: String) {
        guard !text.isEmpty else { return }
        Task {
            await processUserMessage(text)
        }
    }

    private func processUserMessage(_ text: String) async {
        let userMessage = SpeechMessage(role: .user, content: text)
        messages.append(userMessage)

        isProcessing = true

        do {
            let aiMessages = messages.map { ChatMessage(role: $0.role.rawValue, content: $0.content) }
            let response = try await AIService.shared.processMessages(messages: aiMessages)

            let assistantMessage = SpeechMessage(role: .assistant, content: response)
            messages.append(assistantMessage)

            isProcessing = false

            if mode == .voice {
                await speak(text: response)
            }
        } catch {
            print("Speech Session Error: \(error)")
            isProcessing = false
        }
    }

    func speak(text: String) async {
        isSpeaking = true
        do {
            try await TTSService.shared.speak(text: text)
        } catch {
            print("TTS Error: \(error)")
        }
        isSpeaking = false

        // Auto-resume recording if in voice mode and not text-switching
        if mode == .voice && !isRecording {
            try? startRecording()
        }
    }

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

    private func processVisionFrame(_ buffer: CMSampleBuffer) async {
        guard mode == .vision, !isProcessing, !VisionService.shared.isProcessing else { return }

        guard let imageData = FrameProcessor.process(buffer) else { return }

        do {
            let response = try await VisionService.shared.analyzeFrame(imageData, history: messages)
            if !response.isEmpty {
                let assistantMessage = SpeechMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
                await speak(text: response)
            }
        } catch {
            print("Vision Error: \(error)")
        }
    }

    func resetSession() {
        messages = []
        stopRecording()
        cameraManager.stop()
        TTSService.shared.stop()
        isSpeaking = false
        isProcessing = false
        currentTranscription = ""
    }
}
