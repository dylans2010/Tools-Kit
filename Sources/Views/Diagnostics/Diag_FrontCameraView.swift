import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_FrontCameraView: View {
    @State private var isCameraAvailable = false
    @State private var isSessionRunning = false

    var body: some View {
        VStack(spacing: 0) {
            if isCameraAvailable {
                CameraPreviewRepresentable(position: .front, isRunning: $isSessionRunning)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("Front camera not available")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black)
        .navigationTitle("Front Camera")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isCameraAvailable = UIImagePickerController.isCameraDeviceAvailable(.front)
        }
    }
}

struct CameraPreviewRepresentable: UIViewRepresentable {
    let position: AVCaptureDevice.Position
    @Binding var isRunning: Bool

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView(position: position)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    private var captureSession: AVCaptureSession?

    init(position: AVCaptureDevice.Position) {
        super.init(frame: .zero)
        setupCamera(position: position)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    private func setupCamera(position: AVCaptureDevice.Position) {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill

        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    deinit {
        captureSession?.stopRunning()
    }
}
