import SwiftUI
import AVFoundation

struct Diag_CinematicModeView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Cinematic Mode") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "video.fill" : "video")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .indigo : .secondary)
                    Text(supported ? "Cinematic Mode Available" : "Cinematic Mode Not Available")
                        .font(.headline)
                    Text("Rack focus video with depth-of-field blur and focus transitions")
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

            Section("Cinematic Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Automatic rack focus between subjects", systemImage: "video.fill")
                        .font(.caption)
                    Label("Adjustable depth of field after recording", systemImage: "slider.horizontal.3")
                        .font(.caption)
                    Label("Post-capture focus point changes", systemImage: "camera.metering.center.weighted")
                        .font(.caption)
                    Label("4K Cinematic at 30fps (iPhone 14+)", systemImage: "4k.tv.fill")
                        .font(.caption)
                    Label("4K Cinematic at 24fps (iPhone 14+)", systemImage: "film.fill")
                        .font(.caption)
                    Label("1080p at 30fps (iPhone 13)", systemImage: "play.rectangle.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 13 (all models)", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 14 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkCinematic() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Cinematic Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkCinematic() }
    }

    private func checkCinematic() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let cinematicModels = [
            "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5",
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        supported = cinematicModels.contains(modelId)

        info.append(("Cinematic Mode", supported ? "Supported" : "Not Supported"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        let hasDualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil
        info.append(("Dual Camera", hasDualCamera ? "Available" : "Not available"))

        let hasTriple = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil
        info.append(("Triple Camera", hasTriple ? "Available" : "Not available"))

        details = info
    }
}
