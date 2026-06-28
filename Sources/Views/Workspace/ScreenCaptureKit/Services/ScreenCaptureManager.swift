import Foundation
import ScreenCaptureKit
import CoreMedia

@available(iOS 27.0, *)
@MainActor
@Observable
class ScreenCaptureManager: NSObject, SCStreamOutput, SCStreamDelegate {
    static let shared = ScreenCaptureManager()

    var isCapturing = false
    var stream: SCStream?
    var filter: SCContentFilter?

    private let picker = SCContentSharingPicker.shared

    override init() {
        super.init()
        setupPicker()
    }

    private func setupPicker() {
        picker.isActive = true
        picker.add(self)
        // Set default configuration for the picker if needed
    }

    func presentPicker() {
        picker.present()
    }

    func startCapture(with filter: SCContentFilter) async throws {
        self.filter = filter

        let config = SCStreamConfiguration()
        config.width = 1920
        config.height = 1080
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = false

        stream = SCStream(filter: filter, configuration: config, delegate: self)

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))

        try await stream?.startCapture()
        isCapturing = true
    }

    func stopCapture() async throws {
        try await stream?.stopCapture()
        isCapturing = false
        stream = nil
    }

    // MARK: - SCStreamOutput

    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Route sample buffers to OCR and Transcript managers
        Task { @MainActor in
            if type == .screen {
                SCKOCRManager.shared.processFrame(sampleBuffer)
            } else if type == .audio {
                SCKTranscriptManager.shared.processAudio(sampleBuffer)
            }

            // Also send to RecordingSessionManager for file recording
            RecordingSessionManager.shared.processSampleBuffer(sampleBuffer, of: type)
        }
    }

    // MARK: - SCStreamDelegate

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            isCapturing = false
            // Handle error (e.g., notify RecordingSessionManager)
        }
    }
}

@available(iOS 27.0, *)
extension ScreenCaptureManager: SCContentSharingPickerObserver {
    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        // Handle cancel
    }

    func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        Task {
            if let stream = stream {
                #if os(macOS)
                try? await stream.updateContentFilter(filter)
                #endif
            } else {
                try? await startCapture(with: filter)
            }
        }
    }

    func contentSharingPickerStartDidFailWithError(_ error: Error) {
        // Handle error
    }
}
