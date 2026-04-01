import Foundation
import SwiftUI
class ImageProcessorBackend: ObservableObject {
    @Published var isProcessing = false
    func compressImage(_ image: UIImage) { isProcessing = true; DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.isProcessing = false } }
}
