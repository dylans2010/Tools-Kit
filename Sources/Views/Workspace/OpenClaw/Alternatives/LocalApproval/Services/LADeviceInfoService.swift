import Foundation
import UIKit
import Network

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
            appInstallId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            localIP: getIPAddress() ?? "0.0.0.0"
        )
    }

    private func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    if let name = interface?.ifa_name, String(cString: name) == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        // safe: sa_len is guaranteed by the OS for AF_INET on en0
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!) // safe: sa_len is guaranteed, &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
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
