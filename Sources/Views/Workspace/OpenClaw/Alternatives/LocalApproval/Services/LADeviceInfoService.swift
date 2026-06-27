import Foundation
import UIKit
import Network

public actor LADeviceInfoService {
    public static let shared = LADeviceInfoService()
    private init() {}

    @MainActor
    public func getDeviceInfo() -> LADeviceInfo {
        let installId = UserDefaults.standard.string(forKey: "OpenClawAppInstallId") ?? {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "OpenClawAppInstallId")
            return newId
        }()

        return LADeviceInfo(
            deviceName: UIDevice.current.name,
            deviceModel: UIDevice.current.model,
            platform: "iOS",
            iOSVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            appInstallId: installId,
            localIP: "unavailable" // Removed hardcoded 0.0.0.0, will be determined by connection
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
