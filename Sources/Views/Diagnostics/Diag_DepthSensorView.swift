import SwiftUI
import AVFoundation
import ARKit

struct Diag_DepthSensorView: View {
    @State private var hasDepthSensor = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Depth Sensor") {
                VStack(spacing: 12) {
                    Image(systemName: hasDepthSensor ? "cube.transparent.fill" : "cube.transparent")
                        .font(.system(size: 52))
                        .foregroundStyle(hasDepthSensor ? .blue : .secondary)
                    Text(hasDepthSensor ? "Depth Sensor Available" : "Depth Sensor Not Available")
                        .font(.headline)
                    Text("Tests TrueDepth, LiDAR, and dual-camera depth capabilities")
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

            Section("Depth Sources") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("TrueDepth — Front IR dot projector and camera", systemImage: "faceid")
                        .font(.caption)
                    Label("LiDAR — Time-of-Flight rear depth scanner", systemImage: "light.recessed.fill")
                        .font(.caption)
                    Label("Dual Camera — Stereo disparity depth", systemImage: "camera.on.rectangle.fill")
                        .font(.caption)
                    Label("Triple Camera — Extended depth from 3 lenses", systemImage: "camera.aperture")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Depth Uses") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Portrait mode background blur", systemImage: "person.crop.square.fill").font(.caption)
                    Label("Face ID authentication", systemImage: "faceid").font(.caption)
                    Label("Animoji and Memoji", systemImage: "face.smiling.fill").font(.caption)
                    Label("AR object placement", systemImage: "arkit").font(.caption)
                    Label("3D scanning and measurement", systemImage: "ruler.fill").font(.caption)
                    Label("People occlusion in AR", systemImage: "person.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkDepth() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Depth Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkDepth() }
    }

    private func checkDepth() {
        var info: [(String, String)] = []
        var anyDepth = false

        let hasTrueDepth = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) != nil
        info.append(("TrueDepth Camera", hasTrueDepth ? "Detected" : "Not detected"))
        if hasTrueDepth { anyDepth = true }

        let hasLiDAR = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
        info.append(("LiDAR Depth Camera", hasLiDAR ? "Detected" : "Not detected"))
        if hasLiDAR { anyDepth = true }

        let hasDualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil
        info.append(("Dual Camera (Stereo Depth)", hasDualCamera ? "Detected" : "Not detected"))
        if hasDualCamera { anyDepth = true }

        let hasDualWide = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil
        info.append(("Dual Wide Camera", hasDualWide ? "Detected" : "Not detected"))
        if hasDualWide { anyDepth = true }

        let hasTriple = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil
        info.append(("Triple Camera", hasTriple ? "Detected" : "Not detected"))
        if hasTriple { anyDepth = true }

        let supportsSceneDepth = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        info.append(("AR Scene Depth", supportsSceneDepth ? "Supported" : "Not supported"))

        let supportsFaceTracking = ARFaceTrackingConfiguration.isSupported
        info.append(("Face Tracking (Depth)", supportsFaceTracking ? "Supported" : "Not supported"))
        if supportsFaceTracking { anyDepth = true }

        hasDepthSensor = anyDepth
        details = info
    }
}
