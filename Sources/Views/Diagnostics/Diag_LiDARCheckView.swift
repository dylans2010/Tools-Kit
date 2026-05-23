import SwiftUI
import ARKit

struct Diag_LiDARCheckView: View {
    @State private var hasLiDAR = false
    @State private var supportsSceneReconstruction = false
    @State private var supportsObjectPlacement = false
    @State private var arSupported = false

    var body: some View {
        Form {
            Section("LiDAR Scanner") {
                VStack(spacing: 12) {
                    Image(systemName: hasLiDAR ? "dot.radiowaves.left.and.right" : "dot.radiowaves.right")
                        .font(.system(size: 52))
                        .foregroundStyle(hasLiDAR ? .green : .secondary)
                    Text(hasLiDAR ? "LiDAR Available" : "LiDAR Not Available")
                        .font(.headline)
                    Text(hasLiDAR ? "Your device has a LiDAR depth scanner" : "This device does not have a LiDAR scanner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("AR Capabilities") {
                LabeledContent("ARKit Supported") {
                    Text(arSupported ? "Yes" : "No")
                        .foregroundStyle(arSupported ? .green : .red)
                }
                LabeledContent("Scene Reconstruction") {
                    Text(supportsSceneReconstruction ? "Supported" : "Not Supported")
                        .foregroundStyle(supportsSceneReconstruction ? .green : .secondary)
                }
                LabeledContent("Object Placement") {
                    Text(supportsObjectPlacement ? "Supported" : "Not Supported")
                        .foregroundStyle(supportsObjectPlacement ? .green : .secondary)
                }
            }

            Section("Depth Sensing") {
                LabeledContent("Depth API") {
                    Text(hasLiDAR ? "Available" : "Unavailable")
                        .foregroundStyle(hasLiDAR ? .green : .secondary)
                }
                LabeledContent("Point Cloud") {
                    Text(hasLiDAR ? "Supported" : "Not Supported")
                        .foregroundStyle(hasLiDAR ? .green : .secondary)
                }
                LabeledContent("Mesh Generation") {
                    Text(supportsSceneReconstruction ? "Supported" : "Not Supported")
                        .foregroundStyle(supportsSceneReconstruction ? .green : .secondary)
                }
            }
        }
        .navigationTitle("LiDAR Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkCapabilities() }
    }

    private func checkCapabilities() {
        arSupported = ARWorldTrackingConfiguration.isSupported
        if ARWorldTrackingConfiguration.isSupported {
            let config = ARWorldTrackingConfiguration()
            supportsSceneReconstruction = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            hasLiDAR = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
            supportsObjectPlacement = ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth)
        }
    }
}
