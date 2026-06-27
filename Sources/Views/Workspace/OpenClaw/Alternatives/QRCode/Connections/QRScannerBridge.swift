import Foundation
import AVFoundation
import OSLog
import UIKit

public actor OpenClawQRScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private var continuation: CheckedContinuation<String, Error>?
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "scanner")

    public func scan(in view: UIView) async throws -> String {
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw TLANError.connectionFailed("No camera available")
        }
        let input = try AVCaptureDeviceInput(device: device)
        let output = AVCaptureMetadataOutput()
        guard session.canAddInput(input), session.canAddOutput(output) else {
            throw TLANError.connectionFailed("Capture session setup failed")
        }

        session.beginConfiguration()
        session.addInput(input)
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        session.commitConfiguration()

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        await MainActor.run {
            view.layer.addSublayer(previewLayer)
        }

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            session.startRunning()
        }
    }

    public nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput objects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        Task { await self.finish(with: value) }
    }

    private func finish(with value: String) {
        session.stopRunning()
        continuation?.resume(returning: value)
        continuation = nil
    }
}

public class QRScannerBridge {
    private let scanner = OpenClawQRScanner()
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "bridge")
    public init() {}
    public func startScanning(in view: UIView, completion: @escaping (String) -> Void) {
        Task {
            do {
                let result = try await scanner.scan(in: view)
                completion(result)
            } catch {
                logger.error("Scanning failed: \(error.localizedDescription)")
            }
        }
    }
}
