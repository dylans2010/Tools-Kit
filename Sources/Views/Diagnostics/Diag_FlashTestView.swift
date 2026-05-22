import SwiftUI
import AVFoundation

struct Diag_FlashTestView: View {
    @State private var isFlashOn = false
    @State private var flashAvailable = false
    @State private var torchLevel: Float = 1.0

    var body: some View {
        Form {
            Section("Flash / Torch") {
                VStack(spacing: 16) {
                    Image(systemName: isFlashOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(isFlashOn ? .yellow : .secondary)
                        .animation(.easeInOut, value: isFlashOn)

                    Text(isFlashOn ? "Torch ON" : "Torch OFF")
                        .font(.title2.bold())

                    if !flashAvailable {
                        Text("Flash/Torch not available on this device")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            if flashAvailable {
                Section("Torch Level") {
                    VStack(alignment: .leading, spacing: 8) {
                        Slider(value: $torchLevel, in: 0.1...1.0, step: 0.05)
                            .onChange(of: torchLevel) { _, newVal in
                                if isFlashOn { setTorch(on: true, level: newVal) }
                            }
                        Text("\(Int(torchLevel * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Section {
                    Button {
                        isFlashOn.toggle()
                        setTorch(on: isFlashOn, level: torchLevel)
                    } label: {
                        HStack {
                            Image(systemName: isFlashOn ? "flashlight.off.fill" : "flashlight.on.fill")
                            Text(isFlashOn ? "Turn Off" : "Turn On")
                        }
                    }
                }

                Section("Quick Tests") {
                    Button("Flash Strobe (3x)") {
                        strobeFlash(times: 3)
                    }
                    .disabled(isFlashOn)

                    Button("Brightness Ramp") {
                        brightnessRamp()
                    }
                    .disabled(isFlashOn)
                }
            }
        }
        .navigationTitle("Flash Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkFlash() }
        .onDisappear { setTorch(on: false, level: 0) }
    }

    private func checkFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            flashAvailable = false
            return
        }
        flashAvailable = device.hasTorch && device.isTorchAvailable
    }

    private func setTorch(on: Bool, level: Float) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: max(0.01, level))
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {}
    }

    private func strobeFlash(times: Int) {
        Task {
            for _ in 0..<times {
                await MainActor.run { setTorch(on: true, level: 1.0) }
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run { setTorch(on: false, level: 0) }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }

    private func brightnessRamp() {
        Task {
            for i in stride(from: Float(0.1), through: 1.0, by: 0.1) {
                await MainActor.run { setTorch(on: true, level: i) }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run { setTorch(on: false, level: 0) }
        }
    }
}
