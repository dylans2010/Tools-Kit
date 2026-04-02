import Foundation
import PDFKit

class PDFToolsBackend: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String? = nil
    @Published var outputURL: URL? = nil

    func merge(pdfURLs: [URL]) {
        guard !pdfURLs.isEmpty else { return }
        isProcessing = true
        error = nil
        outputURL = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let outPDF = PDFDocument()
            var pageIndex = 0

            for url in pdfURLs {
                if let pdf = PDFDocument(url: url) {
                    for i in 0..<pdf.pageCount {
                        if let page = pdf.page(at: i) {
                            outPDF.insert(page, at: pageIndex)
                            pageIndex += 1
                        }
                    }
                }
            }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("merged_\(UUID().uuidString).pdf")
            if outPDF.write(to: tempURL) {
                DispatchQueue.main.async {
                    self.outputURL = tempURL
                    self.isProcessing = false
                }
            } else {
                DispatchQueue.main.async {
                    self.error = "Failed to create merged PDF"
                    self.isProcessing = false
                }
            }
        }
    }

    func reset() {
        outputURL = nil
        error = nil
    }
}
