import Foundation
import UIKit
import AVFoundation
import CoreMotion
import CoreHaptics
import Network

final class DiagnosticsService: ObservableObject {
    static let shared = DiagnosticsService()

    private let motionManager = CMMotionManager()
    private var hapticEngine: CHHapticEngine?

    private init() {}

    // MARK: - Device Info

    var deviceModel: String { UIDevice.current.model }
    var deviceName: String { UIDevice.current.name }
    var systemName: String { UIDevice.current.systemName }
    var systemVersion: String { UIDevice.current.systemVersion }
    var identifierForVendor: String { UIDevice.current.identifierForVendor?.uuidString ?? "Unavailable" }

    var deviceModelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    // MARK: - Battery

    func enableBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var batteryLevel: Float { UIDevice.current.batteryLevel }

    var batteryState: String {
        switch UIDevice.current.batteryState {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Storage

    var totalDiskSpace: Int64 {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let space = attrs[.systemSize] as? Int64 else { return 0 }
        return space
    }

    var freeDiskSpace: Int64 {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let space = attrs[.systemFreeSize] as? Int64 else { return 0 }
        return space
    }

    var usedDiskSpace: Int64 { totalDiskSpace - freeDiskSpace }

    func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Motion Sensors

    func startAccelerometer(handler: @escaping (CMAccelerometerData?) -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            handler(data)
        }
    }

    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }

    func startGyroscope(handler: @escaping (CMGyroData?) -> Void) {
        guard motionManager.isGyroAvailable else { return }
        motionManager.gyroUpdateInterval = 0.05
        motionManager.startGyroUpdates(to: .main) { data, _ in
            handler(data)
        }
    }

    func stopGyroscope() {
        motionManager.stopGyroUpdates()
    }

    func startMagnetometer(handler: @escaping (CMMagnetometerData?) -> Void) {
        guard motionManager.isMagnetometerAvailable else { return }
        motionManager.magnetometerUpdateInterval = 0.05
        motionManager.startMagnetometerUpdates(to: .main) { data, _ in
            handler(data)
        }
    }

    func stopMagnetometer() {
        motionManager.stopMagnetometerUpdates()
    }

    var isAccelerometerAvailable: Bool { motionManager.isAccelerometerAvailable }
    var isGyroAvailable: Bool { motionManager.isGyroAvailable }
    var isMagnetometerAvailable: Bool { motionManager.isMagnetometerAvailable }

    // MARK: - Haptics

    var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func playHaptic(intensity: Float, sharpness: Float) {
        guard supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            // Haptic playback failed silently
        }
    }

    func playHapticPattern(events: [CHHapticEvent]) {
        guard supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            // Pattern playback failed silently
        }
    }

    // MARK: - Network

    func checkNetworkPath(completion: @escaping (NWPath) -> Void) {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                completion(path)
                monitor.cancel()
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    // MARK: - Audio

    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }

    // MARK: - System

    var uptimeSeconds: TimeInterval { ProcessInfo.processInfo.systemUptime }

    var formattedUptime: String {
        let total = Int(uptimeSeconds)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m \(seconds)s"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }

    var processorCount: Int { ProcessInfo.processInfo.processorCount }
    var activeProcessorCount: Int { ProcessInfo.processInfo.activeProcessorCount }
    var physicalMemory: UInt64 { ProcessInfo.processInfo.physicalMemory }

    var thermalState: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    // MARK: - Screen

    var screenBrightness: CGFloat { UIScreen.main.brightness }
    var screenBounds: CGRect { UIScreen.main.bounds }
    var screenScale: CGFloat { UIScreen.main.scale }
    var screenNativeBounds: CGRect { UIScreen.main.nativeBounds }
    var screenNativeScale: CGFloat { UIScreen.main.nativeScale }
}
