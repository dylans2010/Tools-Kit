import SwiftUI
import CoreMotion

struct Diag_SensorAttitudeEulerView: View {
    @State private var x = 0.0
    @State private var y = 0.0
    @State private var z = 0.0
    @State private var w = 0.0
    @State private var isRunning = false
    private let manager = CMMotionManager()

    var body: some View {
        Form {
            Section("Attitude (Euler)") {
                LabeledContent("Pitch (rad)") { Text(String(format: "%.3f", x)).monospacedDigit() }
                LabeledContent("Roll (rad)") { Text(String(format: "%.3f", y)).monospacedDigit() }
                LabeledContent("Yaw (rad)") { Text(String(format: "%.3f", z)).monospacedDigit() }
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
        .navigationTitle("Attitude")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private func start() {
        guard manager.isDeviceMotionAvailable else { return }
        isRunning = true
        manager.startDeviceMotionUpdates(to: .main) { data, _ in guard let d = data else { return }; x = d.attitude.pitch; y = d.attitude.roll; z = d.attitude.yaw }
    }

    private func stop() {
        manager.stopDeviceMotionUpdates()
        isRunning = false
    }
}
