import SwiftUI
import CoreMotion

struct Diag_SensorUserAccelerationView: View {
    @State private var x = 0.0
    @State private var y = 0.0
    @State private var z = 0.0
    @State private var w = 0.0
    @State private var isRunning = false
    private let manager = CMMotionManager()

    var body: some View {
        Form {
            Section("User Acceleration") {
                LabeledContent("X") { Text(String(format: "%.3f", x)).monospacedDigit() }
                LabeledContent("Y") { Text(String(format: "%.3f", y)).monospacedDigit() }
                LabeledContent("Z") { Text(String(format: "%.3f", z)).monospacedDigit() }
            }
            Section {
                Button {
                    if isRunning { stop() } else { start() }
                } label: {
                    HStack { Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill"); Text(isRunning ? "Stop" : "Start") }
                }
                .disabled(!manager.isAccelerometerAvailable)
            }
        }
        .navigationTitle("User Acceleration")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private func start() {
        guard manager.isAccelerometerAvailable else { return }
        isRunning = true
        manager.startAccelerometerUpdates(to: .main) { data, _ in guard let d = data else { return }; x = d.acceleration.x; y = d.acceleration.y; z = d.acceleration.z }
    }

    private func stop() {
        manager.stopAccelerometerUpdates()
        isRunning = false
    }
}
