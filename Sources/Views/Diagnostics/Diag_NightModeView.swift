import SwiftUI
import AVFoundation

struct Diag_NightModeView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Night Mode") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "moon.stars.fill" : "moon.stars")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .yellow : .secondary)
                    Text(supported ? "Night Mode Available" : "Night Mode Not Available")
                        .font(.headline)
                    Text("Low-light photography with multi-frame processing and long exposure")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Camera Check") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Night Mode Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Automatic activation in low light", systemImage: "moon.fill").font(.caption)
                    Label("Multi-frame stacking and alignment", systemImage: "square.stack.3d.up.fill").font(.caption)
                    Label("Intelligent long exposure (1-30 seconds)", systemImage: "timer").font(.caption)
                    Label("LiDAR-assisted focus in dark (Pro models)", systemImage: "light.recessed.fill").font(.caption)
                    Label("Night mode on all cameras (iPhone 12+)", systemImage: "camera.fill").font(.caption)
                    Label("Night mode portraits (iPhone 12+)", systemImage: "person.crop.square.fill").font(.caption)
                    Label("Night mode time-lapse", systemImage: "timelapse").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 11 (all models) — Wide only", systemImage: "iphone.gen1").font(.caption)
                    Label("iPhone 12 (all models) — All cameras", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 13+ — All cameras + Night portraits", systemImage: "iphone.gen2").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkNightMode() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Night Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkNightMode() }
    }

    private func checkNightMode() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let nightModeModels = [
            "iPhone12,1", "iPhone12,3", "iPhone12,5",
            "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4",
            "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5",
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        supported = nightModeModels.contains(modelId)
        info.append(("Night Mode", supported ? "Supported" : "Not Supported"))

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            info.append(("Wide Camera", device.localizedName))
            info.append(("Low Light Boost", device.isLowLightBoostSupported ? "Supported" : "Not Supported"))
        }

        let hasLiDAR = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
        info.append(("LiDAR Night Focus", hasLiDAR ? "Available" : "Not available"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
