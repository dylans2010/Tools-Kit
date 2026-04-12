import Foundation
import Vision
import UIKit

final class ObjectDetectionBackend: NSObject, ObservableObject, CameraServiceDelegate {
    @Published var detectedObjects: [String] = []

    func didOutput(pixelBuffer: CVPixelBuffer) {
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let observations = request.results as? [VNClassificationObservation] else { return }
            let topObjects = observations.prefix(5)
                .filter { $0.confidence > 0.5 }
                .map { "\($0.identifier) (\(Int($0.confidence * 100))%)" }

            DispatchQueue.main.async {
                self?.detectedObjects = topObjects
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    func detectObjects(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let observations = request.results as? [VNClassificationObservation] else { return }
            let topObjects = observations.prefix(5).map { $0.identifier }
            DispatchQueue.main.async { self?.detectedObjects = topObjects }
        }
        try? VNImageRequestHandler(cgImage: cgImage).perform([request])
    }
}
