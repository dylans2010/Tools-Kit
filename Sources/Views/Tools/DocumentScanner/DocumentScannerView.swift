import SwiftUI
import VisionKit

struct DocumentScannerView: View {
    @State private var showingScanner = false
    @State private var scannedImages: [UIImage] = []

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
                    ForEach(scannedImages, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    }
                }

                Button("Scan More") {
                    showingScanner = true
                }
                .padding()
                HStack {
                    Text("\(scannedImages.count) pages scanned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Clear") { scannedImages = [] }
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
