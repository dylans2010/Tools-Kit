import Foundation
import Network
import Darwin

class LMDeviceDiscoveryService: NSObject, ObservableObject {
    static let shared = LMDeviceDiscoveryService()

    @Published var discoveredDevices: [LMDevice] = []
    @Published var isScanning = false

    private let client = LMNetworkClient()
    private var monitorTimer: Timer?
    private var lastScanTimestamp: Date?

    private let cacheKey = "com.toolskit.lmlink.cachedDevices"
    private let discoveryPort = 1234
    private let subnetScanConcurrency = 25

    override init() {
        super.init()
        loadCachedDevices()
        startPeriodicMonitoring()
    }

    func startPeriodicMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.validateCachedDevices()
            }
        }
    }

    func stopPeriodicMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func loadCachedDevices() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let devices = try? JSONDecoder().decode([LMDevice].self, from: data) {
            self.discoveredDevices = devices
        }
    }

    private func saveCachedDevices() {
        if let data = try? JSONEncoder().encode(discoveredDevices) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    func performFullScan(force: Bool = false) async {
        if !force, let last = lastScanTimestamp, Date().timeIntervalSince(last) < 15 {
            SDKLogStore.shared.log("LM Link: Skipping full scan, cache is fresh", source: "LMDeviceDiscoveryService", level: .info)
            await validateCachedDevices()
            return
        }

        await MainActor.run { isScanning = true }
        defer {
            lastScanTimestamp = Date()
            Task { await MainActor.run { isScanning = false } }
        }

        SDKLogStore.shared.log("LM Link: Starting deterministic discovery pipeline", source: "LMDeviceDiscoveryService", level: .info)

        // Stage 1: Cached IP Validation (Fast path)
        await validateCachedDevices()

        // Stage 2: Subnet Enumeration
        await scanLocalSubnet()

        saveCachedDevices()
    }

    private func validateCachedDevices() async {
        SDKLogStore.shared.log("LM Link: Stage 1 - Validating cached devices", source: "LMDeviceDiscoveryService", level: .info)
        await withTaskGroup(of: Void.self) { group in
            for device in discoveredDevices {
                group.addTask {
                    // Stage 1 uses strict 0.5s timeout for fast validation
                    await self.probeDevice(ip: device.ipAddress, port: device.port, name: device.name, timeout: 0.5)
                }
            }
        }
    }

    private func scanLocalSubnet() async {
        SDKLogStore.shared.log("LM Link: Stage 2 - Starting subnet enumeration", source: "LMDeviceDiscoveryService", level: .info)
        guard let localIP = getLocalIPAddress() else {
            SDKLogStore.shared.log("LM Link: Subnet scan aborted - local IP unknown", source: "LMDeviceDiscoveryService", level: .error)
            return
        }

        let components = localIP.components(separatedBy: ".")
        guard components.count == 4 else { return }
        let baseIP = components.dropLast().joined(separator: ".")

        // Subnet range 1-254
        let range = 1...254

        for i in stride(from: range.lowerBound, through: range.upperBound, by: subnetScanConcurrency) {
            await withTaskGroup(of: Void.self) { group in
                for j in i..<min(i + subnetScanConcurrency, range.upperBound + 1) {
                    let ip = "\(baseIP).\(j)"
                    if ip == localIP { continue }

                    group.addTask {
                        // Subnet probes use 1.0s timeout to account for initial discovery latency
                        await self.probeDevice(ip: ip, port: self.discoveryPort, name: "LM Studio (\(ip))", timeout: 1.0)
                    }
                }
            }
        }
    }

    private func probeDevice(ip: String, port: Int, name: String, timeout: TimeInterval) async {
        let url = URL(string: "http://\(ip):\(port)/v1/models")!
        let startTime = Date()

        do {
            // VALIDATION GATE (STRICT)
            // 1. HTTP status = 200
            // 2. JSON parsing succeeds
            // 3. "data" array exists
            // 4. at least one model ID exists
            // 5. response latency < threshold

            let response: LMModelsResponse = try await client.request(url, timeout: timeout)
            let latency = Date().timeIntervalSince(startTime)

            guard !response.data.isEmpty else {
                SDKLogStore.shared.log("LM Link: Node \(ip):\(port) rejected - No models loaded", source: "LMDeviceDiscoveryService", level: .debug)
                return
            }

            SDKLogStore.shared.log("LM Link: Validated node \(ip):\(port) in \(String(format: "%.3fs", latency))", source: "LMDeviceDiscoveryService", level: .info)

            await MainActor.run {
                let device = LMDevice(
                    id: "\(ip):\(port)",
                    name: name,
                    ipAddress: ip,
                    port: port,
                    status: .online,
                    lastSeen: Date(),
                    models: response.data.map { LMModel(id: $0.id) }
                )

                if let index = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                    self.discoveredDevices[index] = device
                } else {
                    self.discoveredDevices.append(device)
                }
            }
        } catch {
            // Silently discard invalid responses or timeouts for discovery cleanliness
            await MainActor.run {
                if let index = self.discoveredDevices.firstIndex(where: { $0.id == "\(ip):\(port)" }) {
                    if self.discoveredDevices[index].status == .online {
                        SDKLogStore.shared.log("LM Link: Device \(self.discoveredDevices[index].name) went offline", source: "LMDeviceDiscoveryService", level: .warning)
                    }
                    self.discoveredDevices[index].status = .offline
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
}
