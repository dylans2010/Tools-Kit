import Foundation
import Speech
import CoreMedia
import AVFoundation

@available(iOS 27.0, *)
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
        if let pcmBuffer = sampleBufferToPCMBuffer(sampleBuffer) {
            recognitionRequest?.append(pcmBuffer)
        }
    }

    private func sampleBufferToPCMBuffer(_ sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee else {
            return nil
        }

        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?

        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        let commonFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: asbd.mSampleRate, channels: asbd.mChannelsPerFrame, interleaved: false)

        guard let format = commonFormat,
              let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        pcmBuffer.frameLength = frameCount

        // This is a simplified conversion, actual implementation might need more complex handling of different formats
        return pcmBuffer
    }
}
