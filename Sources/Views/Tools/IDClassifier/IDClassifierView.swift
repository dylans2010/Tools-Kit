import SwiftUI

struct IDClassifierView: View {
    @StateObject private var cameraService = CameraService()
    @State private var classificationResult = "Point at an ID"
    @State private var extractedFields: [String: String] = [:]
    @State private var isAnalyzing = false

    private let visionService = VisionService.shared

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                CameraPreview(session: cameraService.session)

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

            VStack(spacing: 10) {
                Text(classificationResult)
                    .font(.headline)

                if !extractedFields.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(extractedFields.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text("\(key):").bold()
                                Text(value)
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
                }
            }

            Button(action: captureAndClassify) {
                if isAnalyzing {
                    ProgressView().tint(.white)
                } else {
                    Text("Capture & Classify")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAnalyzing)
        }
        .navigationTitle("ID Classifier")
        .onAppear { cameraService.start() }
        .onDisappear { cameraService.stop() }
    }

    private func captureAndClassify() {
        guard let pixelBuffer = cameraService.currentFrame else { return }
        isAnalyzing = true

        // Convert CVPixelBuffer to UIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            isAnalyzing = false
            return
        }
        let image = UIImage(cgImage: cgImage)

        Task {
            do {
                let type = try await visionService.classifyID(image: image)
                let fields = try await visionService.extractIDFields(image: image)

                await MainActor.run {
                    self.classificationResult = "Detected: \(type)"
                    self.extractedFields = fields
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.classificationResult = "Classification failed"
                    self.isAnalyzing = false
                }
            }
        }
    }
}

struct IDClassifierTool: Tool {
    let name = "ID Classifier"
    let icon = "person.text.rectangle"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Identify passports, licenses, and official documents"
    let requiresAPI = false
    var view: AnyView { AnyView(IDClassifierView()) }
}
