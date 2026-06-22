import Foundation
import Network
import Darwin

enum ConnectionType: String, Codable, CaseIterable {
    case lan
    case wifi
    case local
    case manualIP
}

struct LMStudioModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
}

struct LocalDevice: Identifiable, Codable, Hashable {
    var id: String { "\(ip):\(port)" }
    let ip: String
    let port: Int
    let connectionType: ConnectionType
    var isReachable: Bool
    var latency: TimeInterval?
    var models: [LMStudioModel]
    var serverInfo: String?

    var baseURL: String {
        return "http://\(ip):\(port)"
    }
}

@MainActor
class LMLocalDevicesService: ObservableObject {
    static let shared = LMLocalDevicesService()

    @Published var discoveredDevices: [LocalDevice] = []
    @Published var isScanning = false

    private let client = LMNetworkClient()
    private let subnetScanConcurrency = 30
    private let defaultPorts = [1234, 11434, 8080]

    private init() {
        loadCachedDevices()
    }

    private let cacheKey = "com.toolskit.localmodels.devices"

    private func loadCachedDevices() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let devices = try? JSONDecoder().decode([LocalDevice].self, from: data) {
            self.discoveredDevices = devices
        }
    }

    private func saveCachedDevices() {
        if let data = try? JSONEncoder().encode(discoveredDevices) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    func performFullScan() async {
        guard !isScanning else { return }
        isScanning = true
        SDKLogStore.shared.log("LMLocalDevicesService: Starting full discovery scan", source: "LMLocalDevicesService", level: .info)

        defer {
            isScanning = false
            saveCachedDevices()
        }

        await withTaskGroup(of: Void.self) { group in
            // 1. Localhost
            group.addTask { await self.probeLocalhost() }

            // 2. Subnet
            group.addTask { await self.scanLocalSubnet() }
        }

        SDKLogStore.shared.log("LMLocalDevicesService: Discovery scan complete. Found \(discoveredDevices.count) devices.", source: "LMLocalDevicesService", level: .info)
    }

    func addManualIP(_ ip: String, port: Int) async {
        SDKLogStore.shared.log("LMLocalDevicesService: Probing manual IP \(ip):\(port)", source: "LMLocalDevicesService", level: .info)
        await probeDevice(ip: ip, port: port, type: .manualIP)
        saveCachedDevices()
    }

    private func probeLocalhost() async {
        for port in defaultPorts {
            await probeDevice(ip: "127.0.0.1", port: port, type: .local)
        }
    }

    private func scanLocalSubnet() async {
        guard let localIP = getLocalIPAddress() else {
            SDKLogStore.shared.log("LMLocalDevicesService: Could not determine local IP for subnet scan", source: "LMLocalDevicesService", level: .error)
            return
        }

        let components = localIP.components(separatedBy: ".")
        guard components.count == 4 else { return }
        let baseIP = components.dropLast().joined(separator: ".")

        for port in [1234, 11434] { // Prioritize common AI ports for subnet scan
            for i in stride(from: 1, through: 254, by: subnetScanConcurrency) {
                await withTaskGroup(of: Void.self) { group in
                    for j in i..<min(i + subnetScanConcurrency, 255) {
                        let ip = "\(baseIP).\(j)"
                        if ip == localIP { continue }
                        group.addTask {
                            await self.probeDevice(ip: ip, port: port, type: .lan, timeout: 0.8)
                        }
                    }
                }
            }
        }
    }

    private func probeDevice(ip: String, port: Int, type: ConnectionType, timeout: TimeInterval = 2.0) async {
        guard let url = URL(string: "http://\(ip):\(port)/v1/models") else { return }
        let startTime = Date()

        do {
            let response: LMModelsResponse = try await client.request(url, timeout: timeout)
            let latency = Date().timeIntervalSince(startTime)

            let studioModels = response.data.map { LMStudioModel(id: $0.id, name: $0.id) }

            let device = LocalDevice(
                ip: ip,
                port: port,
                connectionType: type,
                isReachable: true,
                latency: latency,
                models: studioModels,
                serverInfo: "LM Studio / OpenAI Compatible"
            )

            await MainActor.run {
                updateDevice(device)
            }
        } catch {
            await MainActor.run {
                markDeviceOffline(ip: ip, port: port, type: type)
            }
        }
    }

    private func updateDevice(_ device: LocalDevice) {
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
    }

    private func markDeviceOffline(ip: String, port: Int, type: ConnectionType) {
        if let index = discoveredDevices.firstIndex(where: { $0.id == "\(ip):\(port)" }) {
            discoveredDevices[index].isReachable = false
            discoveredDevices[index].latency = nil
        } else if type == .manualIP || type == .local {
            // Keep track of manual/local even if offline
            let device = LocalDevice(ip: ip, port: port, connectionType: type, isReachable: false, latency: nil, models: [], serverInfo: nil)
            discoveredDevices.append(device)
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
}
