import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_PortraitModeView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Portrait Mode") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "person.crop.square.fill" : "person.crop.square")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .indigo : .secondary)
                    Text(supported ? "Portrait Mode Available" : "Portrait Mode Not Available")
                        .font(.headline)
                    Text("Depth-based background blur (bokeh) for photo and video")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Depth Hardware") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Portrait Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Adjustable f-stop (depth of field)", systemImage: "camera.aperture").font(.caption)
                    Label("Studio, Contour, Stage lighting", systemImage: "light.max").font(.caption)
                    Label("Portrait selfies via TrueDepth", systemImage: "person.crop.square.fill").font(.caption)
                    Label("Portrait mode video (iPhone 15+)", systemImage: "video.fill").font(.caption)
                    Label("Post-capture focus point (iPhone 15+)", systemImage: "camera.metering.center.weighted").font(.caption)
                    Label("Night mode portraits (iPhone 12+)", systemImage: "moon.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 7 Plus (dual camera portrait)", systemImage: "iphone.gen1").font(.caption)
                    Label("iPhone X+ (TrueDepth selfie portraits)", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone XR/SE 2+ (ML-based portraits)", systemImage: "iphone.gen2").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkPortrait() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Portrait Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPortrait() }
    }

    private func checkPortrait() {
        var info: [(String, String)] = []

        let hasDualCam = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil
        info.append(("Dual Camera (Portrait)", hasDualCam ? "Available" : "Not available"))

        let hasTriple = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil
        info.append(("Triple Camera", hasTriple ? "Available" : "Not available"))

        let hasTrueDepth = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) != nil
        info.append(("TrueDepth (Selfie Portrait)", hasTrueDepth ? "Available" : "Not available"))

        let hasLiDAR = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
        info.append(("LiDAR Depth", hasLiDAR ? "Available" : "Not available"))

        supported = hasDualCam || hasTriple || hasTrueDepth
        info.append(("Portrait Mode", supported ? "Supported" : "Not Supported"))

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        details = info
    }
}
