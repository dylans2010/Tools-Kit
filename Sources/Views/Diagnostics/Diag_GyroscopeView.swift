import SwiftUI
import CoreMotion

struct Diag_GyroscopeView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var x: Double = 0
    @State private var y: Double = 0
    @State private var z: Double = 0
    @State private var isActive = false
    @State private var history: [(x: Double, y: Double, z: Double)] = []

    var body: some View {
        Form {
            Section("Rotation Rate (rad/s)") {
                VStack(spacing: 12) {
                    GyroAxisRow(label: "Pitch (X)", value: x, color: .red)
                    GyroAxisRow(label: "Roll (Y)", value: y, color: .green)
                    GyroAxisRow(label: "Yaw (Z)", value: z, color: .blue)
                }
                .padding(.vertical, 4)
            }

            Section("Live Graph") {
                Canvas { context, size in
                    guard history.count > 1 else { return }
                    let axes: [(KeyPath<(x: Double, y: Double, z: Double), Double>, Color)] = [
                        (\.x, .red), (\.y, .green), (\.z, .blue)
                    ]
                    for (keyPath, color) in axes {
                        var path = Path()
                        for (i, point) in history.enumerated() {
                            let xPos = CGFloat(i) / CGFloat(history.count - 1) * size.width
                            let value = point[keyPath: keyPath]
                            let yPos = size.height / 2 - CGFloat(value) * (size.height / 8)
                            if i == 0 { path.move(to: CGPoint(x: xPos, y: yPos)) }
                            else { path.addLine(to: CGPoint(x: xPos, y: yPos)) }
                        }
                        context.stroke(path, with: .color(color), lineWidth: 1.5)
                    }
                }
                .frame(height: 150)
            }

            Section("Sensor Status") {
                LabeledContent("Available") {
                    Text(service.isGyroAvailable ? "Yes" : "No")
                        .foregroundStyle(service.isGyroAvailable ? .green : .red)
                }
                LabeledContent("Total Rate") {
                    Text("\(sqrt(x*x + y*y + z*z), specifier: "%.3f") rad/s")
                        .monospacedDigit()
                }
            }

            Section {
                Button {
                    if isActive { stopSensor() } else { startSensor() }
                } label: {
                    HStack {
                        Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                        Text(isActive ? "Stop" : "Start Gyroscope")
                    }
                }
            }
        }
        .navigationTitle("Gyroscope")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopSensor() }
    }

    private func startSensor() {
        isActive = true
        history.removeAll()
        service.startGyroscope { data in
            guard let data = data else { return }
            x = data.rotationRate.x
            y = data.rotationRate.y
            z = data.rotationRate.z
            history.append((x: x, y: y, z: z))
            if history.count > 100 { history.removeFirst() }
        }
    }

    private func stopSensor() {
        service.stopGyroscope()
        isActive = false
    }
}

private struct GyroAxisRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
                .frame(width: 70, alignment: .leading)
            Spacer()
            Text("\(value, specifier: "%+.4f")")
                .font(.system(.body, design: .monospaced))
        }
    }
}
