import SwiftUI
import CoreMotion

struct Diag_MagSafeTestView: View {
    @State private var hasMagSafe = false
    @State private var details: [(String, String)] = []
    @State private var magneticFieldX: Double = 0
    @State private var magneticFieldY: Double = 0
    @State private var magneticFieldZ: Double = 0
    @State private var magneticMagnitude: Double = 0
    @State private var isMonitoring = false
    @State private var motionManager = CMMotionManager()

    var body: some View {
        Form {
            Section("MagSafe") {
                VStack(spacing: 12) {
                    Image(systemName: hasMagSafe ? "magsafe.batterypack.fill" : "magsafe.batterypack")
                        .font(.system(size: 52))
                        .foregroundStyle(hasMagSafe ? .blue : .secondary)
                    Text(hasMagSafe ? "MagSafe Compatible" : "MagSafe Not Available")
                        .font(.headline)
                    Text("Magnetic alignment system for wireless charging and accessories")
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

            Section("Magnetic Field (Magnetometer)") {
                VStack(spacing: 8) {
                    HStack {
                        Text("X: \(String(format: "%.1f", magneticFieldX)) \u{00B5}T")
                        Spacer()
                        Text("Y: \(String(format: "%.1f", magneticFieldY)) \u{00B5}T")
                        Spacer()
                        Text("Z: \(String(format: "%.1f", magneticFieldZ)) \u{00B5}T")
                    }
                    .font(.caption.monospaced())

                    LabeledContent("Magnitude") {
                        Text(String(format: "%.1f \u{00B5}T", magneticMagnitude))
                            .font(.caption.monospaced())
                    }

                    Text("Place a MagSafe accessory on the back to see magnetic field changes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Magnetometer")
                    }
                }
            }

            Section("MagSafe Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("15W wireless charging (MagSafe charger)", systemImage: "bolt.fill").font(.caption)
                    Label("Perfect alignment with magnets", systemImage: "circle.dashed").font(.caption)
                    Label("MagSafe cases and wallets", systemImage: "creditcard.fill").font(.caption)
                    Label("MagSafe Battery Pack", systemImage: "battery.100").font(.caption)
                    Label("Qi2 compatibility (iPhone 16+)", systemImage: "bolt.circle.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 12 and later (all models)", systemImage: "iphone.gen2").font(.caption)
                    Label("Qi2 (open standard) iPhone 16+", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkMagSafe() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("MagSafe Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkMagSafe() }
        .onDisappear { stopMonitoring() }
    }

    private func checkMagSafe() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let magSafeModels = [
            "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4",
            "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5",
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        hasMagSafe = magSafeModels.contains(modelId)
        info.append(("MagSafe", hasMagSafe ? "Supported" : "Not Supported"))
        info.append(("Magnetometer", motionManager.isMagnetometerAvailable ? "Available" : "Not available"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }

    private func startMonitoring() {
        guard motionManager.isMagnetometerAvailable else { return }
        isMonitoring = true
        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.startMagnetometerUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            magneticFieldX = data.magneticField.x
            magneticFieldY = data.magneticField.y
            magneticFieldZ = data.magneticField.z
            magneticMagnitude = sqrt(pow(data.magneticField.x, 2) + pow(data.magneticField.y, 2) + pow(data.magneticField.z, 2))
        }
    }

    private func stopMonitoring() {
        motionManager.stopMagnetometerUpdates()
        isMonitoring = false
    }
}
