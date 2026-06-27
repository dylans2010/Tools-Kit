import Foundation
import UIKit

public actor LADeviceInfoService {
    public static let shared = LADeviceInfoService()

    @MainActor
    public func getDeviceInfo() -> LADeviceInfo {
        LADeviceInfo(
            deviceName: UIDevice.current.name,
            deviceModel: UIDevice.current.model,
            platform: "iOS",
            iOSVersion: UIDevice.current.systemVersion,
            appVersion: "1.0",
            appInstallId: "UUID-HERE",
            localIP: "192.168.1.x"
        )
    }
}

public struct LADeviceInfo: Codable {
    let deviceName: String
    let deviceModel: String
    let platform: String
    let iOSVersion: String
    let appVersion: String
    let appInstallId: String
    let localIP: String
}
