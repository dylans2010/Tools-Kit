import SwiftUI
import CoreMotion

struct Diag_MotionSensorFusionView: View {
    @State private var attitude: (pitch: Double, roll: Double, yaw: Double) = (0, 0, 0)
    @State private var userAcceleration: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @State private var rotationRate: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @State private var magneticField: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @State private var magneticAccuracy: String = "Unknown"
    @State private var isActive = false
    private let motionManager = CMMotionManager()

    var body: some View {
        Form {
            Section("Device Attitude") {
                LabeledContent("Pitch") {
                    Text(String(format: "%.3f rad (%.1f°)", attitude.pitch, attitude.pitch * 180 / .pi))
                        .monospacedDigit()
                }
                LabeledContent("Roll") {
                    Text(String(format: "%.3f rad (%.1f°)", attitude.roll, attitude.roll * 180 / .pi))
                        .monospacedDigit()
                }
                LabeledContent("Yaw") {
                    Text(String(format: "%.3f rad (%.1f°)", attitude.yaw, attitude.yaw * 180 / .pi))
                        .monospacedDigit()
                }
            }

            Section("User Acceleration (g)") {
                LabeledContent("X") { Text(String(format: "%+.4f", userAcceleration.x)).monospacedDigit().foregroundStyle(.red) }
                LabeledContent("Y") { Text(String(format: "%+.4f", userAcceleration.y)).monospacedDigit().foregroundStyle(.green) }
                LabeledContent("Z") { Text(String(format: "%+.4f", userAcceleration.z)).monospacedDigit().foregroundStyle(.blue) }
                LabeledContent("Magnitude") {
                    let mag = sqrt(pow(userAcceleration.x, 2) + pow(userAcceleration.y, 2) + pow(userAcceleration.z, 2))
                    Text(String(format: "%.4f g", mag)).monospacedDigit()
                }
            }

            Section("Rotation Rate (rad/s)") {
                LabeledContent("X") { Text(String(format: "%+.4f", rotationRate.x)).monospacedDigit().foregroundStyle(.red) }
                LabeledContent("Y") { Text(String(format: "%+.4f", rotationRate.y)).monospacedDigit().foregroundStyle(.green) }
                LabeledContent("Z") { Text(String(format: "%+.4f", rotationRate.z)).monospacedDigit().foregroundStyle(.blue) }
            }

            Section("Calibrated Magnetic Field (μT)") {
                LabeledContent("X") { Text(String(format: "%+.2f", magneticField.x)).monospacedDigit() }
                LabeledContent("Y") { Text(String(format: "%+.2f", magneticField.y)).monospacedDigit() }
                LabeledContent("Z") { Text(String(format: "%+.2f", magneticField.z)).monospacedDigit() }
                LabeledContent("Accuracy") {
                    Text(magneticAccuracy)
                        .foregroundStyle(magneticAccuracy == "High" ? .green : .orange)
                }
            }

            Section("Sensor Availability") {
                LabeledContent("Device Motion") {
                    Text(motionManager.isDeviceMotionAvailable ? "Available" : "Not Available")
                        .foregroundStyle(motionManager.isDeviceMotionAvailable ? .green : .red)
                }
                LabeledContent("Accelerometer") {
                    Text(motionManager.isAccelerometerAvailable ? "Available" : "Not Available")
                        .foregroundStyle(motionManager.isAccelerometerAvailable ? .green : .red)
                }
                LabeledContent("Gyroscope") {
                    Text(motionManager.isGyroAvailable ? "Available" : "Not Available")
                        .foregroundStyle(motionManager.isGyroAvailable ? .green : .red)
                }
                LabeledContent("Magnetometer") {
                    Text(motionManager.isMagnetometerAvailable ? "Available" : "Not Available")
                        .foregroundStyle(motionManager.isMagnetometerAvailable ? .green : .red)
                }
            }

            Section {
                Button {
                    if isActive { stopMotion() } else { startMotion() }
                } label: {
                    HStack {
                        Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                        Text(isActive ? "Stop Sensor Fusion" : "Start Sensor Fusion")
                    }
                }
            }
        }
        .navigationTitle("Motion Sensor Fusion")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMotion() }
        .onDisappear { stopMotion() }
    }

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        isActive = true
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { motion, _ in
            guard let motion = motion else { return }
            attitude = (motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw)
            userAcceleration = (motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z)
            rotationRate = (motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z)
            magneticField = (motion.magneticField.field.x, motion.magneticField.field.y, motion.magneticField.field.z)

            switch motion.magneticField.accuracy {
            case .uncalibrated: magneticAccuracy = "Uncalibrated"
            case .low: magneticAccuracy = "Low"
            case .medium: magneticAccuracy = "Medium"
            case .high: magneticAccuracy = "High"
            @unknown default: magneticAccuracy = "Unknown"
            }
        }
    }

    private func stopMotion() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
    }
}
