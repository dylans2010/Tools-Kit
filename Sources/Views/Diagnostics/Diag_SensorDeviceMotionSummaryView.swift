import SwiftUI
import CoreMotion

struct Diag_SensorDeviceMotionSummaryView: View {
    @State private var x = 0.0
    @State private var y = 0.0
    @State private var z = 0.0
    @State private var w = 0.0
    @State private var isRunning = false
    private let manager = CMMotionManager()

    var body: some View {
        Form {
            Section("Device Motion") {
                LabeledContent("User Accel X") { Text(String(format: "%.3f", x)).monospacedDigit() }
                LabeledContent("User Accel Y") { Text(String(format: "%.3f", y)).monospacedDigit() }
                LabeledContent("Rotation Z") { Text(String(format: "%.3f", z)).monospacedDigit() }
            }
            Section {
                Button {
                    if isRunning { stop() } else { start() }
                } label: {
                    HStack { Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill"); Text(isRunning ? "Stop" : "Start") }
                }
                .disabled(!manager.isDeviceMotionAvailable)
            }
        }
        .navigationTitle("Device Motion")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private func start() {
        guard manager.isDeviceMotionAvailable else { return }
        isRunning = true
        manager.startDeviceMotionUpdates(to: .main) { data, _ in guard let d = data else { return }; x = d.userAcceleration.x; y = d.userAcceleration.y; z = d.rotationRate.z }
    }

    private func stop() {
        manager.stopDeviceMotionUpdates()
        isRunning = false
    }
}
