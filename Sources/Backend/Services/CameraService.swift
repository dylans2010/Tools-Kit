#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UIKit)
import UIKit
#endif

protocol CameraServiceDelegate: AnyObject {
    func didOutput(pixelBuffer: CVPixelBuffer)
}

class CameraService: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.tools-kit.camera-queue")

    weak var delegate: CameraServiceDelegate?
    private var _previewLayer: AVCaptureVideoPreviewLayer?

    var previewLayer: AVCaptureVideoPreviewLayer {
        if let existing = _previewLayer { return existing }
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        _previewLayer = layer
        return layer
    }

    func checkPermissions(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    func startSession() {
        sessionQueue.async {
            if self.captureSession.inputs.isEmpty {
                self.setupSession()
            }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func updatePreviewLayerFrame(_ frame: CGRect) {
        DispatchQueue.main.async {
            self._previewLayer?.frame = frame
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func setupSession() {
        captureSession.beginConfiguration()

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate?.didOutput(pixelBuffer: pixelBuffer)
    }
}
