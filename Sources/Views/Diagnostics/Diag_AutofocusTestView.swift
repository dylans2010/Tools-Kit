import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_AutofocusTestView: View {
    @State private var details: [(String, String)] = []
    @State private var showPreview = false
    @State private var isSessionRunning = false

    var body: some View {
        Form {
            Section("Autofocus System") {
                VStack(spacing: 12) {
                    Image(systemName: "camera.metering.center.weighted")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                    Text("Autofocus Diagnostics")
                        .font(.headline)
                    Text("Test camera autofocus, continuous AF, and focus lock capabilities")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Autofocus Capabilities") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            if showPreview {
                Section("Live Preview (tap to focus)") {
                    AutofocusPreviewRepresentable(isRunning: $isSessionRunning)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Section {
                Button { showPreview.toggle() } label: {
                    HStack {
                        Image(systemName: showPreview ? "eye.slash" : "eye")
                        Text(showPreview ? "Hide Preview" : "Show Camera Preview")
                    }
                }
            }

            Section("Focus Modes") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Auto Focus — Single focus acquisition", systemImage: "scope").font(.caption)
                    Label("Continuous AF — Tracks moving subjects", systemImage: "scope").font(.caption)
                    Label("Locked Focus — Manual focus lock", systemImage: "lock.fill").font(.caption)
                    Label("Tap to Focus — Point-of-interest focus", systemImage: "hand.tap.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkAF() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Autofocus Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkAF() }
    }

    private func checkAF() {
        var info: [(String, String)] = []

        let cameras: [(String, AVCaptureDevice.DeviceType, AVCaptureDevice.Position)] = [
            ("Back Wide", .builtInWideAngleCamera, .back),
            ("Front", .builtInWideAngleCamera, .front),
            ("Back Telephoto", .builtInTelephotoCamera, .back),
            ("Back Ultra Wide", .builtInUltraWideCamera, .back),
        ]

        for (name, deviceType, position) in cameras {
            if let device = AVCaptureDevice.default(deviceType, for: .video, position: position) {
                let af = device.isFocusModeSupported(.autoFocus)
                let caf = device.isFocusModeSupported(.continuousAutoFocus)
                let locked = device.isFocusModeSupported(.locked)
                let poi = device.isFocusPointOfInterestSupported

                info.append(("\(name) — Auto Focus", af ? "Yes" : "No"))
                info.append(("\(name) — Continuous AF", caf ? "Yes" : "No"))
                info.append(("\(name) — Locked Focus", locked ? "Yes" : "No"))
                info.append(("\(name) — Tap to Focus", poi ? "Yes" : "No"))

                let minFocus = device.minimumFocusDistance
                if minFocus > 0 {
                    info.append(("\(name) — Min Focus Dist", "\(minFocus) mm"))
                }
            }
        }

        details = info
    }
}

struct AutofocusPreviewRepresentable: UIViewRepresentable {
    @Binding var isRunning: Bool
    func makeUIView(context: Context) -> AutofocusPreviewUIView { AutofocusPreviewUIView() }
    func updateUIView(_ uiView: AutofocusPreviewUIView, context: Context) {}
}

class AutofocusPreviewUIView: UIView {
    private var captureSession: AVCaptureSession?
    private var device: AVCaptureDevice?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: dev) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        captureSession = session
        device = dev
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let device = device, device.isFocusPointOfInterestSupported else { return }
        let point = gesture.location(in: self)
        let focusPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = focusPoint
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        } catch {}
    }

    deinit { captureSession?.stopRunning() }
}
