import SwiftUI
import CoreMotion

struct Diag_SensorRotationRateView: View {
    @State private var x = 0.0
    @State private var y = 0.0
    @State private var z = 0.0
    @State private var w = 0.0
    @State private var isRunning = false
    private let manager = CMMotionManager()

    var body: some View {
        Form {
            Section("Rotation Rate") {
                LabeledContent("X (rad/s)") { Text(String(format: "%.3f", x)).monospacedDigit() }
                LabeledContent("Y (rad/s)") { Text(String(format: "%.3f", y)).monospacedDigit() }
                LabeledContent("Z (rad/s)") { Text(String(format: "%.3f", z)).monospacedDigit() }
            }
            Section {
                Button {
                    if isRunning { stop() } else { start() }
                } label: {
                    HStack { Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill"); Text(isRunning ? "Stop" : "Start") }
                }
                .disabled(!manager.isGyroAvailable)
            }
        }
        .navigationTitle("Rotation Rate")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private func start() {
        guard manager.isGyroAvailable else { return }
        isRunning = true
        manager.startGyroUpdates(to: .main) { data, _ in guard let d = data else { return }; x = d.rotationRate.x; y = d.rotationRate.y; z = d.rotationRate.z }
    }

    private func stop() {
        manager.stopGyroUpdates()
        isRunning = false
    }
}
