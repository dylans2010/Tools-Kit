import SwiftUI
import VisionKit
import PDFKit
import PencilKit

struct DocumentScannerTool: Tool, Sendable {
    let name = "Document Scanner"
    let icon = "doc.text.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Scan, annotate, and export documents as PDFs"
    let requiresAPI = false
    var view: AnyView { AnyView(DocumentScannerView()) }
}

struct DocumentScannerView: View {
    @StateObject private var backend = DocumentScannerBackend()
    @State private var showingScanner = false

    var body: some View {
        ToolDetailView(tool: DocumentScannerTool()) {
            VStack(spacing: 24) {
                Button(action: { showingScanner = true }) {
                    Label("New Scan", systemImage: "doc.text.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                if backend.savedDocuments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No documents saved yet")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ToolInputSection("Saved Documents") {
                        ForEach(backend.savedDocuments) { doc in
                            NavigationLink(destination: DocumentEditorView(document: doc, backend: backend)) {
                                HStack(spacing: 12) {
                                    if let firstPage = doc.pageImageData.first, let uiImage = UIImage(data: firstPage) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 60)
                                            .cornerRadius(4)
                                            .clipped()
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doc.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("\(doc.pageImageData.count) pages • \(doc.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            Divider()
                        }
                        .onDelete(perform: backend.deleteDocument)
                    }
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            ScannerRepresentable { images in
                backend.addScan(images: images)
                showingScanner = false
            }
        }
    }
}

struct DocumentEditorView: View {
    @State var document: ScannedDocument
    @ObservedObject var backend: DocumentScannerBackend
    @State private var currentPage = 0
    @State private var signatures: [Int: PKDrawing] = [:]

    var body: some View {
        VStack {
            if document.pageImageData.isEmpty {
                Text("No pages in this document.")
            } else {
                TabView(selection: $currentPage) {
                    ForEach(0..<document.pageImageData.count, id: \.self) { index in
                        if let uiImage = UIImage(data: document.pageImageData[index]) {
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                                DrawingView(drawing: Binding(
                                    get: { signatures[index] ?? PKDrawing() },
                                    set: { signatures[index] = $0 }
                                ))
                            }
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }

            HStack(spacing: 20) {
                Button(action: {
                    if let url = backend.exportPDF(document: document) {
                        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let vc = windowScene.windows.first?.rootViewController {
                            vc.present(av, animated: true)
                        }
                    }
                }) {
                    Label("Export PDF", systemImage: "doc.zipper")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(document.title)
        .toolbar {
            Button("Save") {
                backend.updateDocument(document)
            }
        }
    }
}

struct DrawingView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView
        init(_ parent: DrawingView) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
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
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: ([UIImage]) -> Void
        init(completion: @escaping ([UIImage]) -> Void) { self.completion = completion }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount { images.append(scan.imageOfPage(at: i)) }
            completion(images)
        }
    }
}
