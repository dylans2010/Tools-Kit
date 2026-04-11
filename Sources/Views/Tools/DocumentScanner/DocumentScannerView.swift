import SwiftUI
import VisionKit
import PDFKit
import PencilKit

struct ScannedDocument: Identifiable, Codable {
    let id: UUID
    var title: String
    var pageImageData: [Data]
    var createdAt: Date

    init(id: UUID = UUID(), title: String, pageImageData: [Data], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.pageImageData = pageImageData
        self.createdAt = createdAt
    }
}

struct DocumentScannerView: View {
    @State private var showingScanner = false
    @State private var savedDocuments: [ScannedDocument] = []
    @State private var selectedDocument: ScannedDocument? = nil

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Capture multiple pages, organize them into documents, and use advanced tools like signatures and PDF exporting.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: { showingScanner = true }) {
                        Label("New Scan", systemImage: "doc.text.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Capture")
            }

            Section {
                if savedDocuments.isEmpty {
                    Text("No documents saved yet.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(savedDocuments) { doc in
                        NavigationLink(destination: DocumentEditorView(document: doc, onSave: { updated in
                            if let idx = savedDocuments.firstIndex(where: { $0.id == updated.id }) {
                                savedDocuments[idx] = updated
                                saveToDisk()
                            }
                        })) {
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
                                    Text("\(doc.pageImageData.count) pages • \(doc.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteDocument)
                }
            } header: {
                Text("Saved Documents")
            }
        }
        .navigationTitle("Doc Scanner")
        .sheet(isPresented: $showingScanner) {
            ScannerRepresentable { images in
                let data = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
                let newDoc = ScannedDocument(title: "Scan \(savedDocuments.count + 1)", pageImageData: data)
                savedDocuments.insert(newDoc, at: 0)
                saveToDisk()
                showingScanner = false
            }
        }
        .onAppear { loadFromDisk() }
    }

    private func deleteDocument(at offsets: IndexSet) {
        savedDocuments.remove(atOffsets: offsets)
        saveToDisk()
    }

    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(savedDocuments) {
            UserDefaults.standard.set(encoded, forKey: "scanned_documents_v2")
        }
    }

    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "scanned_documents_v2"),
           let decoded = try? JSONDecoder().decode([ScannedDocument].self, from: data) {
            savedDocuments = decoded
        }
    }
}

struct DocumentEditorView: View {
    @State var document: ScannedDocument
    let onSave: (ScannedDocument) -> Void
    @State private var currentPage = 0
    @State private var showingSignature = false
    @State private var canvasView = PKCanvasView()
    @State private var signatures: [Int: [PKDrawing]] = [:] // Page index to drawings

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
                                    get: { signatures[index]?.first ?? PKDrawing() },
                                    set: { signatures[index] = [$0] }
                                ))
                            }
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }

            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    Button(action: { showingSignature.toggle() }) {
                        Label("Sign", systemImage: "pencil.tip.crop.circle")
                    }
                    .buttonStyle(.bordered)

                    Button(action: exportPDF) {
                        Label("Export PDF", systemImage: "doc.zipper")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    // In a real app, we'd burn the signatures into the images
                    onSave(document)
                }
            }
        }
    }

    func exportPDF() {
        let pdfDocument = PDFDocument()
        for data in document.pageImageData {
            if let image = UIImage(data: data), let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: pdfDocument.pageCount)
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(document.title).pdf")
        pdfDocument.write(to: tempURL)

        let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let vc = UIApplication.shared.windows.first?.rootViewController {
            vc.present(av, animated: true)
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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

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
