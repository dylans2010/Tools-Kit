import SwiftUI
import AVFoundation

struct Diag_TrueToneFlashView: View {
    @State private var hasFlash = false
    @State private var isTorchOn = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("True Tone Flash") {
                VStack(spacing: 12) {
                    Image(systemName: hasFlash ? "bolt.circle.fill" : "bolt.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(hasFlash ? .yellow : .secondary)
                    Text(hasFlash ? "True Tone Flash Available" : "Flash Not Available")
                        .font(.headline)
                    Text("Adaptive True Tone LED flash with ambient color temperature matching")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Flash Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Flash Test") {
                Button {
                    toggleTorch()
                } label: {
                    HStack {
                        Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        Text(isTorchOn ? "Turn Off Flash" : "Turn On Flash")
                    }
                }
                .disabled(!hasFlash)
            }

            Section("True Tone Flash Info") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Dual LED warm/cool color temperature", systemImage: "sun.max.fill").font(.caption)
                    Label("Over 1000 combinations of color and intensity", systemImage: "paintpalette.fill").font(.caption)
                    Label("Ambient light color temperature matching", systemImage: "circle.lefthalf.filled").font(.caption)
                    Label("Adaptive flash (iPhone 14 Pro+)", systemImage: "bolt.fill").font(.caption)
                    Label("Slow Sync flash for background exposure", systemImage: "camera.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkFlash() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("True Tone Flash")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkFlash() }
        .onDisappear { turnOffTorch() }
    }

    private func checkFlash() {
        var info: [(String, String)] = []

        if let device = AVCaptureDevice.default(for: .video) {
            hasFlash = device.hasFlash
            info.append(("Flash", device.hasFlash ? "Available" : "Not available"))
            info.append(("Torch", device.hasTorch ? "Available" : "Not available"))
            info.append(("Torch Level", String(format: "%.0f%%", device.torchLevel * 100)))
            info.append(("Max Torch Level", "100%"))

            let modes: [(String, AVCaptureDevice.FlashMode)] = [
                ("Auto Flash", .auto),
                ("Flash On", .on),
                ("Flash Off", .off)
            ]
            for (name, mode) in modes {
                info.append((name, device.isFlashModeSupported(mode) ? "Supported" : "Not supported"))
            }
        } else {
            hasFlash = false
            info.append(("Flash", "No camera device found"))
        }

        details = info
    }

    private func toggleTorch() {
        if isTorchOn { turnOffTorch() } else { turnOnTorch() }
    }

    private func turnOnTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: 1.0)
            device.unlockForConfiguration()
            isTorchOn = true
        } catch {}
    }

    private func turnOffTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
            isTorchOn = false
        } catch {}
    }
}
