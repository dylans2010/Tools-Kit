import SwiftUI
import CoreHaptics
import AudioToolbox
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_VibrationMotorView: View {
    @State private var engine: CHHapticEngine?
    @State private var supportsHaptics = false
    @State private var isPlaying = false
    @State private var selectedIntensity: Float = 0.8
    @State private var selectedSharpness: Float = 0.5
    @State private var selectedDuration: Double = 0.5
    @State private var statusText = "Ready"
    @State private var testResults: [TestResult] = []

    struct TestResult: Identifiable {
        let id = UUID()
        let name: String
        let passed: Bool
        let detail: String
    }

    var body: some View {
        Form {
            Section("Hardware Status") {
                LabeledContent("Haptic Engine") {
                    HStack(spacing: 4) {
                        Image(systemName: supportsHaptics ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(supportsHaptics ? .green : .red)
                        Text(supportsHaptics ? "Supported" : "Not Available")
                    }
                }
                LabeledContent("Engine State") {
                    Text(engine != nil ? "Initialized" : "Not Started")
                        .foregroundStyle(engine != nil ? .green : .secondary)
                }
            }

            Section("Custom Vibration") {
                VStack(alignment: .leading) {
                    Text("Intensity: \(Int(selectedIntensity * 100))%")
                        .font(.subheadline)
                    Slider(value: $selectedIntensity, in: 0...1, step: 0.05)
                        .tint(.blue)
                }

                VStack(alignment: .leading) {
                    Text("Sharpness: \(Int(selectedSharpness * 100))%")
                        .font(.subheadline)
                    Slider(value: $selectedSharpness, in: 0...1, step: 0.05)
                        .tint(.purple)
                }

                VStack(alignment: .leading) {
                    Text("Duration: \(String(format: "%.1fs", selectedDuration))")
                        .font(.subheadline)
                    Slider(value: $selectedDuration, in: 0.1...2.0, step: 0.1)
                        .tint(.orange)
                }

                Button {
                    playCustomHaptic()
                } label: {
                    HStack {
                        Image(systemName: "waveform")
                        Text("Play Custom Vibration")
                    }
                }
                .disabled(!supportsHaptics)
            }

            Section("Preset Tests") {
                Button { playPreset(.light) } label: {
                    Label("Light Tap", systemImage: "hand.tap")
                }
                Button { playPreset(.medium) } label: {
                    Label("Medium Tap", systemImage: "hand.tap.fill")
                }
                Button { playPreset(.heavy) } label: {
                    Label("Heavy Tap", systemImage: "hand.point.up.left.fill")
                }
                Button { playPattern() } label: {
                    Label("Rhythmic Pattern", systemImage: "waveform.path")
                }
                Button { playLegacyVibration() } label: {
                    Label("Legacy Vibration (AudioToolbox)", systemImage: "iphone.radiowaves.left.and.right")
                }
            }

            Section {
                Button {
                    runFullDiagnostic()
                } label: {
                    HStack {
                        Image(systemName: "stethoscope")
                        Text("Run Full Motor Diagnostic")
                    }
                }
            }

            if !testResults.isEmpty {
                Section("Diagnostic Results") {
                    ForEach(testResults, id: \.id) { result in
                        HStack {
                            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.passed ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(result.name)
                                    .font(.subheadline)
                                Text(result.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Vibration Motor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupEngine()
        }
    }

    private func setupEngine() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else {
            statusText = "This device does not support haptics"
            return
        }

        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { _ in
                DispatchQueue.main.async {
                    statusText = "Engine stopped"
                }
            }
            engine?.resetHandler = {
                do {
                    try self.engine?.start()
                } catch {
                    // Engine restart failed
                }
            }
            try engine?.start()
            statusText = "Haptic engine ready"
        } catch {
            statusText = "Failed to initialize: \(error.localizedDescription)"
        }
    }

    private func playCustomHaptic() {
        guard let engine = engine else { return }
        isPlaying = true
        statusText = "Playing custom haptic..."

        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: selectedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: selectedSharpness)
                ],
                relativeTime: 0,
                duration: selectedDuration
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            statusText = "Played: intensity=\(Int(selectedIntensity * 100))%, sharpness=\(Int(selectedSharpness * 100))%, duration=\(String(format: "%.1fs", selectedDuration))"
        } catch {
            statusText = "Error: \(error.localizedDescription)"
        }
        isPlaying = false
    }

    private func playPreset(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        statusText = "Played \(style == .light ? "light" : style == .medium ? "medium" : "heavy") impact"
    }

    private func playPattern() {
        guard let engine = engine else { return }

        do {
            var events: [CHHapticEvent] = []
            for i in 0..<6 {
                let time = TimeInterval(i) * 0.15
                let intensity = Float(i % 2 == 0 ? 1.0 : 0.5)
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: time
                ))
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            statusText = "Played rhythmic pattern (6 taps)"
        } catch {
            statusText = "Pattern error: \(error.localizedDescription)"
        }
    }

    private func playLegacyVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        statusText = "Played legacy vibration via AudioToolbox"
    }

    private func runFullDiagnostic() {
        testResults = []
        statusText = "Running diagnostics..."

        // Test 1: Engine availability
        testResults.append(TestResult(
            name: "Haptic Hardware",
            passed: supportsHaptics,
            detail: supportsHaptics ? "Taptic Engine detected" : "No haptic hardware found"
        ))

        // Test 2: Engine initialization
        testResults.append(TestResult(
            name: "Engine Init",
            passed: engine != nil,
            detail: engine != nil ? "CHHapticEngine started successfully" : "Failed to create engine"
        ))

        // Test 3: Transient haptic
        var transientOK = false
        if let engine = engine {
            do {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                )
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
                transientOK = true
            } catch {}
        }
        testResults.append(TestResult(
            name: "Transient Haptic",
            passed: transientOK,
            detail: transientOK ? "Single tap executed" : "Failed to play transient"
        ))

        // Test 4: Continuous haptic
        var continuousOK = false
        if let engine = engine {
            do {
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.3,
                    duration: 0.3
                )
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
                continuousOK = true
            } catch {}
        }
        testResults.append(TestResult(
            name: "Continuous Haptic",
            passed: continuousOK,
            detail: continuousOK ? "Sustained vibration executed" : "Failed to play continuous"
        ))

        // Test 5: Legacy vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        testResults.append(TestResult(
            name: "Legacy Vibration",
            passed: true,
            detail: "AudioToolbox vibration triggered"
        ))

        // Test 6: UIKit feedback generators
        let notif = UINotificationFeedbackGenerator()
        notif.prepare()
        notif.notificationOccurred(.success)
        testResults.append(TestResult(
            name: "UIKit Feedback",
            passed: true,
            detail: "UINotificationFeedbackGenerator success feedback"
        ))

        statusText = "Diagnostics complete — \(testResults.filter { $0.passed }.count)/\(testResults.count) passed"
    }
}
