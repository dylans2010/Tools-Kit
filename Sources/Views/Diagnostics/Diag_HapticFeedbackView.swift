import SwiftUI
import CoreHaptics

struct Diag_HapticFeedbackView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var intensity: Float = 0.5
    @State private var sharpness: Float = 0.5
    @State private var lastPlayed: String = ""

    var body: some View {
        Form {
            Section("Haptic Engine") {
                LabeledContent("Haptics Supported") {
                    Text(service.supportsHaptics ? "Yes" : "No")
                        .foregroundStyle(service.supportsHaptics ? .green : .red)
                }
            }

            Section("Custom Haptic") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Intensity: \(intensity, specifier: "%.2f")")
                        .font(.subheadline)
                    Slider(value: $intensity, in: 0...1, step: 0.05)

                    Text("Sharpness: \(sharpness, specifier: "%.2f")")
                        .font(.subheadline)
                    Slider(value: $sharpness, in: 0...1, step: 0.05)

                    Button {
                        service.playHaptic(intensity: intensity, sharpness: sharpness)
                        lastPlayed = "Custom (I: \(String(format: "%.2f", intensity)), S: \(String(format: "%.2f", sharpness)))"
                    } label: {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                            Text("Play Custom Haptic")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Preset Haptics") {
                Button("Light Impact") {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    lastPlayed = "Light Impact"
                }
                Button("Medium Impact") {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    lastPlayed = "Medium Impact"
                }
                Button("Heavy Impact") {
                    let gen = UIImpactFeedbackGenerator(style: .heavy)
                    gen.impactOccurred()
                    lastPlayed = "Heavy Impact"
                }
                Button("Rigid Impact") {
                    let gen = UIImpactFeedbackGenerator(style: .rigid)
                    gen.impactOccurred()
                    lastPlayed = "Rigid Impact"
                }
                Button("Soft Impact") {
                    let gen = UIImpactFeedbackGenerator(style: .soft)
                    gen.impactOccurred()
                    lastPlayed = "Soft Impact"
                }
                Button("Success Notification") {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)
                    lastPlayed = "Success"
                }
                Button("Warning Notification") {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.warning)
                    lastPlayed = "Warning"
                }
                Button("Error Notification") {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.error)
                    lastPlayed = "Error"
                }
                Button("Selection Changed") {
                    let gen = UISelectionFeedbackGenerator()
                    gen.selectionChanged()
                    lastPlayed = "Selection"
                }
            }

            if !lastPlayed.isEmpty {
                Section("Last Played") {
                    Text(lastPlayed)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Haptic Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}
