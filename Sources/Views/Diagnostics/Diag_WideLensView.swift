import SwiftUI
import AVFoundation

struct Diag_WideLensView: View {
    @State private var isAvailable = false
    @State private var details: [(String, String)] = []
    @State private var showPreview = false
    @State private var isSessionRunning = false

    var body: some View {
        Form {
            Section("Wide Angle Lens") {
                VStack(spacing: 12) {
                    Image(systemName: isAvailable ? "camera.fill" : "camera")
                        .font(.system(size: 52))
                        .foregroundStyle(isAvailable ? .blue : .secondary)
                    Text(isAvailable ? "Wide Lens Available" : "Wide Lens Not Available")
                        .font(.headline)
                    Text("Primary 1x wide-angle camera — the main shooter")
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
                        WideLensPreviewRepresentable(isRunning: $isSessionRunning)
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

            Section("Wide Lens Info") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("26mm equivalent focal length", systemImage: "camera.aperture")
                        .font(.caption)
                    Label("Sensor-shift OIS (iPhone 12 Pro Max+)", systemImage: "hand.raised.slash.fill")
                        .font(.caption)
                    Label("Dual Pixel autofocus", systemImage: "camera.metering.center.weighted")
                        .font(.caption)
                    Label("48MP sensor (iPhone 14 Pro+)", systemImage: "square.grid.4x3.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkWideLens() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Wide Lens")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkWideLens() }
    }

    private func checkWideLens() {
        var info: [(String, String)] = []

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            isAvailable = true
            info.append(("Wide Camera", device.localizedName))
            info.append(("Max Zoom", String(format: "%.1fx", device.maxAvailableVideoZoomFactor)))
            info.append(("Has Torch", device.hasTorch ? "Yes" : "No"))
            info.append(("Has Flash", device.hasFlash ? "Yes" : "No"))
            info.append(("Autofocus", device.isFocusModeSupported(.autoFocus) ? "Supported" : "Not Supported"))
            info.append(("Continuous AF", device.isFocusModeSupported(.continuousAutoFocus) ? "Supported" : "Not Supported"))
            info.append(("Low Light Boost", device.isLowLightBoostSupported ? "Supported" : "Not Supported"))
            info.append(("Exposure Lock", device.isExposureModeSupported(.locked) ? "Supported" : "Not Supported"))

            let formats = device.formats
            info.append(("Format Count", "\(formats.count)"))
            if let best = formats.last {
                let dims = CMVideoFormatDescriptionGetDimensions(best.formatDescription)
                info.append(("Max Resolution", "\(dims.width) x \(dims.height)"))
                let maxFPS = best.videoSupportedFrameRateRanges.map { $0.maxFrameRate }.max() ?? 0
                info.append(("Max FPS", String(format: "%.0f", maxFPS)))
            }
        } else {
            isAvailable = false
            info.append(("Wide Camera", "Not detected"))
        }

        details = info
    }
}

struct WideLensPreviewRepresentable: UIViewRepresentable {
    @Binding var isRunning: Bool
    func makeUIView(context: Context) -> WideLensPreviewUIView { WideLensPreviewUIView() }
    func updateUIView(_ uiView: WideLensPreviewUIView, context: Context) {}
}

class WideLensPreviewUIView: UIView {
    private var captureSession: AVCaptureSession?
    override init(frame: CGRect) { super.init(frame: frame); setupCamera() }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }
    deinit { captureSession?.stopRunning() }
}
