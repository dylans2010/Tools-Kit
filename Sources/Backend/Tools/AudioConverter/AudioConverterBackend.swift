import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

final class AudioConverterBackend: ObservableObject {
    @Published var isProcessing = false
    @Published var status: String = ""

    func convertToM4A(inputURL: URL) async throws -> URL {
        await MainActor.run { isProcessing = true; status = "Starting conversion..." }

        let asset = AVAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioConverter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                continuation.resume()
            }
        }

        await MainActor.run { isProcessing = false; status = "Conversion complete" }
        return outputURL
    }
}
