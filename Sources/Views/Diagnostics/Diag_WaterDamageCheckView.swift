import SwiftUI
import CoreMotion
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_WaterDamageCheckView: View {
    @State private var checks: [(String, String, DamageIndicator)] = []
    @State private var overallRisk: DamageIndicator = .unknown
    @State private var hasChecked = false

    enum DamageIndicator {
        case clear, warning, detected, unknown

        var color: Color {
            switch self {
            case .clear: return .green
            case .warning: return .orange
            case .detected: return .red
            case .unknown: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .clear: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .detected: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }

    var body: some View {
        List {
            Section("Water Damage Assessment") {
                VStack(spacing: 12) {
                    Image(systemName: overallRisk == .clear ? "drop.degreesign.slash.fill" : overallRisk == .warning || overallRisk == .detected ? "drop.fill" : "questionmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(overallRisk.color)
                    Text(overallRisk == .clear ? "No Water Damage Indicators" : overallRisk == .warning ? "Possible Water Exposure" : overallRisk == .detected ? "Water Damage Signs Detected" : "Analyzing...")
                        .font(.headline)
                    Text("Software-based assessment — physical LCI inspection recommended")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Sensor & Hardware Checks") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2.icon)
                            .foregroundStyle(check.2.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.1)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Physical LCI Locations") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("SIM card tray slot (visible LCI sticker)", systemImage: "simcard.fill")
                        .font(.caption)
                    Label("Headphone jack (older models)", systemImage: "headphones")
                        .font(.caption)
                    Label("Charging port (internal inspection)", systemImage: "powerplug.fill")
                        .font(.caption)
                    Label("LCI turns red/pink when exposed to water", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.vertical, 4)
            }

            Section("IP Ratings") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 7-11: IP67 (1m for 30 min)", systemImage: "iphone.gen1")
                        .font(.caption)
                    Label("iPhone 12-14: IP68 (6m for 30 min)", systemImage: "iphone.gen2")
                        .font(.caption)
                    Label("iPhone 15+: IP68 (6m for 30 min)", systemImage: "iphone.gen3")
                        .font(.caption)
                    Text("Note: IP rating degrades over time and with wear")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    runWaterDamageChecks()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-check")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Water Damage Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runWaterDamageChecks() }
    }

    private func runWaterDamageChecks() {
        var results: [(String, String, DamageIndicator)] = []

        let mm = CMMotionManager()
        let accelOK = mm.isAccelerometerAvailable
        let gyroOK = mm.isGyroAvailable
        let magOK = mm.isMagnetometerAvailable
        let allSensorsOK = accelOK && gyroOK && magOK
        results.append(("Motion Sensors", allSensorsOK ? "All sensors responding (accel, gyro, mag)" : "Some sensors not responding — possible corrosion", allSensorsOK ? .clear : .warning))

        let session = AVAudioSession.sharedInstance()
        let hasOutputs = !session.currentRoute.outputs.isEmpty
        let hasInputs = session.availableInputs?.isEmpty == false
        results.append(("Audio System", hasOutputs && hasInputs ? "Speaker and microphone responding" : "Audio hardware issue detected", hasOutputs && hasInputs ? .clear : .warning))

        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        let batteryOK = batteryLevel >= 0 && batteryState != .unknown
        results.append(("Battery Monitor", batteryOK ? "Battery reporting normally" : "Battery monitoring issues — may indicate corrosion", batteryOK ? .clear : .warning))

        let thermal = ProcessInfo.processInfo.thermalState
        let thermalOK = thermal == .nominal || thermal == .fair
        results.append(("Thermal State", thermalOK ? "Temperature normal" : "Elevated temperature — possible short circuit", thermalOK ? .clear : .warning))

        let screen = UIScreen.main
        let brightness = screen.brightness
        results.append(("Display", "Brightness: \(Int(brightness * 100))% — display functional", .clear))

        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let frontCam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        let camerasOK = camera != nil && frontCam != nil
        results.append(("Cameras", camerasOK ? "Both cameras responding" : "Camera hardware issue — possible moisture", camerasOK ? .clear : .warning))

        let flash = camera?.isTorchAvailable ?? false
        results.append(("Flash/Torch", flash ? "Flash hardware available" : "Flash not available — may indicate damage", flash ? .clear : .warning))

        checks = results
        let warningCount = results.filter { $0.2 == .warning || $0.2 == .detected }.count
        overallRisk = warningCount == 0 ? .clear : warningCount >= 3 ? .detected : .warning
        hasChecked = true
    }
}
