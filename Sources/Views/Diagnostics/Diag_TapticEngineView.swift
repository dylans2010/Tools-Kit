import SwiftUI
import CoreHaptics

struct Diag_TapticEngineView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var testResults: [(String, Bool)] = []
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Taptic Engine Status") {
                VStack(spacing: 12) {
                    Image(systemName: service.supportsHaptics ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(service.supportsHaptics ? .green : .red)

                    Text(service.supportsHaptics ? "Taptic Engine Available" : "Taptic Engine Not Available")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            if service.supportsHaptics {
                Section("Diagnostic Tests") {
                    Button {
                        runDiagnostics()
                    } label: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                            Text(isTesting ? "Running Tests..." : "Run Full Diagnostic")
                        }
                    }
                    .disabled(isTesting)
                }

                if !testResults.isEmpty {
                    Section("Results") {
                        ForEach(testResults, id: \.0) { name, passed in
                            HStack {
                                Text(name)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(passed ? .green : .red)
                            }
                        }
                    }
                }
            }

            Section("Engine Capabilities") {
                let caps = CHHapticEngine.capabilitiesForHardware()
                LabeledContent("Haptics") {
                    Text(caps.supportsHaptics ? "Supported" : "Not Supported")
                }
                LabeledContent("Audio") {
                    Text(caps.supportsAudio ? "Supported" : "Not Supported")
                }
            }
        }
        .navigationTitle("Taptic Engine Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runDiagnostics() {
        isTesting = true
        testResults.removeAll()

        testResults.append(("Engine Initialization", testEngineInit()))
        testResults.append(("Transient Event", testTransient()))
        testResults.append(("Continuous Event", testContinuous()))
        testResults.append(("Pattern Creation", testPattern()))
        testResults.append(("Impact Feedback (Light)", testImpact(.light)))
        testResults.append(("Impact Feedback (Medium)", testImpact(.medium)))
        testResults.append(("Impact Feedback (Heavy)", testImpact(.heavy)))
        testResults.append(("Notification Feedback", testNotification()))

        isTesting = false
    }

    private func testEngineInit() -> Bool {
        do {
            let engine = try CHHapticEngine()
            try engine.start()
            engine.stop()
            return true
        } catch { return false }
    }

    private func testTransient() -> Bool {
        do {
            let engine = try CHHapticEngine()
            try engine.start()
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let _ = try engine.makePlayer(with: pattern)
            return true
        } catch { return false }
    }

    private func testContinuous() -> Bool {
        do {
            let engine = try CHHapticEngine()
            try engine.start()
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0, duration: 0.5)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let _ = try engine.makePlayer(with: pattern)
            return true
        } catch { return false }
    }

    private func testPattern() -> Bool {
        do {
            var events: [CHHapticEvent] = []
            for i in 0..<3 {
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i + 1) / 3.0)
                ], relativeTime: Double(i) * 0.2))
            }
            let _ = try CHHapticPattern(events: events, parameters: [])
            return true
        } catch { return false }
    }

    private func testImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> Bool {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
        return true
    }

    private func testNotification() -> Bool {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
        return true
    }
}
