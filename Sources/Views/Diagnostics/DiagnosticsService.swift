import Foundation
import UIKit
import AVFoundation
import CoreMotion
import CoreHaptics
import Network
import CoreLocation
import Darwin

final class DiagnosticsService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = DiagnosticsService()

    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private var hapticEngine: CHHapticEngine?

    @Published var lastLocation: CLLocation?
    @Published var lastHeading: CLHeading?
    @Published var locationError: Error?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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

    var kernelVersion: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return String(cString: &systemInfo.version.0)
    }

    var hostname: String {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        gethostname(&hostname, Int(NI_MAXHOST))
        return String(cString: hostname)
    }

    var isSatelliteSupported: Bool {
        let id = deviceModelIdentifier
        // iPhone 14 models: iPhone14,7, iPhone14,8, iPhone15,2, iPhone15,3
        // iPhone 15 models: iPhone15,4, iPhone15,5, iPhone16,1, iPhone16,2
        // Simplified check: iPhone14,7 or higher numerical identifiers (with some exceptions)
        // iPhone14,7 is the base iPhone 14.
        if id.hasPrefix("iPhone") {
            let versionString = id.replacingOccurrences(of: "iPhone", with: "")
            let components = versionString.split(separator: ",")
            if let major = Int(components[0]) {
                if major > 14 { return true }
                if major == 14 {
                    if let minor = components.count > 1 ? Int(components[1]) : nil {
                        return minor >= 7
                    }
                }
            }
        }
        return false
    }

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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
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

    func getDNSServers() -> [String] {
        var servers: [String] = []
        var res = __res_9_state()
        if res_9_ninit(&res) == 0 {
            let nscount = Int(res.nscount)
            for i in 0..<nscount {
                let addr = withUnsafePointer(to: res.nsaddr_list) {
                    $0.withMemoryRebound(to: sockaddr_in.self, capacity: nscount) { $0[i] }
                }
                if addr.sin_family == UInt8(AF_INET) {
                    var ip = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    var sin_addr = addr.sin_addr
                    inet_ntop(AF_INET, &sin_addr, &ip, socklen_t(INET_ADDRSTRLEN))
                    servers.append(String(cString: ip))
                }
            }
        }
        res_9_ndestroy(&res)
        return servers
    }

    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name == "pdp_ip0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
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

    func getMemoryStatistics() -> (active: UInt64, wired: UInt64, inactive: UInt64, free: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            return (
                active: UInt64(stats.active_count) * pageSize,
                wired: UInt64(stats.wire_count) * pageSize,
                inactive: UInt64(stats.inactive_count) * pageSize,
                free: UInt64(stats.free_count) * pageSize
            )
        }
        return (0, 0, 0, 0)
    }

    func getProcessorUsage() -> [Double] {
        var processorInfo: processor_info_array_t?
        var processorMsgCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &processorInfo, &processorMsgCount)

        if result == KERN_SUCCESS, let info = processorInfo {
            var usages: [Double] = []
            for i in 0..<Int(processorCount) {
                let offset = i * Int(CPU_STATE_MAX)
                let user = Double(info[offset + Int(CPU_STATE_USER)])
                let system = Double(info[offset + Int(CPU_STATE_SYSTEM)])
                let idle = Double(info[offset + Int(CPU_STATE_IDLE)])
                let nice = Double(info[offset + Int(CPU_STATE_NICE)])
                let total = user + system + idle + nice
                if total > 0 {
                    usages.append((1.0 - (idle / total)) * 100.0)
                } else {
                    usages.append(0)
                }
            }
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(processorMsgCount * natural_t(MemoryLayout<integer_t>.size)))
            return usages
        }
        return []
    }

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
