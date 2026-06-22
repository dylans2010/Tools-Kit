import SwiftUI
import CoreMotion

struct Diag_AccelerometerView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var x: Double = 0
    @State private var y: Double = 0
    @State private var z: Double = 0
    @State private var isActive = false
    @State private var history: [(x: Double, y: Double, z: Double)] = []

    var body: some View {
        Form {
            accelerometerDataSection
            liveGraphSection
            sensorStatusSection
            actionsSection
        }
        .navigationTitle("Accelerometer")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopSensor() }
    }

    private var accelerometerDataSection: some View {
        Section("Accelerometer Data") {
            VStack(spacing: 12) {
                AxisRow(label: "X", value: x, color: .red)
                AxisRow(label: "Y", value: y, color: .green)
                AxisRow(label: "Z", value: z, color: .blue)
            }
            .padding(.vertical, 4)
        }
    }

    private var liveGraphSection: some View {
        Section("Live Graph") {
            Canvas { context, size in
                drawGraph(context: context, size: size)
            }
            .frame(height: 150)
        }
    }

    private var sensorStatusSection: some View {
        Section("Sensor Status") {
            LabeledContent("Available") {
                Text(service.isAccelerometerAvailable ? "Yes" : "No")
                    .foregroundStyle(service.isAccelerometerAvailable ? .green : .red)
            }
            LabeledContent("G-Force") {
                Text("\(sqrt(x*x + y*y + z*z), specifier: "%.2f") G")
                    .monospacedDigit()
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                if isActive { stopSensor() } else { startSensor() }
            } label: {
                HStack {
                    Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                    Text(isActive ? "Stop" : "Start Accelerometer")
                }
            }
        }
    }

    private func startSensor() {
        isActive = true
        history.removeAll()
        service.startAccelerometer { data in
            guard let data = data else { return }
            x = data.acceleration.x
            y = data.acceleration.y
            z = data.acceleration.z
            history.append((x: x, y: y, z: z))
            if history.count > 100 { history.removeFirst() }
        }
    }

    private func stopSensor() {
        service.stopAccelerometer()
        isActive = false
    }

    private func drawGraph(context: GraphicsContext, size: CGSize) {
        guard history.count > 1 else { return }
        let axes: [(KeyPath<(x: Double, y: Double, z: Double), Double>, Color)] = [
            (\.x, .red), (\.y, .green), (\.z, .blue)
        ]
        for (keyPath, color) in axes {
            var path = Path()
            for (i, point) in history.enumerated() {
                let xPos = CGFloat(i) / CGFloat(history.count - 1) * size.width
                let value = point[keyPath: keyPath]
                let yPos = size.height / 2 - CGFloat(value) * (size.height / 4)
                if i == 0 { path.move(to: CGPoint(x: xPos, y: yPos)) }
                else { path.addLine(to: CGPoint(x: xPos, y: yPos)) }
            }
            context.stroke(path, with: .color(color), lineWidth: 1.5)
        }
    }
}

private struct AxisRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 24)
            ProgressView(value: abs(value), total: 2.0)
                .tint(color)
            Text("\(value, specifier: "%+.3f")")
                .font(.system(.body, design: .monospaced))
                .frame(width: 80, alignment: .trailing)
        }
    }
}
