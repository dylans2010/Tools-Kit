import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let layer = cameraService.previewLayer
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        cameraService.updatePreviewLayerFrame(uiView.bounds)
    }
}
