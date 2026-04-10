import SwiftUI
import Vision

struct IDClassifierView: View {
    @StateObject private var classifier = IDClassifier()
    @StateObject private var cameraService = CameraService()

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                CameraPreview(cameraService: cameraService)
                    .onAppear {
                        cameraService.delegate = classifier
                        cameraService.startSession()
                    }
                    .onDisappear {
                        cameraService.stopSession()
                    }

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 300, height: 200)

                Text("Align ID Card Here")
                    .foregroundColor(.white)
                    .offset(y: 120)
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            .cornerRadius(12)
            .padding()

            VStack(alignment: .leading, spacing: 10) {
                Text(classifier.idType)
                    .font(.headline)
                    .foregroundColor(.blue)

                Divider()

                Group {
                    IDInfoRow(label: "Name", value: classifier.extractedName)
                    IDInfoRow(label: "DOB", value: classifier.extractedDOB)
                    IDInfoRow(label: "ID Number", value: classifier.extractedIDNumber)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding()

            Spacer()
        }
        .navigationTitle("ID Classifier")
    }
}

struct IDInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.bold)
            Spacer()
            Text(value.isEmpty ? "Searching..." : value)
                .foregroundColor(value.isEmpty ? .secondary : .primary)
        }
    }
}

class IDClassifier: NSObject, ObservableObject, CameraServiceDelegate {
    @Published var idType = "Scanning ID..."
    @Published var extractedName = ""
    @Published var extractedDOB = ""
    @Published var extractedIDNumber = ""

    func didOutput(pixelBuffer: CVPixelBuffer) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            let texts = observations.compactMap { $0.topCandidates(1).first?.string }
            self?.processTexts(texts)
        }

        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    private func processTexts(_ texts: [String]) {
        DispatchQueue.main.async {
            // Identify ID Type
            if texts.contains(where: { $0.localizedCaseInsensitiveContains("PASSPORT") }) {
                self.idType = "Detected: Passport"
            } else if texts.contains(where: { $0.localizedCaseInsensitiveContains("LICENSE") || $0.localizedCaseInsensitiveContains("DRIVING") }) {
                self.idType = "Detected: Driver License"
            }

            // Very simple regex-based extraction for demonstration
            for text in texts {
                // Name usually appears in ALL CAPS or specific patterns, hard to genericize without model
                // For now, let's look for common patterns

                // DOB: looking for date patterns like DD/MM/YYYY or MM/DD/YYYY
                if self.extractedDOB.isEmpty {
                    let dobPattern = #"\b\d{2}[/-]\d{2}[/-]\d{4}\b"#
                    if let range = text.range(of: dobPattern, options: .regularExpression) {
                        self.extractedDOB = String(text[range])
                    }
                }

                // ID Number: looking for alphanumeric strings of 8+ chars
                if self.extractedIDNumber.isEmpty {
                    let idPattern = #"\b[A-Z0-9]{8,12}\b"#
                    if let range = text.range(of: idPattern, options: .regularExpression), !text.localizedCaseInsensitiveContains("PASSPORT"), !text.localizedCaseInsensitiveContains("LICENSE") {
                        self.extractedIDNumber = String(text[range])
                    }
                }
            }

            // Name is hardest; usually it's one of the first few lines that isn't a title
            if self.extractedName.isEmpty && texts.count > 2 {
                for i in 0..<min(3, texts.count) {
                    if !texts[i].localizedCaseInsensitiveContains("PASSPORT") &&
                       !texts[i].localizedCaseInsensitiveContains("REPUBLIC") &&
                       !texts[i].localizedCaseInsensitiveContains("IDENTITY") {
                        self.extractedName = texts[i]
                        break
                    }
                }
            }
        }
    }
}

struct IDClassifierTool: Tool {
    let id = UUID()
    let requiresAPI = false
    let name = "ID Classifier"
    let icon = "person.text.rectangle"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Identify passports, licenses, and official documents"
    var view: AnyView { AnyView(IDClassifierView()) }
}
