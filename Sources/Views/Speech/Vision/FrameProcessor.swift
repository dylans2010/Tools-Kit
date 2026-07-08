import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UIKit)
import UIKit
#endif
import CoreImage

enum FrameProcessor {
    private static let context = CIContext()

    static func process(_ sampleBuffer: CMSampleBuffer, targetWidth: CGFloat = 512) -> Data? {
        return autoreleasepool {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            // Normalize orientation (AVCaptureVideoDataOutput from back camera is usually landscape right)
            // For a robust implementation we should read UIDevice.current.orientation or use a fixed one.
            // Assuming portrait for standard iPhone app camera usage:
            let orientedImage = ciImage.oriented(.right)

            let width = orientedImage.extent.width
            let height = orientedImage.extent.height
            
            // Prevent processing empty/invalid bounds
            if width <= 0 || height <= 0 { return nil }
            
            let scale = targetWidth / width
            let targetHeight = height * scale

            let resizedImage = orientedImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

            guard let cgImage = context.createCGImage(resizedImage, from: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)) else {
                return nil
            }

            let uiImage = UIImage(cgImage: cgImage)
            let jpegData = uiImage.jpegData(compressionQuality: 0.7)
            
            // Validate frame: discard if unexpectedly small (e.g. completely black or failed compression)
            if let data = jpegData, data.count > 1024 {
                return data
            }
            
            return nil
        }
    }
}
