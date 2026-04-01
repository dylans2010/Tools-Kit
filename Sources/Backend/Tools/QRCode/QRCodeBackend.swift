import Foundation
import CoreImage.CIFilterBuiltins
import SwiftUI
import AVFoundation
import UIKit

class QRCodeBackend: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var inputText = ""
    @Published var qrCodeImage: UIImage? = nil
    @Published var scannedCode: String? = nil
    @Published var isScanning = false

    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    var captureSession: AVCaptureSession?

    func generateQRCode() {
        let data = Data(inputText.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                qrCodeImage = UIImage(cgImage: cgimg)
            }
        }
    }

    func startScanning() {
        isScanning = true
        scannedCode = nil

        // This logic would normally initialize AVCaptureSession on a real device
        // We'll simulate the state here for the modular toolkit
    }

    func stopScanning() {
        isScanning = false
    }

    // AVCaptureMetadataOutputObjectsDelegate method (simulated)
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            DispatchQueue.main.async {
                self.scannedCode = stringValue
                self.isScanning = false
            }
        }
    }
}
