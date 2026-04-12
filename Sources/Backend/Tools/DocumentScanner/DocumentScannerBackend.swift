import Foundation
import UIKit
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

final class DocumentScannerBackend: ObservableObject {
    @Published var savedDocuments: [ScannedDocument] = []
    @Published var isProcessing = false

    init() {
        loadFromDisk()
    }

    func addScan(images: [UIImage]) {
        let data = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        let newDoc = ScannedDocument(title: "Scan \(savedDocuments.count + 1)", pageImageData: data)
        savedDocuments.insert(newDoc, at: 0)
        saveToDisk()
    }

    func updateDocument(_ updated: ScannedDocument) {
        if let idx = savedDocuments.firstIndex(where: { $0.id == updated.id }) {
            savedDocuments[idx] = updated
            saveToDisk()
        }
    }

    func deleteDocument(at offsets: IndexSet) {
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

    func exportPDF(document: ScannedDocument) -> URL? {
        let pdfDocument = PDFDocument()
        for data in document.pageImageData {
            if let image = UIImage(data: data), let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: pdfDocument.pageCount)
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(document.title).pdf")
        pdfDocument.write(to: tempURL)
        return tempURL
    }
}
