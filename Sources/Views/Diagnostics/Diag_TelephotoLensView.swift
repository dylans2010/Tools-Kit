import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_TelephotoLensView: View {
    @State private var isAvailable = false
    @State private var isSessionRunning = false
    @State private var details: [(String, String)] = []
    @State private var showPreview = false

    var body: some View {
        Form {
            Section("Telephoto Lens") {
                VStack(spacing: 12) {
                    Image(systemName: isAvailable ? "camera.aperture" : "camera")
                        .font(.system(size: 52))
                        .foregroundStyle(isAvailable ? .indigo : .secondary)
                    Text(isAvailable ? "Telephoto Lens Available" : "Telephoto Lens Not Available")
                        .font(.headline)
                    Text("Tests the built-in telephoto camera for optical zoom")
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
                        TelephotoPreviewRepresentable(isRunning: $isSessionRunning)
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

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 7 Plus and later dual/triple camera models", systemImage: "iphone.gen2")
                        .font(.caption)
                    Label("2x optical zoom (standard), 3x (iPhone 13 Pro+), 5x (iPhone 15 Pro Max)", systemImage: "plus.magnifyingglass")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkTelephoto() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Telephoto Lens")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkTelephoto() }
    }

    private func checkTelephoto() {
        var info: [(String, String)] = []

        if let device = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
            isAvailable = true
            info.append(("Telephoto Camera", device.localizedName))
            info.append(("Unique ID", String(device.uniqueID.prefix(12)) + "..."))
            info.append(("Max Zoom", String(format: "%.1fx", device.maxAvailableVideoZoomFactor)))
            info.append(("Min Zoom", String(format: "%.1fx", device.minAvailableVideoZoomFactor)))
            info.append(("Has Torch", device.hasTorch ? "Yes" : "No"))
            info.append(("Has Flash", device.hasFlash ? "Yes" : "No"))
            info.append(("Low Light Boost", device.isLowLightBoostSupported ? "Supported" : "Not Supported"))

            let formats = device.formats
            info.append(("Format Count", "\(formats.count)"))
            if let best = formats.last {
                let dims = CMVideoFormatDescriptionGetDimensions(best.formatDescription)
                info.append(("Max Resolution", "\(dims.width) x \(dims.height)"))
            }
        } else {
            isAvailable = false
            info.append(("Telephoto Camera", "Not detected"))
        }

        details = info
    }
}

struct TelephotoPreviewRepresentable: UIViewRepresentable {
    @Binding var isRunning: Bool

    func makeUIView(context: Context) -> TelephotoPreviewUIView {
        TelephotoPreviewUIView()
    }
    func updateUIView(_ uiView: TelephotoPreviewUIView, context: Context) {}
}

class TelephotoPreviewUIView: UIView {
    private var captureSession: AVCaptureSession?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    deinit { captureSession?.stopRunning() }
}
