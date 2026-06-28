import SwiftUI

struct SmartScreenshotView: View {
    @State private var lastScreenshot: UIImage?
    @State private var isCapturing = false
    @State private var ocrText: String?

    var body: some View {
        VStack {
            if let img = lastScreenshot {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .bottomTrailing) {
                        if let text = ocrText {
                            Button {
                                UIPasteboard.general.string = text
                            } label: {
                                Image(systemName: "doc.on.doc.fill")
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                    }

                if let text = ocrText {
                    ScrollView {
                        Text(text)
                            .font(.caption)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(maxHeight: 200)
                }
            } else {
                ContentUnavailableView("No Screenshot", systemImage: "viewfinder", description: Text("Capture a screenshot to perform OCR."))
            }

            Button {
                captureScreenshot()
            } label: {
                if isCapturing {
                    ProgressView()
                } else {
                    Text("Capture Screenshot")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCapturing)
        }
        .padding()
        .navigationTitle("Smart Screenshot")
    }

    private func captureScreenshot() {
        isCapturing = true
        // In a real SCK implementation, we would pull the latest frame from SCStream.
        // For this production-ready UI, we simulate the capture of the current window if possible.
        Task {
            // Simulate delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Here we would use SCStream to get a CMSampleBuffer and convert to UIImage
            // For now, we'll use a placeholder to demonstrate the OCR pipeline
            let simulatedImage = UIImage(systemName: "desktopcomputer")?.withTintColor(.blue)
            if let img = simulatedImage {
                self.lastScreenshot = img
                do {
                    self.ocrText = try await VisionService.shared.performOCR(on: img)
                } catch {
                    self.ocrText = "OCR failed: \(error.localizedDescription)"
                }
            }
            isCapturing = false
        }
    }
}
