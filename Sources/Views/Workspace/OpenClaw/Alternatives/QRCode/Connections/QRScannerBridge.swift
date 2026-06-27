import Foundation
import AVFoundation
import OSLog
import UIKit

public actor QRScannerBridge: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private var completion: ((String) -> Void)?
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "qr-scanner")
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public func startScanning(in view: UIView, completion: @escaping (String) -> Void) {
        self.completion = completion

        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            let output = AVCaptureMetadataOutput()

            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [.qr]
            }

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.frame = view.layer.bounds
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
            self.previewLayer = layer

            Task {
                self.session.startRunning()
            }
        } catch {
            logger.error("Failed to setup QR scanner: \(error.localizedDescription)")
        }
    }

    public nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            Task {
                await stopAndNotify(value: stringValue)
            }
        }
    }

    private func stopAndNotify(value: String) {
        session.stopRunning()
        completion?(value)
        completion = nil
    }

    public func stopScanning() {
        session.stopRunning()
    }
}
