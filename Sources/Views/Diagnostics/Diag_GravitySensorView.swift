import SwiftUI
import CoreMotion

struct Diag_GravitySensorView: View {
    @State private var motionManager = CMMotionManager()
    @State private var isActive = false
    @State private var gravity: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @State private var tiltAngle: Double = 0
    @State private var rollAngle: Double = 0
    @State private var isFlat = false
    @State private var isFaceDown = false
    @State private var orientation: String = "Unknown"
    @State private var history: [(Date, Double, Double, Double)] = []
    @State private var calibrated = false
    @State private var calibrationOffset: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @State private var statusText = "Tap Start to begin"

    var body: some View {
        Form {
            Section("Gravity Vector") {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 2)
                            .frame(width: 150, height: 150)

                        // Cross-hair
                        Rectangle()
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(width: 1, height: 150)
                        Rectangle()
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(width: 150, height: 1)

                        // Gravity indicator
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                            .offset(x: gravity.x * 70, y: gravity.y * 70)
                            .animation(.spring(response: 0.2), value: gravity.x)
                            .animation(.spring(response: 0.2), value: gravity.y)
                    }
                    .frame(width: 150, height: 150)

                    HStack(spacing: 20) {
                        axisLabel("X", value: gravity.x, color: .red)
                        axisLabel("Y", value: gravity.y, color: .green)
                        axisLabel("Z", value: gravity.z, color: .blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Device Orientation") {
                LabeledContent("Tilt") {
                    Text(String(format: "%.1f°", tiltAngle))
                        .monospacedDigit()
                }
                LabeledContent("Roll") {
                    Text(String(format: "%.1f°", rollAngle))
                        .monospacedDigit()
                }
                LabeledContent("Position") {
                    Text(orientation)
                }
                LabeledContent("Face Down") {
                    Image(systemName: isFaceDown ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(isFaceDown ? .green : .secondary)
                }
                LabeledContent("Flat") {
                    Image(systemName: isFlat ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(isFlat ? .green : .secondary)
                }
            }

            Section("Sensor Info") {
                LabeledContent("Accelerometer") {
                    Text(motionManager.isAccelerometerAvailable ? "Available" : "N/A")
                        .foregroundStyle(motionManager.isAccelerometerAvailable ? .green : .red)
                }
                LabeledContent("Device Motion") {
                    Text(motionManager.isDeviceMotionAvailable ? "Available" : "N/A")
                        .foregroundStyle(motionManager.isDeviceMotionAvailable ? .green : .red)
                }
                LabeledContent("Calibrated") {
                    Text(calibrated ? "Yes" : "No")
                        .foregroundStyle(calibrated ? .green : .secondary)
                }
            }

            Section {
                Button {
                    if isActive { stopMotion() } else { startMotion() }
                } label: {
                    HStack {
                        Image(systemName: isActive ? "stop.circle.fill" : "move.3d")
                        Text(isActive ? "Stop" : "Start Gravity Sensor")
                    }
                }

                if isActive {
                    Button {
                        calibrate()
                    } label: {
                        HStack {
                            Image(systemName: "scope")
                            Text("Calibrate (Set Current as Level)")
                        }
                    }
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Gravity Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMotion() }
    }

    private func axisLabel(_ axis: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(axis)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(String(format: "%.3f", value))
                .font(.caption.monospacedDigit())
        }
    }

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            statusText = "Device motion not available"
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }

            let g = motion.gravity
            gravity = (
                g.x - calibrationOffset.x,
                g.y - calibrationOffset.y,
                g.z - calibrationOffset.z
            )

            // Calculate angles
            tiltAngle = atan2(gravity.y, gravity.z) * 180 / .pi
            rollAngle = atan2(gravity.x, gravity.z) * 180 / .pi

            // Determine orientation
            isFlat = abs(gravity.z) > 0.9
            isFaceDown = gravity.z > 0.9

            if abs(gravity.z) > 0.8 {
                orientation = gravity.z < 0 ? "Face Up" : "Face Down"
            } else if abs(gravity.y) > 0.8 {
                orientation = gravity.y < 0 ? "Portrait" : "Portrait (Upside Down)"
            } else if abs(gravity.x) > 0.8 {
                orientation = gravity.x < 0 ? "Landscape Left" : "Landscape Right"
            } else {
                orientation = "Tilted"
            }

            history.append((Date(), gravity.x, gravity.y, gravity.z))
            if history.count > 300 { history.removeFirst() }
        }

        isActive = true
        statusText = "Monitoring gravity vector..."
    }

    private func calibrate() {
        calibrationOffset = gravity
        calibrated = true
        statusText = "Calibrated — current position set as reference"
    }

    private func stopMotion() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
        statusText = "Stopped"
    }
}
