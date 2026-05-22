import SwiftUI
import AVFoundation
import Vision

// MARK: - Scan Engine

@MainActor
final class ScanNotebooksEngine: NSObject, ObservableObject {

    // MARK: Published state

    @Published var isCameraReady = false
    @Published var isCapturing = false
    @Published var capturedImage: UIImage?
    @Published var extractedText = ""
    @Published var extractionError: String?
    @Published var isExtracting = false
    @Published var cameraPermissionDenied = false

    // MARK: AVFoundation objects

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?

    // MARK: - Lifecycle

    func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.cameraPermissionDenied = true
                    }
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }

    // MARK: - Session setup

    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        captureSession.commitConfiguration()
        currentDevice = device

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            Task { @MainActor in
                self?.isCameraReady = true
            }
        }
    }

    // MARK: - Capture

    func capturePhoto() {
        guard isCameraReady else { return }
        isCapturing = true
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func retryCapture() {
        capturedImage = nil
        extractedText = ""
        extractionError = nil
        isExtracting = false

        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    // MARK: - Text extraction (Vision)

    func extractText(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            extractionError = "Could not process image."
            return
        }

        isExtracting = true
        extractionError = nil

        let request = VNRecognizeTextRequest { [weak self] request, error in
            Task { @MainActor in
                guard let self else { return }
                self.isExtracting = false

                if let error {
                    self.extractionError = error.localizedDescription
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.extractionError = "No text found in image."
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                if lines.isEmpty {
                    self.extractionError = "No text found in image."
                } else {
                    self.extractedText = lines.joined(separator: "\n")
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Cleanup

    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension ScanNotebooksEngine: AVCapturePhotoCaptureDelegate {

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        Task { @MainActor in
            isCapturing = false

            if let error {
                extractionError = error.localizedDescription
                return
            }

            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                extractionError = "Failed to process captured photo."
                return
            }

            capturedImage = image

            captureSession.stopRunning()

            extractText(from: image)
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
