import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_TrueDepthView: View {
    @State private var hasTrueDepth = false
    @State private var hasDepthCamera = false
    @State private var frontCameraFeatures: [String] = []
    @State private var supportsPortrait = false

    var body: some View {
        Form {
            Section("TrueDepth Camera") {
                VStack(spacing: 12) {
                    Image(systemName: hasTrueDepth ? "faceid" : "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(hasTrueDepth ? .green : .secondary)
                    Text(hasTrueDepth ? "TrueDepth Available" : "TrueDepth Not Detected")
                        .font(.headline)
                    Text(hasTrueDepth ? "Face ID and depth sensing supported" : "Standard front camera only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Capabilities") {
                LabeledContent("Depth Camera") {
                    Text(hasDepthCamera ? "Available" : "Not Available")
                        .foregroundStyle(hasDepthCamera ? .green : .secondary)
                }
                LabeledContent("Portrait Mode") {
                    Text(supportsPortrait ? "Supported" : "Not Supported")
                        .foregroundStyle(supportsPortrait ? .green : .secondary)
                }
                LabeledContent("Face ID") {
                    Text(hasTrueDepth ? "Supported" : "Not Available")
                        .foregroundStyle(hasTrueDepth ? .green : .secondary)
                }
                LabeledContent("Animoji") {
                    Text(hasTrueDepth ? "Supported" : "Not Available")
                        .foregroundStyle(hasTrueDepth ? .green : .secondary)
                }
            }

            Section("Front Camera Features") {
                if frontCameraFeatures.isEmpty {
                    Text("No additional features detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(frontCameraFeatures, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("TrueDepth Camera")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkCapabilities() }
    }

    private func checkCapabilities() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera],
            mediaType: .video,
            position: .front
        )
        hasTrueDepth = !discoverySession.devices.isEmpty
        hasDepthCamera = hasTrueDepth

        var features: [String] = []
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            features.append("Wide Angle Lens")
            if camera.activeFormat.isVideoHDRSupported { features.append("HDR Video") }
            if camera.hasFlash { features.append("Retina Flash") }
        }
        if hasTrueDepth {
            features.append("Depth Mapping")
            features.append("IR Flood Illuminator")
            features.append("Dot Projector")
            supportsPortrait = true
        }
        frontCameraFeatures = features
    }
}
