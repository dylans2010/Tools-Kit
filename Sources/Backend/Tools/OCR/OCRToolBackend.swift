import Foundation
import SwiftUI
import Vision

class OCRToolBackend: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var extractedText: String = ""
    @Published var isExtracting: Bool = false
    @Published var error: String? = nil

    func extractText() {
        guard let image = selectedImage, let cgImage = image.cgImage else { return }

        isExtracting = true
        extractedText = ""
        error = nil

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isExtracting = false
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            DispatchQueue.main.async {
                self.extractedText = recognizedStrings.joined(separator: "\n")
                self.isExtracting = false
            }
        }

        request.recognitionLevel = .accurate

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isExtracting = false
                }
            }
        }
    }

    func reset() {
        selectedImage = nil
        extractedText = ""
        error = nil
    }
}
