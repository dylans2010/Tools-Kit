import SwiftUI
import AVFoundation
import ARKit

struct Diag_LiDARFullView: View {
    @State private var lidarSupported = false
    @State private var details: [(String, String)] = []
    @State private var isScanning = false
    @State private var scanResults: [(String, String)] = []
    @State private var meshVertexCount = 0
    @State private var meshFaceCount = 0

    var body: some View {
        Form {
            Section("LiDAR Scanner") {
                VStack(spacing: 12) {
                    Image(systemName: lidarSupported ? "light.recessed.fill" : "light.recessed")
                        .font(.system(size: 52))
                        .foregroundStyle(lidarSupported ? .blue : .secondary)
                    Text(lidarSupported ? "LiDAR Available" : "LiDAR Not Available")
                        .font(.headline)
                    Text("Full LiDAR depth sensor, mesh reconstruction, and measurement capabilities")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Hardware Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Depth Capabilities") {
                VStack(alignment: .leading, spacing: 6) {
                    capabilityRow("Scene Depth", supported: supportsSceneDepth())
                    capabilityRow("Smoothed Scene Depth", supported: supportsSmoothedDepth())
                    capabilityRow("Scene Reconstruction (Mesh)", supported: supportsMesh())
                    capabilityRow("Mesh with Classification", supported: supportsMeshClassification())
                    capabilityRow("Person Segmentation", supported: supportsPersonSeg())
                    capabilityRow("People Occlusion", supported: supportsPeopleOcclusion())
                    capabilityRow("Ray Casting", supported: ARWorldTrackingConfiguration.isSupported)
                    capabilityRow("Object Detection", supported: ARObjectScanningConfiguration.isSupported)
                }
                .padding(.vertical, 4)
            }

            Section("AR Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Real-time 3D mesh generation", systemImage: "cube.transparent.fill")
                        .font(.caption)
                    Label("Point cloud generation", systemImage: "circle.grid.3x3.fill")
                        .font(.caption)
                    Label("Room scanning and measurement", systemImage: "ruler.fill")
                        .font(.caption)
                    Label("Surface classification (floor, wall, etc.)", systemImage: "square.3.layers.3d.down.left")
                        .font(.caption)
                    Label("Instant AR plane detection", systemImage: "rectangle.3.group.fill")
                        .font(.caption)
                    Label("Night mode autofocus assist", systemImage: "moon.fill")
                        .font(.caption)
                    Label("Object occlusion in AR", systemImage: "arkit")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Measurement") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Up to 5m range", systemImage: "arrow.left.and.right")
                        .font(.caption)
                    Label("Time-of-Flight (ToF) technology", systemImage: "timer")
                        .font(.caption)
                    Label("Sub-centimeter accuracy at close range", systemImage: "ruler.fill")
                        .font(.caption)
                    Label("256x192 depth resolution", systemImage: "square.grid.4x3.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 12 Pro / Pro Max", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 13 Pro / Pro Max", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 14 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPad Pro 11\" (2nd gen+) and 12.9\" (4th gen+)", systemImage: "ipad").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkLiDAR() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("LiDAR Full")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkLiDAR() }
    }

    @ViewBuilder
    private func capabilityRow(_ name: String, supported: Bool) -> some View {
        HStack {
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(supported ? .green : .secondary)
                .font(.caption)
            Text(name)
                .font(.caption)
            Spacer()
            Text(supported ? "Yes" : "No")
                .font(.caption)
                .foregroundStyle(supported ? .green : .secondary)
        }
    }

    private func checkLiDAR() {
        var info: [(String, String)] = []

        let arSupported = ARWorldTrackingConfiguration.isSupported
        info.append(("AR World Tracking", arSupported ? "Supported" : "Not supported"))

        let hasSceneDepth = supportsSceneDepth()
        lidarSupported = hasSceneDepth
        info.append(("Scene Depth (LiDAR)", hasSceneDepth ? "Supported" : "Not supported"))
        info.append(("Smoothed Depth", supportsSmoothedDepth() ? "Supported" : "Not supported"))
        info.append(("Mesh Reconstruction", supportsMesh() ? "Supported" : "Not supported"))
        info.append(("Mesh Classification", supportsMeshClassification() ? "Supported" : "Not supported"))

        if let lidarCam = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) {
            lidarSupported = true
            info.append(("LiDAR Camera", lidarCam.localizedName))
            info.append(("Depth Formats", "\(lidarCam.formats.count)"))
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

    private func supportsSceneDepth() -> Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }
    private func supportsSmoothedDepth() -> Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth)
    }
    private func supportsMesh() -> Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    private func supportsMeshClassification() -> Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)
    }
    private func supportsPersonSeg() -> Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation)
    }
    private func supportsPeopleOcclusion() -> Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth)
    }
}
