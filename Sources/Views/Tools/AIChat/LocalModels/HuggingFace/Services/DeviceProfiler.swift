import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct DeviceProfile: Codable {
    let ramGB: Double
    let storageFreeGB: Double
    let deviceModel: String
    let cpuClass: String
    let osVersion: String

    static func current() -> DeviceProfile {
        let processInfo = ProcessInfo.processInfo
        let ram = Double(processInfo.physicalMemory) / (1024 * 1024 * 1024)

        let fileManager = FileManager.default
        let path = NSHomeDirectory()
        let attributes = try? fileManager.attributesOfFileSystem(forPath: path)
        let freeSize = attributes?[.systemFreeSize] as? Int64 ?? 0
        let storageFree = Double(freeSize) / (1024 * 1024 * 1024)

        return DeviceProfile(
            ramGB: ram,
            storageFreeGB: storageFree,
            deviceModel: UIDevice.current.model,
            cpuClass: "Apple Silicon", // Simplified for iOS
            osVersion: UIDevice.current.systemVersion
        )
    }

    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
