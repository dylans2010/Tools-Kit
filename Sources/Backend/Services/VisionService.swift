import Foundation
import Vision
import CoreImage
import UIKit

class VisionService {
    static let shared = VisionService()

    func detectObjects(in pixelBuffer: CVPixelBuffer) async throws -> [VNRecognizedObjectObservation] {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        // Use standard Vision request for object detection
        // On iOS 17+, we can use VNDetectObjectsRequest
        // For iOS 16, we use the specific requests if models are provided,
        // but here we'll use a standard VNDetectBarcodesRequest or similar if no custom model is bundled.
        // Since we MUST have real logic, we'll perform a text recognition as a fallback 'object' if no model.
        // Actually, we can use the built-in saliency request to detect 'interesting' areas as objects.

        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        try requestHandler.perform([request])

        guard let result = request.results?.first else { return [] }

        // Map saliency results to observations for visualization
        let observations = result.salientObjects?.map { salientObject in
            VNRecognizedObjectObservation(
                boundingBox: salientObject.boundingBox,
                confidence: 1.0,
                labels: [VNClassificationObservation(identifier: "Object", confidence: 1.0)]
            )
        } ?? []

        return observations
    }

    func classifyID(image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw NSError(domain: "VisionService", code: -1, userInfo: nil) }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        try requestHandler.perform([request])

        guard let results = request.results as? [VNRecognizedTextObservation] else { return "Unknown" }

        let fullText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ").uppercased()

        if fullText.contains("PASSPORT") { return "Passport" }
        if fullText.contains("DRIVER LICENSE") || fullText.contains("DL") { return "Driver's License" }
        if fullText.contains("IDENTITY CARD") || fullText.contains("ID CARD") { return "ID Card" }

        return "Document"
    }

    func extractIDFields(image: UIImage) async throws -> [String: String] {
        guard let cgImage = image.cgImage else { throw NSError(domain: "VisionService", code: -1, userInfo: nil) }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        try requestHandler.perform([request])

        guard let results = request.results as? [VNRecognizedTextObservation] else { return [:] }

        let textLines = results.compactMap { $0.topCandidates(1).first?.string }
        var fields: [String: String] = [:]

        for line in textLines {
            if line.contains("Name:") || line.hasPrefix("FN") || line.contains("Given Name") {
                fields["Name"] = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? line
            }
            if let dateRange = line.range(of: "\\d{2}[/-]\\d{2}[/-]\\d{4}", options: .regularExpression) {
                fields["Date"] = String(line[dateRange])
            }
            if let idRange = line.range(of: "[A-Z0-9]{8,}", options: .regularExpression) {
                fields["ID Number"] = String(line[idRange])
            }
        }

        return fields
    }
}
