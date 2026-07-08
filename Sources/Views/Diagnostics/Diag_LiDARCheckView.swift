import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif
import ARKit

struct Diag_LiDARCheckView: View {
    @State private var lidarSupported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("LiDAR Scanner") {
                VStack(spacing: 12) {
                    Image(systemName: lidarSupported ? "light.recessed.fill" : "light.recessed")
                        .font(.system(size: 52))
                        .foregroundStyle(lidarSupported ? .blue : .secondary)
                    Text(lidarSupported ? "LiDAR Available" : "LiDAR Not Available")
                        .font(.headline)
                    Text(lidarSupported ? "Time-of-Flight depth sensor detected" : "This device does not have a LiDAR scanner")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Hardware Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("LiDAR Capabilities") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Room scanning and 3D measurement", systemImage: "ruler.fill").font(.caption)
                    Label("AR object occlusion", systemImage: "arkit").font(.caption)
                    Label("Faster AR plane detection", systemImage: "square.3.layers.3d.down.left").font(.caption)
                    Label("Night mode autofocus assist", systemImage: "camera.fill").font(.caption)
                    Label("Point cloud generation", systemImage: "circle.grid.3x3.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 12 Pro / Pro Max and later Pro models", systemImage: "iphone.gen2").font(.caption)
                    Label("iPad Pro 11\" (2nd gen+) and 12.9\" (4th gen+)", systemImage: "ipad").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section { Button { checkLiDAR() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") } } }
        }
        .navigationTitle("LiDAR Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkLiDAR() }
    }

    private func checkLiDAR() {
        var info: [(String, String)] = []

        let arSupported = ARWorldTrackingConfiguration.isSupported
        info.append(("AR World Tracking", arSupported ? "Supported" : "Not supported"))

        if arSupported {
            let config = ARWorldTrackingConfiguration()
            let supportsSceneDepth = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
            lidarSupported = supportsSceneDepth
            info.append(("Scene Depth", supportsSceneDepth ? "Supported (LiDAR)" : "Not supported"))

            let supportsSmoothed = ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth)
            info.append(("Smoothed Depth", supportsSmoothed ? "Supported" : "Not supported"))

            let supportsMeshClassification = ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)
            info.append(("Mesh Classification", supportsMeshClassification ? "Supported" : "Not supported"))

            let supportsMesh = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            info.append(("Scene Reconstruction", supportsMesh ? "Supported" : "Not supported"))
        } else {
            lidarSupported = false
        }

        if let backCam = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) {
            lidarSupported = true
            info.append(("LiDAR Camera", backCam.localizedName))
        } else {
            info.append(("LiDAR Camera", "Not detected"))
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
}
