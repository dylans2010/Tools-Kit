import Foundation
import PDFKit

class PDFToolsBackend: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String? = nil
    @Published var outputURL: URL? = nil

    func merge(pdfURLs: [URL], reverseOrder: Bool = false) {
        guard !pdfURLs.isEmpty else { return }
        isProcessing = true
        error = nil
        outputURL = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let outPDF = PDFDocument()
            var pageIndex = 0

            for url in (reverseOrder ? pdfURLs.reversed() : pdfURLs) {
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

    func extract(pageRange: ClosedRange<Int>, from url: URL) {
        isProcessing = true
        error = nil
        outputURL = nil
        DispatchQueue.global(qos: .userInitiated).async {
            guard let source = PDFDocument(url: url) else {
                DispatchQueue.main.async {
                    self.error = "Failed to load source PDF"
                    self.isProcessing = false
                }
                return
            }
            let output = PDFDocument()
            var insertIndex = 0
            for pageNumber in pageRange where pageNumber > 0 && pageNumber <= source.pageCount {
                if let page = source.page(at: pageNumber - 1) {
                    output.insert(page, at: insertIndex)
                    insertIndex += 1
                }
            }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("extracted_\(UUID().uuidString).pdf")
            if output.write(to: tempURL) {
                DispatchQueue.main.async {
                    self.outputURL = tempURL
                    self.isProcessing = false
                }
            } else {
                DispatchQueue.main.async {
                    self.error = "Failed to extract pages"
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
