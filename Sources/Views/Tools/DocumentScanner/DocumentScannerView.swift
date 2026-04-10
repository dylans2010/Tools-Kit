import SwiftUI
import VisionKit

struct DocumentScannerView: View {
    @State private var showingScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var summary = ""

    private let ocrService = OCRService.shared
    private let aiService = AIService()

    var body: some View {
        VStack {
            if scannedImages.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("No documents scanned yet")
                        .foregroundColor(.secondary)
                    Button("Start Scanning") {
                        showingScanner = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(scannedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                        }

                        HStack {
                            Button("Scan More") { showingScanner = true }
                                .buttonStyle(.bordered)
                            Spacer()
                            Button("Clear All") {
                                scannedImages = []
                                recognizedText = ""
                                summary = ""
                            }
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)

                        Divider()

                        Button(action: processDocuments) {
                            if isProcessing {
                                ProgressView().tint(.white)
                            } else {
                                Label("OCR & AI Summarize", systemImage: "sparkles")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)

                        if !summary.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("AI Summary").font(.headline)
                                Text(summary)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            .padding()
                        }

                        if !recognizedText.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recognized Text").font(.headline)
                                Text(recognizedText)
                                    .font(.caption)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .navigationTitle("Document Scanner")
        .sheet(isPresented: $showingScanner) {
            ScannerRepresentable { images in
                self.scannedImages.append(contentsOf: images)
                showingScanner = false
            }
        }
    }

    private func processDocuments() {
        guard !scannedImages.isEmpty else { return }
        isProcessing = true

        Task {
            var fullText = ""
            for image in scannedImages {
                if let text = try? await ocrService.recognizeText(in: image) {
                    fullText += text + "\n\n"
                }
            }

            await MainActor.run {
                self.recognizedText = fullText
            }

            let prompt = "Summarize the following scanned document text and extract key information:\n\n\(fullText)"
            let request = AIRequest(
                prompt: prompt,
                systemPrompt: "You are a document analysis assistant. Provide clear summaries and extract structured data from OCR text.",
                model: "google/gemini-2.0-flash-exp:free",
                attachments: nil
            )

            if let result = try? await aiService.process(request: request) {
                await MainActor.run {
                    self.summary = result
                    self.isProcessing = false
                }
            } else {
                await MainActor.run { self.isProcessing = false }
            }
        }
    }
}

struct ScannerRepresentable: UIViewControllerRepresentable {
    let completion: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: ([UIImage]) -> Void

        init(completion: @escaping ([UIImage]) -> Void) {
            self.completion = completion
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            completion(images)
        }
    }
}

struct DocumentScannerTool: Tool {
    let name = "Doc Scanner"
    let icon = "doc.text.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Scan documents using high-quality camera recognition"
    let requiresAPI = false
    var view: AnyView { AnyView(DocumentScannerView()) }
}
