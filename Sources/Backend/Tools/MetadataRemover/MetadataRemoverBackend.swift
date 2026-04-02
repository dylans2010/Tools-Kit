import Foundation
import SwiftUI

class MetadataRemoverBackend: ObservableObject {
    @Published var inputImage: UIImage?
    @Published var outputImage: UIImage?
    @Published var isProcessing = false
    @Published var isDone = false

    func stripMetadata() {
        guard let image = inputImage else { return }
        isProcessing = true
        isDone = false

        DispatchQueue.global(qos: .userInitiated).async {
            // Re-drawing the image effectively strips metadata because UIImage/CGImage
            // drawing doesn't preserve EXIF/IPTC properties by default unless explicitly handled.
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let strippedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            DispatchQueue.main.async {
                self.outputImage = strippedImage
                self.isProcessing = false
                self.isDone = true
            }
        }
    }

    func reset() {
        inputImage = nil
        outputImage = nil
        isDone = false
    }
}
