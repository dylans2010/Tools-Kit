import SwiftUI
import CoreHaptics

struct Diag_PatternPlaybackView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var isPlaying = false

    private let patterns: [(String, String, [CHHapticEvent])] = {
        var result: [(String, String, [CHHapticEvent])] = []

        // Heartbeat
        let heartbeat: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ], relativeTime: 0.15),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ], relativeTime: 0.8),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ], relativeTime: 0.95),
        ]
        result.append(("Heartbeat", "heart.fill", heartbeat))

        // Rapid taps
        var rapid: [CHHapticEvent] = []
        for i in 0..<8 {
            rapid.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: Double(i) * 0.1))
        }
        result.append(("Rapid Taps", "hand.tap.fill", rapid))

        // Crescendo
        var crescendo: [CHHapticEvent] = []
        for i in 0..<6 {
            let intensity = Float(i + 1) / 6.0
            crescendo.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: intensity * 0.8)
            ], relativeTime: Double(i) * 0.2))
        }
        result.append(("Crescendo", "waveform.path.ecg", crescendo))

        // SOS
        var sos: [CHHapticEvent] = []
        let dotDuration = 0.1
        let dashDuration = 0.3
        let morse: [Double] = [dotDuration, dotDuration, dotDuration, dashDuration, dashDuration, dashDuration, dotDuration, dotDuration, dotDuration]
        var time = 0.0
        for dur in morse {
            sos.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: time, duration: dur))
            time += dur + 0.15
        }
        result.append(("SOS", "sos", sos))

        return result
    }()

    var body: some View {
        Form {
            Section("Haptic Patterns") {
                if !service.supportsHaptics {
                    Text("Haptics not supported on this device")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(patterns, id: \.0) { name, icon, events in
                        Button {
                            service.playHapticPattern(events: events)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(.pink)
                                    .frame(width: 36)
                                VStack(alignment: .leading) {
                                    Text(name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("\(events.count) haptic events")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section {
                Text("Tap any pattern to feel it play. Each pattern uses different combinations of haptic intensity, sharpness, and timing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Pattern Playback")
        .navigationBarTitleDisplayMode(.inline)
    }
}
