import SwiftUI
import CoreMotion

struct Diag_SensorMagneticFieldView: View {
    @State private var x = 0.0
    @State private var y = 0.0
    @State private var z = 0.0
    @State private var w = 0.0
    @State private var isRunning = false
    private let manager = CMMotionManager()

    var body: some View {
        Form {
            Section("Magnetic Field") {
                LabeledContent("X (uT)") { Text(String(format: "%.3f", x)).monospacedDigit() }
                LabeledContent("Y (uT)") { Text(String(format: "%.3f", y)).monospacedDigit() }
                LabeledContent("Z (uT)") { Text(String(format: "%.3f", z)).monospacedDigit() }
            }
            Section {
                Button {
                    if isRunning { stop() } else { start() }
                } label: {
                    HStack { Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill"); Text(isRunning ? "Stop" : "Start") }
                }
                .disabled(!manager.isMagnetometerAvailable)
            }
        }
        .navigationTitle("Magnetic Field")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private func start() {
        guard manager.isMagnetometerAvailable else { return }
        isRunning = true
        manager.startMagnetometerUpdates(to: .main) { data, _ in guard let d = data else { return }; x = d.magneticField.x; y = d.magneticField.y; z = d.magneticField.z }
    }

    private func stop() {
        manager.stopMagnetometerUpdates()
        isRunning = false
    }
}
