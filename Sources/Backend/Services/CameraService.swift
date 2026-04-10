import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isPermissionGranted = false
    @Published var currentFrame: CVPixelBuffer?

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.tools-kit.camera-session-queue")
    private var lastProcessingTime: TimeInterval = 0
    private let frameThrottlingInterval: TimeInterval = 0.1 // 10 FPS

    override init() {
        super.init()
        checkPermissions()
    }

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isPermissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.isPermissionGranted = true
                        self.setupSession()
                    }
                }
            }
        default:
            self.isPermissionGranted = false
        }
    }

    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }

            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }

            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.tools-kit.video-output-queue"))
            self.videoOutput.alwaysDiscardsLateVideoFrames = true

            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            self.session.commitConfiguration()
        }
    }

    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessingTime >= frameThrottlingInterval else { return }
        lastProcessingTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        DispatchQueue.main.async {
            self.currentFrame = pixelBuffer
        }
    }
}
