import Foundation
import Speech
import CoreMedia

@MainActor
@Observable
class SCKTranscriptManager {
    static let shared = SCKTranscriptManager()

    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startTranscription() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let result = result else { return }

            Task { @MainActor in
                let text = result.bestTranscription.formattedString
                let timestamp = RecordingSessionManager.shared.elapsedTime
                let segment = SCKTranscriptSegment(
                    id: UUID(),
                    timestamp: timestamp,
                    text: text,
                    speaker: "User"
                )

                // For real-time, we might want to update the last segment instead of appending constantly
                if var last = RecordingSessionManager.shared.currentSession?.transcript.last,
                   timestamp - last.timestamp < 2.0 {
                    RecordingSessionManager.shared.currentSession?.transcript[RecordingSessionManager.shared.currentSession!.transcript.count - 1] = SCKTranscriptSegment(id: last.id, timestamp: last.timestamp, text: text, speaker: "User")
                } else {
                    RecordingSessionManager.shared.currentSession?.transcript.append(segment)
                }
            }
        }
    }

    func stopTranscription() {
        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil
    }

    func processAudio(_ sampleBuffer: CMSampleBuffer) {
        recognitionRequest?.append(sampleBuffer)
    }
}
