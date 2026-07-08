import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class DiagnosticsManager {
    public static let shared = DiagnosticsManager()

    private var logs: [String] = []
    private let maxLogs = 1000

    private init() {
        captureInitialLogs()
    }

    public func log(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let formattedLog = "[\(timestamp)] \(message)"
        logs.append(formattedLog)
        if logs.count > maxLogs {
            logs.removeFirst()
        }
    }

    public func captureDiagnostics() async -> DiagnosticsData {
        let device = UIDevice.current
        let processInfo = ProcessInfo.processInfo

        return DiagnosticsData(
            deviceName: device.name,
            osVersion: "\(device.systemName) \(device.systemVersion)",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage(),
            networkStatus: getNetworkStatus(),
            logs: Array(logs.suffix(100)),
            timestamp: Date()
        )
    }

    private func captureInitialLogs() {
        log("Application started")
        log("Environment: Production")
        log("User authenticated")
    }

    private func getMemoryUsage() -> String {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMB = Float(taskInfo.resident_size) / 1024.0 / 1024.0
            return String(format: "%.1f MB", usedMB)
        } else {
            return "Unknown"
        }
    }

    private func getCPUUsage() -> String {
        // Mock CPU usage for demonstration
        return "\(Int.random(in: 2...15))%"
    }

    private func getNetworkStatus() -> String {
        // Mock network status
        return "WiFi (Strong)"
    }
}
