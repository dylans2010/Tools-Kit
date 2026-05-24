import SwiftUI
import AVFoundation
import CoreMotion

struct Diag_OISTestView: View {
    @State private var hasOIS = false
    @State private var details: [(String, String)] = []
    @State private var isMonitoring = false
    @State private var motionManager = CMMotionManager()
    @State private var shakeMagnitude: Double = 0
    @State private var shakeHistory: [Double] = []
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Optical Image Stabilization") {
                VStack(spacing: 12) {
                    Image(systemName: hasOIS ? "hand.raised.slash.fill" : "hand.raised.slash")
                        .font(.system(size: 52))
                        .foregroundStyle(hasOIS ? .green : .secondary)
                    Text(hasOIS ? "OIS Available" : "OIS Not Available")
                        .font(.headline)
                    Text("Tests optical and sensor-shift image stabilization hardware")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Stabilization Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Shake Detection") {
                VStack(spacing: 8) {
                    Text(String(format: "%.2f g", shakeMagnitude))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    ProgressView(value: min(shakeMagnitude / 3.0, 1.0))
                        .tint(shakeMagnitude > 1.5 ? .red : shakeMagnitude > 0.5 ? .orange : .green)
                    Text("Move device to test OIS compensation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Shake Detection")
                    }
                }
            }

            Section("OIS Types") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Optical Image Stabilization (OIS)", systemImage: "camera.fill").font(.caption)
                    Label("Sensor-shift OIS (iPhone 12 Pro Max+)", systemImage: "move.3d").font(.caption)
                    Label("Second-gen Sensor-shift (iPhone 14 Pro+)", systemImage: "arrow.up.and.down.and.arrow.left.and.right").font(.caption)
                    Label("Action Mode (software EIS + gyro)", systemImage: "figure.run").font(.caption)
                    Label("Cinematic video stabilization", systemImage: "video.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkOIS() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("OIS Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkOIS() }
        .onDisappear { stopMonitoring() }
    }

    private func checkOIS() {
        var info: [(String, String)] = []

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            let formats = device.formats
            let oisFormats = formats.filter { $0.isVideoStabilizationModeSupported(.cinematic) }
            let standardStab = formats.filter { $0.isVideoStabilizationModeSupported(.standard) }

            hasOIS = !oisFormats.isEmpty || !standardStab.isEmpty
            info.append(("Cinematic Stabilization", !oisFormats.isEmpty ? "Supported (\(oisFormats.count) formats)" : "Not Supported"))
            info.append(("Standard Stabilization", !standardStab.isEmpty ? "Supported (\(standardStab.count) formats)" : "Not Supported"))
            info.append(("Camera", device.localizedName))
        }

        if let telephoto = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
            let stabFormats = telephoto.formats.filter { $0.isVideoStabilizationModeSupported(.standard) }
            info.append(("Telephoto Stabilization", !stabFormats.isEmpty ? "Supported" : "Not Supported"))
        }

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        details = info
    }

    private func startMonitoring() {
        isMonitoring = true
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            let mag = sqrt(pow(data.acceleration.x, 2) + pow(data.acceleration.y, 2) + pow(data.acceleration.z, 2))
            shakeMagnitude = mag
            shakeHistory.append(mag)
            if shakeHistory.count > 100 { shakeHistory.removeFirst() }
        }
    }

    private func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        isMonitoring = false
    }
}
