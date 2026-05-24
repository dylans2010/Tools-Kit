import SwiftUI
import CoreMotion

struct Diag_CrashDetectionView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Crash Detection") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "car.side.front.open.fill" : "car.side.front.open")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .red : .secondary)
                    Text(supported ? "Crash Detection Available" : "Crash Detection Not Available")
                        .font(.headline)
                    Text("Detects severe car crashes and automatically contacts emergency services")
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

            Section("Sensors Used") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("High-g accelerometer (up to 256g)", systemImage: "move.3d").font(.caption)
                    Label("High dynamic range gyroscope", systemImage: "gyroscope").font(.caption)
                    Label("Barometer (cabin pressure change)", systemImage: "barometer").font(.caption)
                    Label("GPS (speed and sudden deceleration)", systemImage: "location.fill").font(.caption)
                    Label("Microphone (crash sounds)", systemImage: "mic.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("How It Works") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Detects impacts up to 256g force", systemImage: "exclamationmark.triangle.fill").font(.caption)
                    Label("Analyzes cabin pressure changes", systemImage: "barometer").font(.caption)
                    Label("Checks for sudden speed drop", systemImage: "speedometer").font(.caption)
                    Label("20-second countdown before calling 911", systemImage: "timer").font(.caption)
                    Label("Shares location with emergency contacts", systemImage: "location.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 14 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("Apple Watch Series 8+, Ultra", systemImage: "applewatch").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkCrashDetection() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Crash Detection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkCrashDetection() }
    }

    private func checkCrashDetection() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let crashDetectionModels = [
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        supported = crashDetectionModels.contains(modelId)
        info.append(("Crash Detection", supported ? "Supported" : "Not Supported"))

        let motionManager = CMMotionManager()
        info.append(("Accelerometer", motionManager.isAccelerometerAvailable ? "Available" : "Not available"))
        info.append(("Gyroscope", motionManager.isGyroAvailable ? "Available" : "Not available"))

        let altimeter = CMAltimeter.isRelativeAltitudeAvailable()
        info.append(("Barometer", altimeter ? "Available" : "Not available"))

        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
