import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

final class LiveTextBackend: NSObject, ObservableObject, CameraServiceDelegate {
    @Published var recognizedText: String = ""
    @Published var isProcessing = false

    func didOutput(pixelBuffer: CVPixelBuffer) {
        // Live text recognition logic
    }

    func recognizeText(from image: UIImage) async {
        await MainActor.run { isProcessing = true }

        guard let cgImage = image.cgImage else { return }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

            DispatchQueue.main.async {
                self.recognizedText = text
                self.isProcessing = false
            }
        }

        request.recognitionLevel = .accurate
        try? requestHandler.perform([request])
    }
}
