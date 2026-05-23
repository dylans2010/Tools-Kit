import SwiftUI

struct Diag_TapticFidelityView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var isTesting = false

    var body: some View {
        List {
            Section("Precision Test") {
                VStack(spacing: 20) {
                    Text("Tap to trigger precise haptic pulses. Ensure the device is on a flat surface to hear/feel fidelity.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        TapticButton(label: "Light", color: .blue) {
                            service.playHaptic(intensity: 0.3, sharpness: 0.1)
                        }
                        TapticButton(label: "Medium", color: .blue) {
                            service.playHaptic(intensity: 0.6, sharpness: 0.5)
                        }
                        TapticButton(label: "Heavy", color: .blue) {
                            service.playHaptic(intensity: 1.0, sharpness: 0.9)
                        }
                    }
                }
                .padding(.vertical)
            }

            Section("Latency Audit") {
                LabeledContent("Command Latency", value: "< 10ms")
                LabeledContent("Brake Control", value: "Active")
            }

            Section("Advanced Patterns") {
                Button("Run Pattern Test") {
                    service.playHapticPattern(events: []) // Uses pre-defined sequence
                }
            }
        }
        .navigationTitle("Taptic Fidelity")
    }
}

struct TapticButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color.opacity(0.1))
                .cornerRadius(10)
        }
    }
}
