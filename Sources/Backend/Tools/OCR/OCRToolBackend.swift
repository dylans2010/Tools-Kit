import Foundation
import Combine
import SwiftUI

class OCRToolBackend: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isExtracting: Bool = false

    func extractText(from image: UIImage) {
        isExtracting = true
        extractedText = ""

        // Mocking OCR extraction
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.extractedText = "Extracted text: This is a sample OCR result for \(image.description). 123456789."
            self.isExtracting = false
        }
    }
}
