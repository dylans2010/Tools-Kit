import SwiftUI
import AVFoundation

struct Diag_MacroCameraView: View {
    @State private var macroSupported = false
    @State private var ultraWideAvailable = false
    @State private var details: [(String, String)] = []
    @State private var showPreview = false
    @State private var isSessionRunning = false

    var body: some View {
        Form {
            Section("Macro Photography") {
                VStack(spacing: 12) {
                    Image(systemName: macroSupported ? "leaf.fill" : "leaf")
                        .font(.system(size: 52))
                        .foregroundStyle(macroSupported ? .green : .secondary)
                    Text(macroSupported ? "Macro Mode Available" : "Macro Mode Not Available")
                        .font(.headline)
                    Text("Close-up photography using the ultra wide lens with autofocus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Hardware Check") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            if macroSupported {
                Section("Macro Preview (Ultra Wide)") {
                    if showPreview {
                        MacroPreviewRepresentable(isRunning: $isSessionRunning)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button {
                        showPreview.toggle()
                    } label: {
                        HStack {
                            Image(systemName: showPreview ? "eye.slash" : "eye")
                            Text(showPreview ? "Hide Preview" : "Show Macro Preview")
                        }
                    }
                }
            }

            Section("Macro Capabilities") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("2cm minimum focus distance", systemImage: "ruler.fill")
                        .font(.caption)
                    Label("Uses ultra wide lens with autofocus", systemImage: "camera.aperture")
                        .font(.caption)
                    Label("Macro video and slow-motion", systemImage: "video.fill")
                        .font(.caption)
                    Label("Auto Macro switching in Camera app", systemImage: "arrow.triangle.swap")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 13 Pro / Pro Max", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 14 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkMacro() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Macro Camera")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkMacro() }
    }

    private func checkMacro() {
        var info: [(String, String)] = []

        if let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            ultraWideAvailable = true
            info.append(("Ultra Wide Camera", ultraWide.localizedName))

            let hasAutoFocus = ultraWide.isFocusModeSupported(.autoFocus)
            info.append(("Autofocus on Ultra Wide", hasAutoFocus ? "Yes" : "No"))

            let minFocusDistance = ultraWide.minimumFocusDistance
            info.append(("Min Focus Distance", minFocusDistance > 0 ? "\(minFocusDistance) mm" : "N/A"))

            macroSupported = hasAutoFocus
            info.append(("Macro Mode", macroSupported ? "Supported" : "Not Supported"))
        } else {
            ultraWideAvailable = false
            macroSupported = false
            info.append(("Ultra Wide Camera", "Not detected"))
            info.append(("Macro Mode", "Not Supported"))
        }

        details = info
    }
}

struct MacroPreviewRepresentable: UIViewRepresentable {
    @Binding var isRunning: Bool
    func makeUIView(context: Context) -> MacroPreviewUIView { MacroPreviewUIView() }
    func updateUIView(_ uiView: MacroPreviewUIView, context: Context) {}
}

class MacroPreviewUIView: UIView {
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
