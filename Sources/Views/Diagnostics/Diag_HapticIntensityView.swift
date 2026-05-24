import SwiftUI
import CoreHaptics

struct Diag_HapticIntensityView: View {
    @State private var supportsHaptics = false
    @State private var engine: CHHapticEngine?
    @State private var intensity: Float = 0.5
    @State private var sharpness: Float = 0.5
    @State private var details: [(String, String)] = []
    @State private var lastPlayed = ""

    var body: some View {
        Form {
            Section("Haptic Intensity") {
                VStack(spacing: 12) {
                    Image(systemName: supportsHaptics ? "hand.tap.fill" : "hand.tap")
                        .font(.system(size: 52))
                        .foregroundStyle(supportsHaptics ? .pink : .secondary)
                    Text(supportsHaptics ? "Haptics Available" : "Haptics Not Available")
                        .font(.headline)
                    Text("Test haptic feedback at varying intensity and sharpness levels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Haptic Engine") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Custom Haptic") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Intensity: \(Int(intensity * 100))%")
                        .font(.caption)
                    Slider(value: $intensity, in: 0...1, step: 0.05)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sharpness: \(Int(sharpness * 100))%")
                        .font(.caption)
                    Slider(value: $sharpness, in: 0...1, step: 0.05)
                }
                Button {
                    playCustomHaptic()
                } label: {
                    HStack { Image(systemName: "hand.tap.fill"); Text("Play Custom Haptic") }
                }
                .disabled(!supportsHaptics)
            }

            Section("Preset Patterns") {
                Button { playPreset(intensity: 0.2, sharpness: 0.2, name: "Light Tap") } label: {
                    HStack { Image(systemName: "circle.fill").font(.caption); Text("Light Tap"); Spacer(); Text("20%").font(.caption).foregroundStyle(.secondary) }
                }.disabled(!supportsHaptics)
                Button { playPreset(intensity: 0.5, sharpness: 0.5, name: "Medium Tap") } label: {
                    HStack { Image(systemName: "circle.fill").font(.caption); Text("Medium Tap"); Spacer(); Text("50%").font(.caption).foregroundStyle(.secondary) }
                }.disabled(!supportsHaptics)
                Button { playPreset(intensity: 0.8, sharpness: 0.8, name: "Strong Tap") } label: {
                    HStack { Image(systemName: "circle.fill").font(.caption); Text("Strong Tap"); Spacer(); Text("80%").font(.caption).foregroundStyle(.secondary) }
                }.disabled(!supportsHaptics)
                Button { playPreset(intensity: 1.0, sharpness: 1.0, name: "Maximum") } label: {
                    HStack { Image(systemName: "circle.fill").font(.caption); Text("Maximum"); Spacer(); Text("100%").font(.caption).foregroundStyle(.secondary) }
                }.disabled(!supportsHaptics)
                Button { playContinuousHaptic() } label: {
                    HStack { Image(systemName: "waveform.path"); Text("Continuous Vibration (1s)") }
                }.disabled(!supportsHaptics)
            }

            if !lastPlayed.isEmpty {
                Section("Last Played") {
                    Text(lastPlayed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button { checkHaptics() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Haptic Intensity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkHaptics() }
    }

    private func checkHaptics() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        var info: [(String, String)] = []
        info.append(("Haptic Support", supportsHaptics ? "Available" : "Not Available"))
        info.append(("Supports Audio", CHHapticEngine.capabilitiesForHardware().supportsAudio ? "Yes" : "No"))

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))
        details = info

        prepareEngine()
    }

    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {}
    }

    private func playCustomHaptic() {
        playPreset(intensity: intensity, sharpness: sharpness, name: "Custom (\(Int(intensity * 100))%/\(Int(sharpness * 100))%)")
    }

    private func playPreset(intensity: Float, sharpness: Float, name: String) {
        guard let engine = engine else { prepareEngine(); return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            lastPlayed = name
        } catch {}
    }

    private func playContinuousHaptic() {
        guard let engine = engine else { prepareEngine(); return }
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: 1.0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            lastPlayed = "Continuous (1s)"
        } catch {}
    }
}
