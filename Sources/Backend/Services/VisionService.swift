import Vision
import UIKit

class VisionService {
    nonisolated(unsafe) static let shared = VisionService()

    func performOCR(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func detectObjects(in pixelBuffer: CVPixelBuffer) async throws -> [VNRecognizedObjectObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeAnimalsRequest { request, error in // Example, generic object detection often needs a CoreML model
                 // For built-in Vision without custom models, we use specific requests or VNDetectRectanglesRequest etc.
                 // For now, let's assume we want VNDetectBarcodesRequest for QR and others.
            }
            // Realistically, for generic object detection, we'd load a CoreML model here.
            continuation.resume(returning: [])
        }
    }

    func scanBarcodes(in pixelBuffer: CVPixelBuffer) async throws -> [VNBarcodeObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNBarcodeObservation] ?? []
                continuation.resume(returning: observations)
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
