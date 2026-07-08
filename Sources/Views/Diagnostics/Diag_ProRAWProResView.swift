import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_ProRAWProResView: View {
    @State private var supportsProRAW = false
    @State private var supportsProRes = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("ProRAW & ProRes") {
                VStack(spacing: 12) {
                    Image(systemName: (supportsProRAW || supportsProRes) ? "camera.badge.ellipsis.fill" : "camera.badge.ellipsis")
                        .font(.system(size: 52))
                        .foregroundStyle((supportsProRAW || supportsProRes) ? .indigo : .secondary)
                    Text(supportsProRAW || supportsProRes ? "Pro Formats Available" : "Pro Formats Not Available")
                        .font(.headline)
                    Text("Apple ProRAW photography and ProRes video recording capabilities")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Format Support") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("ProRAW Details") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("48MP Apple ProRAW (iPhone 14 Pro+)", systemImage: "photo.fill").font(.caption)
                    Label("DNG format with computational data", systemImage: "doc.fill").font(.caption)
                    Label("Full manual control over processing", systemImage: "slider.horizontal.3").font(.caption)
                    Label("12-bit color depth", systemImage: "paintpalette.fill").font(.caption)
                    Label("~75MB per photo at 48MP", systemImage: "internaldrive.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("ProRes Details") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("ProRes 422 HQ video codec", systemImage: "video.fill").font(.caption)
                    Label("4K at up to 30fps (iPhone 13 Pro+)", systemImage: "4k.tv.fill").font(.caption)
                    Label("Professional editing workflow", systemImage: "film.fill").font(.caption)
                    Label("~6GB per minute at 4K", systemImage: "internaldrive.fill").font(.caption)
                    Label("Log encoding support (iPhone 15 Pro+)", systemImage: "waveform").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("ProRAW: iPhone 12 Pro and later Pro models", systemImage: "iphone.gen2").font(.caption)
                    Label("ProRes: iPhone 13 Pro and later Pro models", systemImage: "iphone.gen2").font(.caption)
                    Label("48MP ProRAW: iPhone 14 Pro and later Pro models", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkProFormats() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("ProRAW & ProRes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkProFormats() }
    }

    private func checkProFormats() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            let formats = device.formats
            let hasProRes = formats.contains { format in
                let codecType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
                return codecType == kCMVideoCodecType_AppleProRes422 ||
                       codecType == kCMVideoCodecType_AppleProRes422HQ ||
                       codecType == kCMVideoCodecType_AppleProRes422LT
            }
            supportsProRes = hasProRes
            info.append(("ProRes Recording", hasProRes ? "Supported" : "Not Supported"))

            let maxRes = formats.compactMap { CMVideoFormatDescriptionGetDimensions($0.formatDescription) }.max { $0.width * $0.height < $1.width * $1.height }
            if let res = maxRes {
                info.append(("Max Resolution", "\(res.width) x \(res.height)"))
            }
        }

        let proRAWModels = [
            "iPhone13,3", "iPhone13,4",
            "iPhone14,2", "iPhone14,3",
            "iPhone15,2", "iPhone15,3",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4"
        ]
        supportsProRAW = proRAWModels.contains(modelId)
        info.append(("ProRAW Photography", supportsProRAW ? "Supported" : "Not Supported"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
