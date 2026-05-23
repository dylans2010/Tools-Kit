import Foundation
import UIKit
import AVFoundation
import CoreMotion
import CoreHaptics
import Network
import CoreLocation
import SystemConfiguration
import Darwin

final class DiagnosticsService: NSObject, ObservableObject {
    static let shared = DiagnosticsService()

    private let motionManager = CMMotionManager()
    private var hapticEngine: CHHapticEngine?
    private let locationManager = CLLocationManager()

    @Published var lastLocation: CLLocation?
    @Published var lastHeading: CLHeading?

    override private init() {
        super.init()
        locationManager.delegate = self
    }

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

    // MARK: - Advanced System Metrics

    func getSysctlValue<T>(_ name: String) -> T? {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        var value = UnsafeMutablePointer<T>.allocate(capacity: size)
        defer { value.deallocate() }
        let result = sysctlbyname(name, value, &size, nil, 0)
        guard result == 0 else { return nil }
        return value.pointee
    }

    func getSysctlStringValue(_ name: String) -> String? {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        var value = [CChar](repeating: 0, count: size)
        let result = sysctlbyname(name, &value, &size, nil, 0)
        guard result == 0 else { return nil }
        return String(cString: value)
    }

    var kernelVersion: String {
        getSysctlStringValue("kern.version") ?? "Unknown"
    }

    var cpuFrequency: Int64 {
        getSysctlValue("hw.cpufrequency") ?? 0
    }

    var ramBreakdown: (wired: UInt64, active: UInt64, inactive: UInt64, compressed: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return (0, 0, 0, 0) }

        let pageSize = UInt64(vm_kernel_page_size)
        return (
            UInt64(stats.wire_count) * pageSize,
            UInt64(stats.active_count) * pageSize,
            UInt64(stats.inactive_count) * pageSize,
            UInt64(stats.compressor_page_count) * pageSize
        )
    }

    var swapUsage: (total: UInt64, used: UInt64, free: UInt64) {
        var xsw: xsw_usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let result = sysctlbyname("vm.swapusage", &xsw, &size, nil, 0)
        guard result == 0 else { return (0, 0, 0) }
        return (UInt64(xsw.xsu_total), UInt64(xsw.xsu_used), UInt64(xsw.xsu_avail))
    }

    // MARK: - Screen

    var screenBrightness: CGFloat { UIScreen.main.brightness }
    var screenBounds: CGRect { UIScreen.main.bounds }
    var screenScale: CGFloat { UIScreen.main.scale }
    var screenNativeBounds: CGRect { UIScreen.main.nativeBounds }
    var screenNativeScale: CGFloat { UIScreen.main.nativeScale }

    // MARK: - Location

    func requestLocationPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    // MARK: - Satellite Connectivity (Simulation for iPhone 14+)

    var supportsSatelliteConnectivity: Bool {
        // iPhone 14 models and later
        let identifier = deviceModelIdentifier
        if identifier.contains("iPhone15") || identifier.contains("iPhone16") || identifier.contains("iPhone17") {
            return true
        }
        // iPhone 14 identifiers: iPhone14,7, iPhone14,8, iPhone15,2, iPhone15,3 (wait, 15,2/3 are 14 Pro)
        if identifier == "iPhone14,7" || identifier == "iPhone14,8" || identifier == "iPhone15,2" || identifier == "iPhone15,3" {
            return true
        }
        return false
    }

    var isSatelliteActive: Bool {
        // In a real scenario, this would use private or specialized APIs
        // For diagnostic purposes, we simulate based on availability and environment
        return supportsSatelliteConnectivity && !hasCellularOrWifi
    }

    private var hasCellularOrWifi: Bool {
        // Simplified check
        return false // Simulate no network to test satellite UI
    }
}

extension DiagnosticsService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
