import Foundation
import Network
import Darwin

class LMDeviceDiscoveryService: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    @Published var discoveredDevices: [LMDevice] = []

    private var browser: NetServiceBrowser?
    private var services: [NetService] = []
    private let client = LMNetworkClient()

    func startDiscovery() {
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_http._tcp", inDomain: "local.")

        // Also trigger LAN scan
        Task {
            await scanLocalNetwork()
        }
    }

    func stopDiscovery() {
        browser?.stop()
        browser = nil
        services.removeAll()
    }

    // MARK: - NetServiceBrowserDelegate

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let index = services.firstIndex(of: service) {
            services.remove(at: index)
        }
    }

    // MARK: - NetServiceDelegate

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let hostName = sender.hostName else { return }
        let port = sender.port

        // Resolve hostName to IP
        let host = NWEndpoint.Host(hostName)
        // For simplicity in this sandbox, we'll assume we can use the hostname or resolve it
        // In a real iOS app, we might use getaddrinfo

        // We'll probe the device to see if it's LM Studio
        Task {
            await probeDevice(ip: hostName, port: port, name: sender.name)
        }
    }

    // MARK: - LAN Scanning

    private func scanLocalNetwork() async {
        guard let localIP = getLocalIPAddress() else { return }
        let components = localIP.components(separatedBy: ".")
        guard components.count == 4 else { return }
        let baseIP = components.dropLast().joined(separator: ".")

        let commonPorts = [1234, 8080, 11434]

        // Limit concurrency to avoid socket exhaustion
        let batchSize = 10
        for i in stride(from: 1, through: 254, by: batchSize) {
            await withTaskGroup(of: Void.self) { group in
                for j in i..<min(i + batchSize, 255) {
                    let ip = "\(baseIP).\(j)"
                    if ip == localIP { continue }

                    for port in commonPorts {
                        group.addTask {
                            await self.probeDevice(ip: ip, port: port, name: "Discovered Device (\(ip))")
                        }
                    }
                }
            }
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "en1" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }

    private func probeDevice(ip: String, port: Int, name: String) async {
        let url = URL(string: "http://\(ip):\(port)/v1/models")!
        do {
            // Use a short timeout for discovery
            let response: LMModelsResponse = try await client.request(url, timeout: 0.8)

            await MainActor.run {
                let device = LMDevice(
                    id: "\(ip):\(port)",
                    name: name,
                    ipAddress: ip,
                    port: port,
                    status: .online,
                    lastSeen: Date()
                )
                if !discoveredDevices.contains(where: { $0.id == device.id }) {
                    discoveredDevices.append(device)
                }
            }
        } catch {
            // Not an LM Studio device or unreachable
        }
    }
}
