import SwiftUI
import VisionKit

struct DocumentScannerView: View {
    @State private var showingScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var extractedTexts: [String] = []
    @State private var summary: String = ""
    @State private var isProcessing = false

    private let visionService = VisionService()
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
                List {
                    Section("Scanned Pages") {
                        ForEach(0..<scannedImages.count, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Image(uiImage: scannedImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(8)

                                if index < extractedTexts.count {
                                    Text(extractedTexts[index])
                                        .font(.caption)
                                        .lineLimit(3)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    if !summary.isEmpty {
                        Section("AI Summary") {
                            Text(summary)
                                .font(.body)
                        }
                    }
                }

                if isProcessing {
                    ProgressView("Processing with AI...")
                        .padding()
                } else {
                    HStack(spacing: 20) {
                        Button("Scan More") {
                            showingScanner = true
                        }
                        .buttonStyle(.bordered)

                        Button("Summarize") {
                            Task { await processDocuments() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                HStack {
                    Text("\(scannedImages.count) pages scanned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Clear") {
                        scannedImages = []
                        extractedTexts = []
                        summary = ""
                    }
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
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

    private func processDocuments() async {
        isProcessing = true
        defer { isProcessing = false }

        var allText = ""
        var newTexts: [String] = []

        for image in scannedImages {
            if let text = try? await visionService.performOCR(on: image) {
                newTexts.append(text)
                allText += text + "\n"
            }
        }

        self.extractedTexts = newTexts

        if !allText.isEmpty {
            if let aiSummary = try? await aiService.summarize(text: allText) {
                self.summary = aiSummary
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
    let id = UUID()
    let name = "Doc Scanner"
    let icon = "doc.text.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Scan documents using high-quality camera recognition"
    let requiresAPI = true
    var view: AnyView { AnyView(DocumentScannerView()) }
}
