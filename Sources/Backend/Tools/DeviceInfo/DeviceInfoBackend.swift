import Foundation
import UIKit

final class DeviceInfoBackend: ObservableObject {
    @Published var info: [InfoItem] = []

    struct InfoItem: Identifiable, Sendable {
        let id = UUID()
        let key: String
        let value: String
    }

    func refreshInfo() {
        let device = UIDevice.current
        let processInfo = ProcessInfo.processInfo

        info = [
            InfoItem(key: "Device Name", value: device.name),
            InfoItem(key: "Model", value: device.model),
            InfoItem(key: "System Name", value: device.systemName),
            InfoItem(key: "System Version", value: device.systemVersion),
            InfoItem(key: "Processor Count", value: "\(processInfo.processorCount)"),
            InfoItem(key: "Physical Memory", value: "\(processInfo.physicalMemory / 1024 / 1024 / 1024) GB"),
            InfoItem(key: "Low Power Mode", value: processInfo.isLowPowerModeEnabled ? "On" : "Off"),
            InfoItem(key: "Identifier", value: device.identifierForVendor?.uuidString ?? "Unknown")
        ]
    }
}
