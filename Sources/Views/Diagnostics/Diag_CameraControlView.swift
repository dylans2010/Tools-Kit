import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_CameraControlView: View {
    @State private var hasCameraControl = false
    @State private var deviceModel = ""
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Camera Control Button") {
                VStack(spacing: 12) {
                    Image(systemName: hasCameraControl ? "camera.shutter.button.fill" : "camera.shutter.button")
                        .font(.system(size: 52))
                        .foregroundStyle(hasCameraControl ? .blue : .secondary)
                    Text(hasCameraControl ? "Camera Control Available" : "Camera Control Not Available")
                        .font(.headline)
                    Text("iPhone 16 series feature — capacitive shutter button with pressure and swipe gestures")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Device Info") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Camera Control Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Light press to focus", systemImage: "camera.metering.center.weighted")
                        .font(.caption)
                    Label("Full press to capture", systemImage: "camera.shutter.button.fill")
                        .font(.caption)
                    Label("Swipe to zoom in/out", systemImage: "plus.magnifyingglass")
                        .font(.caption)
                    Label("Double light press for exposure/depth", systemImage: "slider.horizontal.3")
                        .font(.caption)
                    Label("Works with third-party camera apps", systemImage: "app.badge.checkmark.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 16", systemImage: "iphone.gen3")
                        .font(.caption)
                    Label("iPhone 16 Plus", systemImage: "iphone.gen3")
                        .font(.caption)
                    Label("iPhone 16 Pro", systemImage: "iphone.gen3")
                        .font(.caption)
                    Label("iPhone 16 Pro Max", systemImage: "iphone.gen3")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkCameraControl() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Camera Control")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkCameraControl() }
    }

    private func checkCameraControl() {
        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        deviceModel = modelId

        let iphone16Models = ["iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
                              "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"]
        hasCameraControl = iphone16Models.contains(modelId)

        var info: [(String, String)] = []
        info.append(("Device Model", modelId))
        info.append(("Camera Control", hasCameraControl ? "Supported" : "Not Supported"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            info.append(("Primary Camera", device.localizedName))
        }

        details = info
    }
}
