import Foundation
import SwiftUI

class ImageProcessorBackend: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var compressionQuality: Double = 0.8
    @Published var isProcessing = false
    @Published var originalSize: Int = 0
    @Published var processedSize: Int = 0

    func compressImage() {
        guard let image = selectedImage else { return }
        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            if let data = image.jpegData(compressionQuality: CGFloat(self.compressionQuality)) {
                let compressedImage = UIImage(data: data)
                DispatchQueue.main.async {
                    self.processedImage = compressedImage
                    self.processedSize = data.count
                    self.isProcessing = false
                }
            }
        }
    }

    func setImage(_ image: UIImage) {
        self.selectedImage = image
        if let data = image.jpegData(compressionQuality: 1.0) {
            self.originalSize = data.count
        }
        self.processedImage = nil
        self.processedSize = 0
    }
}
