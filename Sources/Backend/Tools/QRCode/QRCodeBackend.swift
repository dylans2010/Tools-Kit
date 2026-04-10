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
        if captureSession == nil {
            setupCaptureSession()
        }

        isScanning = true
        scannedCode = nil

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
    }

    private func setupCaptureSession() {
        let session = AVCaptureSession()

        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        self.captureSession = session
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            DispatchQueue.main.async {
                self.scannedCode = stringValue
                self.isScanning = false
                self.captureSession?.stopRunning()
            }
        }
    }
}
