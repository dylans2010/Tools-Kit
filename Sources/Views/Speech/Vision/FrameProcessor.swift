import Foundation
import AVFoundation
import UIKit
import CoreImage

enum FrameProcessor {
    private static let context = CIContext()

    static func process(_ sampleBuffer: CMSampleBuffer, targetWidth: CGFloat = 512) -> Data? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)

        // Handle rotation if needed (AVCaptureVideoDataOutput frames are usually rotated)
        // For simplicity, we'll assume basic orientation for now, or the UI handles it.

        let width = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        let scale = targetWidth / width
        let targetHeight = height * scale

        let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(resizedImage, from: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)) else {
            return nil
        }

        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.jpegData(compressionQuality: 0.7)
    }
}
