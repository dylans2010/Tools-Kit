#if canImport(ScreenCaptureKit)

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
    @State private var sessionManager = RecordingSessionManager.shared
    @State private var searchText = ""

    var filteredResults: [SCKOCRResult] {
        guard let results = sessionManager.currentSession?.ocrResults else { return [] }
        if searchText.isEmpty {
            return results.sorted(by: { $0.timestamp > $1.timestamp })
        }
        return results.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }

    var body: some View {
        List {
            if sessionManager.isRecording {
                Section {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        VStack(alignment: .leading) {
                            Text("Scanning Screen...")
                                .font(.headline)
                            Text("Detecting text in real-time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                if filteredResults.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Text Detected" : "No Matches Found",
                        systemImage: "text.viewfinder",
                        description: Text(searchText.isEmpty ? "Start recording to detect text on your screen." : "Try a different search term.")
                    )
                } else {
                    ForEach(filteredResults) { result in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(formatTime(result.timestamp))
                                    .font(.caption.monospacedDigit())
                                    .padding(4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Spacer()

                                Text(String(format: "%.1f%%", result.confidence * 100))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text(result.text)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                UIPasteboard.general.string = result.text
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Detected Text")
            }
        }
        .navigationTitle("OCR Scanner")
        .searchable(text: $searchText, prompt: "Search detected text")
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#endif
