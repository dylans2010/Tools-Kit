import Foundation
import AVFoundation

#if canImport(Speech)
import Speech
#endif

@MainActor
final class MealVoiceService: NSObject, ObservableObject {
    @Published var transcription: String = ""
    @Published var isRecording: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var errorMessage: String?

    #if canImport(Speech)
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    #endif

    func requestPermissions() async {
        let micGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        #if canImport(Speech)
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        permissionGranted = micGranted && speechStatus == .authorized
        #else
        permissionGranted = micGranted
        #endif
    }

    func startRecording() {
        guard permissionGranted else {
            errorMessage = "Microphone and speech permissions are required."
            return
        }
        errorMessage = nil

        #if canImport(Speech)
        recognitionTask?.cancel()
        recognitionTask = nil

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true

            recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    self.transcription = self.cleanTranscription(result.bestTranscription.formattedString)
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                }
            }
        } catch {
            errorMessage = "Unable to start recording: \(error.localizedDescription)"
            stopRecording()
        }
        #else
        isRecording = true
        #endif
    }

    func stopRecording() {
        #if canImport(Speech)
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        #endif
        isRecording = false
    }

    func reset() {
        stopRecording()
        transcription = ""
        errorMessage = nil
    }

    func cleanedOutput() -> String {
        cleanTranscription(transcription)
    }

    private func cleanTranscription(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "i had", with: "")
            .replacingOccurrences(of: "and", with: ",")
            .components(separatedBy: CharacterSet(charactersIn: ",."))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
