import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

final class VideoCompressorBackend: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0

    func compressVideo(at url: URL) async throws -> URL {
        await MainActor.run { isProcessing = true; progress = 0 }

        let asset = AVAsset(url: url)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw NSError(domain: "VideoCompressor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                continuation.resume()
            }
        }

        await MainActor.run { isProcessing = false }
        return outputURL
    }
}
