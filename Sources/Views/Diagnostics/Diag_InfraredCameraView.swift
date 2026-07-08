import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_InfraredCameraView: View {
    @State private var hasInfrared = false
    @State private var hasTrueDepth = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Infrared Camera") {
                VStack(spacing: 12) {
                    Image(systemName: hasInfrared ? "camera.filters" : "camera")
                        .font(.system(size: 52))
                        .foregroundStyle(hasInfrared ? .red : .secondary)
                    Text(hasInfrared ? "Infrared Sensor Detected" : "Infrared Not Available")
                        .font(.headline)
                    Text("Infrared emitter/sensor used by Face ID and TrueDepth system")
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

            Section("Infrared Components") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Flood illuminator — IR light for Face ID", systemImage: "light.max")
                        .font(.caption)
                    Label("Dot projector — 30,000+ IR dots for depth mapping", systemImage: "circle.grid.3x3.fill")
                        .font(.caption)
                    Label("Infrared camera — reads dot pattern for Face ID", systemImage: "camera.filters")
                        .font(.caption)
                    Label("Used for Face ID, Animoji, Portrait selfies", systemImage: "faceid")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Uses") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Face ID authentication", systemImage: "faceid")
                        .font(.caption)
                    Label("Animoji and Memoji tracking", systemImage: "face.smiling.fill")
                        .font(.caption)
                    Label("Portrait mode on front camera", systemImage: "person.crop.square.fill")
                        .font(.caption)
                    Label("Attention awareness", systemImage: "eye.fill")
                        .font(.caption)
                    Label("ARKit face tracking", systemImage: "arkit")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkInfrared() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Infrared Camera")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkInfrared() }
    }

    private func checkInfrared() {
        var info: [(String, String)] = []

        let frontDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices

        hasTrueDepth = frontDevices.contains { $0.deviceType == .builtInTrueDepthCamera }
        hasInfrared = hasTrueDepth

        info.append(("TrueDepth Camera", hasTrueDepth ? "Detected" : "Not detected"))
        info.append(("Infrared Emitter", hasInfrared ? "Present" : "Not detected"))
        info.append(("Dot Projector", hasInfrared ? "Present" : "Not detected"))
        info.append(("Flood Illuminator", hasInfrared ? "Present" : "Not detected"))

        if let front = frontDevices.first {
            info.append(("Front Camera", front.localizedName))
            let formats = front.formats
            info.append(("Format Count", "\(formats.count)"))
        }

        let hasFaceID = hasTrueDepth
        info.append(("Face ID Hardware", hasFaceID ? "Available" : "Not available"))

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
