import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_ZoomRangeView: View {
    @State private var cameras: [CameraInfo] = []
    @State private var maxZoom: CGFloat = 1
    @State private var minZoom: CGFloat = 1
    @State private var hasUltraWide = false
    @State private var hasTelephoto = false

    struct CameraInfo: Identifiable {
        let id = UUID()
        let name: String
        let position: String
        let maxZoom: CGFloat
        let hasFlash: Bool
        let focalLength: Float
    }

    var body: some View {
        Form {
            Section("Zoom Capabilities") {
                VStack(spacing: 12) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 44))
                        .foregroundStyle(.indigo)
                    HStack(spacing: 20) {
                        VStack {
                            Text(String(format: "%.0fx", minZoom))
                                .font(.title3.bold())
                            Text("Min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack {
                            Text(String(format: "%.0fx", maxZoom))
                                .font(.title3.bold())
                            Text("Max")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Lens System") {
                LabeledContent("Ultra Wide") {
                    Text(hasUltraWide ? "Available" : "Not Available")
                        .foregroundStyle(hasUltraWide ? .green : .secondary)
                }
                LabeledContent("Wide (Main)") {
                    Text("Available").foregroundStyle(.green)
                }
                LabeledContent("Telephoto") {
                    Text(hasTelephoto ? "Available" : "Not Available")
                        .foregroundStyle(hasTelephoto ? .green : .secondary)
                }
            }

            Section("Cameras") {
                ForEach(cameras, id: \.id) { camera in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(camera.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(camera.position)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Max Zoom: \(String(format: "%.1fx", camera.maxZoom))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if camera.hasFlash {
                                Image(systemName: "bolt.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Zoom Range")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCameraInfo() }
    }

    private func loadCameraInfo() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .unspecified
        )

        var cameraList: [CameraInfo] = []
        var globalMax: CGFloat = 1

        for device in discoverySession.devices {
            let position = device.position == .front ? "Front" : "Back"
            let info = CameraInfo(
                name: device.localizedName,
                position: position,
                maxZoom: device.activeFormat.videoMaxZoomFactor,
                hasFlash: device.hasFlash,
                focalLength: device.activeFormat.videoFieldOfView
            )
            cameraList.append(info)
            globalMax = max(globalMax, device.activeFormat.videoMaxZoomFactor)

            if device.deviceType == .builtInUltraWideCamera { hasUltraWide = true }
            if device.deviceType == .builtInTelephotoCamera { hasTelephoto = true }
        }

        cameras = cameraList
        maxZoom = min(globalMax, 100)
        minZoom = 1
    }
}
