import Foundation
class PDFToolsBackend: ObservableObject {
    @Published var isProcessing = false
    func merge(pdfURLs: [URL]) { isProcessing = true; DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.isProcessing = false } }
}
