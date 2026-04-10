import Foundation
import Vision
import UIKit

class OCRService {
    static let shared = OCRService()

    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "OCRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func recognizeStructuredText(in image: UIImage) async throws -> [String: Any] {
        let text = try await recognizeText(in: image)
        // In a real implementation, we could use AIService to structure this text
        return ["rawText": text]
    }
}
