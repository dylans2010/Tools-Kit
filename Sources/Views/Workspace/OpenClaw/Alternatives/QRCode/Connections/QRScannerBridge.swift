import Foundation
import UIKit
import AVFoundation

public final class QRScannerBridge: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private var captureSession: AVCaptureSession?
    private var completion: ((String) -> Void)?

    @MainActor
    public func startScanning(in view: UIView, completion: @escaping (String) -> Void) {
        self.completion = completion

        let session = AVCaptureSession()
        self.captureSession = session

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (session.canAddOutput(metadataOutput)) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    public func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            completion?(stringValue)
            stopScanning()
        }
    }
}
