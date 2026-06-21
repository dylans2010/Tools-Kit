import Foundation
import AVFoundation
import CoreImage
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isRunning = false
    @Published var isPaused = false

    private var videoOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.tools-kit.vision.camera-queue")

    private var lastFrameTime: TimeInterval = 0
    private var currentThrottle: TimeInterval = 1.0 // 1 fps base
    
    // For adaptive throttling
    private var lastProcessStartTime: TimeInterval = 0

    var onFrameCaptured: ((CMSampleBuffer) -> Void)?

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .medium

            // Default input (back camera)
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }

            // Output
            if self.session.canAddOutput(self.videoOutput) {
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.session.addOutput(self.videoOutput)
            }

            self.session.commitConfiguration()
        }
    }

    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }

    func switchCamera() {
        sessionQueue.async {
            guard let currentInput = self.videoDeviceInput else { return }

            self.session.beginConfiguration()
            self.session.removeInput(currentInput)

            let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back

            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                self.session.addInput(currentInput)
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
            } else {
                self.session.addInput(currentInput)
            }

            self.session.commitConfiguration()
        }
    }
    
    func captureImmediateFrame() {
        // Temporarily clear the throttle to allow the very next frame through
        sessionQueue.async {
            self.lastFrameTime = 0
        }
    }
    
    func togglePause() {
        DispatchQueue.main.async {
            self.isPaused.toggle()
        }
    }
    
    func reportProcessingComplete(duration: TimeInterval) {
        sessionQueue.async {
            // Adaptive throttling: If processing takes longer than the base throttle, increase it.
            // Decay it slowly back to 1.0 if processing is fast.
            let targetThrottle = max(1.0, duration + 0.2) // Give 200ms breathing room
            self.currentThrottle = (self.currentThrottle * 0.7) + (targetThrottle * 0.3)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isPaused else { return }
        
        let currentTime = CACurrentMediaTime()
        if currentTime - lastFrameTime >= currentThrottle {
            lastFrameTime = currentTime
            lastProcessStartTime = currentTime
            onFrameCaptured?(sampleBuffer)
        }
    }
}
