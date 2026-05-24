import SwiftUI
import AVFoundation

struct Diag_UltraWideLensView: View {
    @State private var isAvailable = false
    @State private var isSessionRunning = false
    @State private var details: [(String, String)] = []
    @State private var showPreview = false

    var body: some View {
        Form {
            Section("Ultra Wide Lens") {
                VStack(spacing: 12) {
                    Image(systemName: isAvailable ? "camera.aperture" : "camera")
                        .font(.system(size: 52))
                        .foregroundStyle(isAvailable ? .orange : .secondary)
                    Text(isAvailable ? "Ultra Wide Lens Available" : "Ultra Wide Lens Not Available")
                        .font(.headline)
                    Text("0.5x ultra wide-angle camera with 120° field of view")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Lens Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            if isAvailable {
                Section("Preview") {
                    if showPreview {
                        UltraWidePreviewRepresentable(isRunning: $isSessionRunning)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button {
                        showPreview.toggle()
                    } label: {
                        HStack {
                            Image(systemName: showPreview ? "eye.slash" : "eye")
                            Text(showPreview ? "Hide Preview" : "Show Preview")
                        }
                    }
                }
            }

            Section("Capabilities") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("120° field of view", systemImage: "viewfinder.wide")
                        .font(.caption)
                    Label("13mm equivalent focal length", systemImage: "camera.aperture")
                        .font(.caption)
                    Label("Macro photography (iPhone 13 Pro+)", systemImage: "leaf.fill")
                        .font(.caption)
                    Label("Front-line correction for distortion", systemImage: "perspective")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkUltraWide() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Ultra Wide Lens")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkUltraWide() }
    }

    private func checkUltraWide() {
        var info: [(String, String)] = []

        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            isAvailable = true
            info.append(("Ultra Wide Camera", device.localizedName))
            info.append(("Max Zoom", String(format: "%.1fx", device.maxAvailableVideoZoomFactor)))
            info.append(("Min Zoom", String(format: "%.1fx", device.minAvailableVideoZoomFactor)))
            info.append(("Has Torch", device.hasTorch ? "Yes" : "No"))
            info.append(("Has Flash", device.hasFlash ? "Yes" : "No"))
            info.append(("Autofocus", device.isFocusModeSupported(.autoFocus) ? "Supported" : "Not Supported"))
            info.append(("Low Light Boost", device.isLowLightBoostSupported ? "Supported" : "Not Supported"))

            let formats = device.formats
            info.append(("Format Count", "\(formats.count)"))
            if let best = formats.last {
                let dims = CMVideoFormatDescriptionGetDimensions(best.formatDescription)
                info.append(("Max Resolution", "\(dims.width) x \(dims.height)"))
            }
        } else {
            isAvailable = false
            info.append(("Ultra Wide Camera", "Not detected"))
        }

        details = info
    }
}

struct UltraWidePreviewRepresentable: UIViewRepresentable {
    @Binding var isRunning: Bool
    func makeUIView(context: Context) -> UltraWidePreviewUIView { UltraWidePreviewUIView() }
    func updateUIView(_ uiView: UltraWidePreviewUIView, context: Context) {}
}

class UltraWidePreviewUIView: UIView {
    private var captureSession: AVCaptureSession?
    override init(frame: CGRect) { super.init(frame: frame); setupCamera() }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }
    deinit { captureSession?.stopRunning() }
}
