import SwiftUI
import CoreMotion
import UIKit

struct Diag_DeviceOrientationView: View {
    @State private var deviceOrientation: String = "Unknown"
    @State private var interfaceOrientation: String = "Unknown"
    @State private var pitch: Double = 0
    @State private var roll: Double = 0
    @State private var yaw: Double = 0
    @State private var gravityX: Double = 0
    @State private var gravityY: Double = 0
    @State private var gravityZ: Double = 0
    @State private var isMonitoring = false
    @State private var orientationLocked: Bool = false
    private let motionManager = CMMotionManager()

    var body: some View {
        Form {
            Section("Current Orientation") {
                HStack {
                    Image(systemName: orientationIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        .rotationEffect(orientationAngle)
                        .animation(.spring(response: 0.3), value: orientationAngle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deviceOrientation)
                            .font(.headline)
                        Text(interfaceOrientation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Device Attitude (Euler)") {
                LabeledContent("Pitch") {
                    Text(String(format: "%.2f°", pitch * 180 / .pi))
                        .monospacedDigit()
                }
                LabeledContent("Roll") {
                    Text(String(format: "%.2f°", roll * 180 / .pi))
                        .monospacedDigit()
                }
                LabeledContent("Yaw") {
                    Text(String(format: "%.2f°", yaw * 180 / .pi))
                        .monospacedDigit()
                }
            }

            Section("Gravity Vector") {
                LabeledContent("X") {
                    Text(String(format: "%.4f g", gravityX))
                        .monospacedDigit()
                        .foregroundStyle(.red)
                }
                LabeledContent("Y") {
                    Text(String(format: "%.4f g", gravityY))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
                LabeledContent("Z") {
                    Text(String(format: "%.4f g", gravityZ))
                        .monospacedDigit()
                        .foregroundStyle(.blue)
                }
            }

            Section("Device Status") {
                LabeledContent("Orientation Lock") {
                    Text(orientationLocked ? "Locked" : "Unlocked")
                        .foregroundStyle(orientationLocked ? .orange : .green)
                }
                LabeledContent("Face Up/Down") {
                    Text(facePosition)
                }
                LabeledContent("Device Motion") {
                    Text(motionManager.isDeviceMotionAvailable ? "Available" : "Not Available")
                        .foregroundStyle(motionManager.isDeviceMotionAvailable ? .green : .red)
                }
                LabeledContent("Proximity") {
                    Text(UIDevice.current.isProximityMonitoringEnabled ? "Monitoring" : "Inactive")
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Device Orientation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            updateOrientation()
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
        }
    }

    private var orientationIcon: String {
        switch UIDevice.current.orientation {
        case .portrait: return "iphone"
        case .portraitUpsideDown: return "iphone"
        case .landscapeLeft, .landscapeRight: return "iphone.landscape"
        case .faceUp: return "iphone.gen3"
        case .faceDown: return "iphone.gen3"
        default: return "iphone"
        }
    }

    private var orientationAngle: Angle {
        switch UIDevice.current.orientation {
        case .portraitUpsideDown: return .degrees(180)
        case .landscapeLeft: return .degrees(-90)
        case .landscapeRight: return .degrees(90)
        default: return .zero
        }
    }

    private var facePosition: String {
        if gravityZ > 0.9 { return "Face Down" }
        if gravityZ < -0.9 { return "Face Up" }
        return "Upright"
    }

    private func updateOrientation() {
        switch UIDevice.current.orientation {
        case .portrait: deviceOrientation = "Portrait"
        case .portraitUpsideDown: deviceOrientation = "Portrait Upside Down"
        case .landscapeLeft: deviceOrientation = "Landscape Left"
        case .landscapeRight: deviceOrientation = "Landscape Right"
        case .faceUp: deviceOrientation = "Face Up"
        case .faceDown: deviceOrientation = "Face Down"
        default: deviceOrientation = "Unknown"
        }

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch scene.interfaceOrientation {
            case .portrait: interfaceOrientation = "Interface: Portrait"
            case .portraitUpsideDown: interfaceOrientation = "Interface: Portrait Upside Down"
            case .landscapeLeft: interfaceOrientation = "Interface: Landscape Left"
            case .landscapeRight: interfaceOrientation = "Interface: Landscape Right"
            default: interfaceOrientation = "Interface: Unknown"
            }
        }
    }

    private func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        isMonitoring = true
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion = motion else { return }
            pitch = motion.attitude.pitch
            roll = motion.attitude.roll
            yaw = motion.attitude.yaw
            gravityX = motion.gravity.x
            gravityY = motion.gravity.y
            gravityZ = motion.gravity.z
        }
    }

    private func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        isMonitoring = false
    }
}
