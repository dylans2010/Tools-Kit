import SwiftUI
import CoreMotion

struct Diag_SensorAttitudeQuaternionView: View {
    @State private var x = 0.0
    @State private var y = 0.0
    @State private var z = 0.0
    @State private var w = 0.0
    @State private var isRunning = false
    private let manager = CMMotionManager()

    var body: some View {
        Form {
            Section("Quaternion") {
                LabeledContent("X") { Text(String(format: "%.3f", x)).monospacedDigit() }
                LabeledContent("Y") { Text(String(format: "%.3f", y)).monospacedDigit() }
                LabeledContent("Z") { Text(String(format: "%.3f", z)).monospacedDigit() }
                LabeledContent("W") { Text(String(format: "%.3f", w)).monospacedDigit() }
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
        .navigationTitle("Attitude Quaternion")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private func start() {
        guard manager.isDeviceMotionAvailable else { return }
        isRunning = true
        manager.startDeviceMotionUpdates(to: .main) { data, _ in guard let d = data else { return }; x = d.attitude.quaternion.x; y = d.attitude.quaternion.y; z = d.attitude.quaternion.z; w = d.attitude.quaternion.w }
    }

    private func stop() {
        manager.stopDeviceMotionUpdates()
        isRunning = false
    }
}
