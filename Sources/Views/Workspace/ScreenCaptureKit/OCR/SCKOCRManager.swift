import Foundation
import Vision
import CoreMedia

@available(iOS 27.0, *)
@MainActor
@Observable
class SCKOCRManager {
    static let shared = SCKOCRManager()

    private var lastOCRTime: TimeInterval = 0
    private let ocrInterval: TimeInterval = 1.0 // 1 second interval

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        let currentTime = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))

        guard currentTime - lastOCRTime >= ocrInterval else { return }
        lastOCRTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }

            Task { @MainActor in
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let result = SCKOCRResult(
                        id: UUID(),
                        timestamp: currentTime,
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                    RecordingSessionManager.shared.currentSession?.ocrResults.append(result)
                }
            }
        }

        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

import SwiftUI

@available(iOS 27.0, *)
struct OCRScannerView: View {
    var body: some View {
        Text("OCR Scanner View")
            .navigationTitle("OCR Scanner")
    }
}
