import SwiftUI
import CoreMotion

/// Real at-rest sensor bias measurement. The previous version hardcoded
/// "Accelerometer 0.002g / Gyroscope 0.05°/s / Magnetometer 1.2µT" and had
/// a Recalibrate button that did nothing. This version samples the live
/// sensors for 3 seconds while the device is still and reports the
/// measured means: at rest, acceleration magnitude should be ~1 g and
/// rotation rate ~0 rad/s. There is no public API to recalibrate the
/// sensors, so no recalibration is claimed.
final class DiagSensorDriftMeasurer: ObservableObject {
    @Published var isMeasuring = false
    @Published var accelMean: (x: Double, y: Double, z: Double)?
    @Published var gyroMean: (x: Double, y: Double, z: Double)?
    @Published var magMean: (x: Double, y: Double, z: Double)?
    @Published var sampleCount = 0
    @Published var error: String?

    private let manager = CMMotionManager()
    private var accelSamples: [(Double, Double, Double)] = []
    private var gyroSamples: [(Double, Double, Double)] = []
    private var magSamples: [(Double, Double, Double)] = []
    private var stopWorkItem: DispatchWorkItem?

    func measure() {
        guard manager.isAccelerometerAvailable || manager.isGyroAvailable || manager.isMagnetometerAvailable else {
            error = "No motion sensors are available on this device."
            return
        }
        error = nil
        isMeasuring = true
        accelSamples = []
        gyroSamples = []
        magSamples = []
        sampleCount = 0
        accelMean = nil
        gyroMean = nil
        magMean = nil
        manager.accelerometerUpdateInterval = 1.0 / 50.0
        manager.gyroUpdateInterval = 1.0 / 50.0
        manager.magnetometerUpdateInterval = 1.0 / 50.0
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.accelSamples.append((data.acceleration.x, data.acceleration.y, data.acceleration.z))
            self.sampleCount += 1
        }
        manager.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.gyroSamples.append((data.rotationRate.x, data.rotationRate.y, data.rotationRate.z))
        }
        manager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.magSamples.append((data.magneticField.x, data.magneticField.y, data.magneticField.z))
        }
        let workItem = DispatchWorkItem { [weak self] in self?.finish() }
        stopWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func finish() {
        manager.stopAccelerometerUpdates()
        manager.stopGyroUpdates()
        manager.stopMagnetometerUpdates()
        isMeasuring = false
        accelMean = mean(accelSamples)
        gyroMean = mean(gyroSamples)
        magMean = mean(magSamples)
    }

    private func mean(_ samples: [(Double, Double, Double)]) -> (x: Double, y: Double, z: Double)? {
        guard !samples.isEmpty else { return nil }
        let n = Double(samples.count)
        return (samples.map { $0.0 }.reduce(0, +) / n, samples.map { $0.1 }.reduce(0, +) / n, samples.map { $0.2 }.reduce(0, +) / n)
    }
}

struct Diag_SensorDriftView: View {
    @StateObject private var measurer = DiagSensorDriftMeasurer()

    var body: some View {
        List {
            Section("Calibration Status") {
                if measurer.isMeasuring {
                    HStack {
                        ProgressView()
                        Text("Measuring — keep the device still on a flat surface…")
                            .font(.subheadline)
                    }
                    Text("\(measurer.sampleCount) accelerometer samples so far")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let accel = measurer.accelMean {
                    let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
                    DriftRow(sensor: "Accelerometer", drift: String(format: "mean %.3f, %.3f, %.3f g (|a| %.3f g)", accel.x, accel.y, accel.z, magnitude), status: abs(magnitude - 1.0) < 0.05 ? "At rest: OK" : "Check: |a| ≠ 1 g")
                    if let gyro = measurer.gyroMean {
                        let gmag = sqrt(gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z)
                        DriftRow(sensor: "Gyroscope", drift: String(format: "mean %.4f rad/s (|ω| %.4f)", gmag, gmag), status: gmag < 0.05 ? "At rest: OK" : "Drift detected")
                    }
                    if let mag = measurer.magMean {
                        let mmag = sqrt(mag.x * mag.x + mag.y * mag.y + mag.z * mag.z)
                        DriftRow(sensor: "Magnetometer", drift: String(format: "mean %.1f µT (|B| %.1f µT)", mmag, mmag), status: "Measured")
                    }
                } else {
                    Text("No measurement yet. Tap Measure to sample the live sensors for 3 seconds at rest.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let error = measurer.error {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }

            Section("Actions") {
                Button(measurer.isMeasuring ? "Measuring…" : "Measure at Rest (3s)") {
                    measurer.measure()
                }
                .disabled(measurer.isMeasuring)
                Text("iOS does not expose a sensor recalibration API to apps, so this tool measures bias instead of claiming to recalibrate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sensor Drift Analysis")
    }
}

struct DriftRow: View {
    let sensor: String
    let drift: String
    let status: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sensor)
                    .font(.subheadline)
                Text(drift)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(status)
                .font(.caption.bold())
                .foregroundColor(status.contains("OK") ? .green : .orange)
        }
    }
}
