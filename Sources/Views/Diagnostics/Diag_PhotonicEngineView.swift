import SwiftUI
import AVFoundation

struct Diag_PhotonicEngineView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Photonic Engine") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "cpu.fill" : "cpu")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .indigo : .secondary)
                    Text(supported ? "Photonic Engine Available" : "Photonic Engine Not Available")
                        .font(.headline)
                    Text("Apple's advanced computational photography pipeline for better detail, color, and low-light performance")
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

            Section("Photonic Engine Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Deep Fusion applied earlier in pipeline", systemImage: "cpu.fill").font(.caption)
                    Label("Enhanced texture and detail preservation", systemImage: "photo.fill").font(.caption)
                    Label("Up to 2x better low-light performance", systemImage: "moon.fill").font(.caption)
                    Label("Applied to all cameras including front", systemImage: "camera.fill").font(.caption)
                    Label("Smart HDR 4/5 integration", systemImage: "sun.max.fill").font(.caption)
                    Label("Neural Engine processing", systemImage: "brain.head.profile.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Image Pipeline") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("1. Raw sensor capture", systemImage: "1.circle.fill").font(.caption)
                    Label("2. Photonic Engine processing (early fusion)", systemImage: "2.circle.fill").font(.caption)
                    Label("3. Deep Fusion detail enhancement", systemImage: "3.circle.fill").font(.caption)
                    Label("4. Smart HDR tone mapping", systemImage: "4.circle.fill").font(.caption)
                    Label("5. Final image output", systemImage: "5.circle.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 14 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkPhotonic() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Photonic Engine")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPhotonic() }
    }

    private func checkPhotonic() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let photonicModels = [
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        supported = photonicModels.contains(modelId)
        info.append(("Photonic Engine", supported ? "Supported" : "Not Supported"))

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            info.append(("Primary Camera", device.localizedName))
            let formats = device.formats
            if let best = formats.last {
                let dims = CMVideoFormatDescriptionGetDimensions(best.formatDescription)
                info.append(("Max Resolution", "\(dims.width) x \(dims.height)"))
            }
        }
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
