import SwiftUI
import Vision

struct LiveTextView: View {
    @StateObject private var scanner = LiveTextScanner()
    @StateObject private var cameraService = CameraService()
    @State private var isScanning = false

    var body: some View {
        VStack {
            ZStack {
                CameraPreview(cameraService: cameraService)
                    .onAppear {
                        cameraService.delegate = scanner
                        cameraService.startSession()
                    }
                    .onDisappear {
                        cameraService.stopSession()
                    }

                if !scanner.extractedText.isEmpty {
                    VStack {
                        Spacer()
                        ScrollView {
                            Text(scanner.extractedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .padding()

            HStack {
                Button(isScanning ? "Stop Scanning" : "Start Live Text") {
                    isScanning.toggle()
                    scanner.isScanning = isScanning
                }
                .buttonStyle(.borderedProminent)

                Button("Copy") { UIPasteboard.general.string = scanner.extractedText }
                    .buttonStyle(.bordered)
                    .disabled(scanner.extractedText.isEmpty)

                Button("Clear") { scanner.extractedText = "" }
                    .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Live Text")
    }
}

class LiveTextScanner: NSObject, ObservableObject, CameraServiceDelegate {
    @Published var extractedText = ""
    var isScanning = false

    func didOutput(pixelBuffer: CVPixelBuffer) {
        guard isScanning else { return }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }

            DispatchQueue.main.async {
                self?.extractedText = recognizedStrings.joined(separator: "\n")
            }
        }

        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

struct LiveTextTool: Tool {
    let name = "Live Text"
    let icon = "text.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Real-time text extraction from live camera feed"
    let requiresAPI = false
    var view: AnyView { AnyView(LiveTextView()) }
}
