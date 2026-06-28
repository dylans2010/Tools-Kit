import Foundation
import CoreMedia
import AVFoundation

@MainActor
@Observable
class RecordingSessionManager {
    static let shared = RecordingSessionManager()

    var currentSession: SCKRecordingSession?
    var isRecording = false
    var elapsedTime: TimeInterval = 0

    private var timer: Timer?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?

    func startRecording(featureType: SCKFeatureType) {
        let session = SCKRecordingSession(
            id: UUID(),
            title: "\(featureType.rawValue) Recording - \(Date().formatted())",
            startTime: Date(),
            transcript: [],
            ocrResults: [],
            bookmarks: [],
            tags: [],
            featureType: featureType
        )
        currentSession = session
        isRecording = true
        elapsedTime = 0

        setupAssetWriter(for: session)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }

    func stopRecording() async {
        isRecording = false
        timer?.invalidate()
        timer = nil

        await finalizeAssetWriter()

        if var session = currentSession {
            session.endTime = Date()
            currentSession = session

            // Trigger AI Processing
            await processSessionWithAI()

            // Save to storage
            RecordingStorageManager.shared.saveSession(session)
        }
    }

    func addBookmark(title: String, note: String? = nil) {
        guard isRecording else { return }
        let bookmark = SCKBookmark(
            id: UUID(),
            timestamp: elapsedTime,
            title: title,
            note: note
        )
        currentSession?.bookmarks.append(bookmark)
    }

    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard isRecording, let writer = assetWriter, writer.status == .writing else { return }

        if type == .screen {
            if videoInput?.isReadyForMoreMediaData == true {
                videoInput?.append(sampleBuffer)
            }
        } else if type == .audio {
            if audioInput?.isReadyForMoreMediaData == true {
                audioInput?.append(sampleBuffer)
            }
        }
    }

    private func setupAssetWriter(for session: SCKRecordingSession) {
        let fileURL = RecordingStorageManager.shared.getURL(for: session.id, ext: "mov")
        currentSession?.videoURL = fileURL

        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mov)

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true

            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000
            ]
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true

            if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
                assetWriter?.add(videoInput)
            }
            if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
                assetWriter?.add(audioInput)
            }

            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)
        } catch {
            print("Failed to setup AssetWriter: \(error)")
        }
    }

    private func finalizeAssetWriter() async {
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        await assetWriter?.finishWriting()
        assetWriter = nil
        videoInput = nil
        audioInput = nil
    }

    private func processSessionWithAI() async {
        guard let session = currentSession else { return }

        do {
            let summary = try await SCKSummaryManager.shared.generateSummary(for: session)
            let actionItems = try await SCKSummaryManager.shared.extractActionItems(for: session)

            currentSession?.summary = summary
            currentSession?.actionItems = actionItems

            // Generate Workspace Assets
            try await SCKWorkspaceGenerator.shared.generateAssets(for: session)
        } catch {
            print("AI Processing failed: \(error)")
        }
    }
}
