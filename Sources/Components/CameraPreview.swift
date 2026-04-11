import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> CameraContainerView {
        let container = CameraContainerView()
        container.backgroundColor = .black
        let previewLayer = cameraService.previewLayer
        previewLayer.frame = container.bounds
        container.layer.addSublayer(previewLayer)
        container.previewLayer = previewLayer
        return container
    }

    func updateUIView(_ uiView: CameraContainerView, context: Context) {
        // Frame updates are handled in layoutSubviews for correct sizing
    }
}

/// A UIView subclass that keeps the preview layer frame in sync during layout.
final class CameraContainerView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
