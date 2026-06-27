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

    nonisolated private func getIPAddress() -> String? {
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
                        guard let addr = interface?.ifa_addr else {
                            continue
                        }
                        let length: socklen_t
                        #if os(iOS)
                        if addr.pointee.sa_family == UInt8(AF_INET) {
                            length = socklen_t(MemoryLayout<sockaddr_in>.size)
                        } else {
                            length = socklen_t(MemoryLayout<sockaddr>.size)
                        }
                        #else
                        length = socklen_t(addr.pointee.sa_len)
                        #endif
                        getnameinfo(addr,
                                    length,
                                    &hostname,
                                    socklen_t(hostname.count),
                                    nil,
                                    0,
                                    NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
