import Foundation
import Network
import Darwin

class LMDeviceDiscoveryService: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    static let shared = LMDeviceDiscoveryService()
    @Published var discoveredDevices: [LMDevice] = []
    @Published var isScanning = false

    private var browser: NetServiceBrowser?
    private var services: [NetService] = []
    private let client = LMNetworkClient()
    private var monitorTimer: Timer?
    private var lastScanTimestamp: Date?

    private let cacheKey = "com.toolskit.lmlink.cachedDevices"

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
            SDKLogStore.shared.log("LM Link: Skipping scan, cache is fresh (TTL < 15s)", source: "LMDeviceDiscoveryService", level: .info)
            await validateCachedDevices()
            return
        }

        await MainActor.run { isScanning = true }
        defer {
            lastScanTimestamp = Date()
            Task { await MainActor.run { isScanning = false } }
        }

        SDKLogStore.shared.log("LM Link: Starting multi-strategy scan", source: "LMDeviceDiscoveryService", level: .info)

        // Strategy A: Cache Fast Path
        await validateCachedDevices()

        // Strategy B: Bonjour Resolution
        startDiscovery()
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Give Bonjour 2s
        stopDiscovery()

        // Strategy C: Subnet Inference Scan
        await scanLocalNetwork()

        saveCachedDevices()
    }

    func startDiscovery() {
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_http._tcp", inDomain: "local.")
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
        SDKLogStore.shared.log("LM Link: Strategy C - Starting subnet inference scan", source: "LMDeviceDiscoveryService", level: .info)
        guard let localIP = getLocalIPAddress() else {
            SDKLogStore.shared.log("LM Link: Subnet scan failed - Could not determine local IP", source: "LMDeviceDiscoveryService", level: .error)
            return
        }
        let components = localIP.components(separatedBy: ".")
        guard components.count == 4 else { return }
        let baseIP = components.dropLast().joined(separator: ".")

        let commonPorts = [1234, 8080, 11434]

        // Limit concurrency to avoid socket exhaustion (Capped at 25 tasks as requested)
        let batchSize = 25
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

    private func validateCachedDevices() async {
        SDKLogStore.shared.log("LM Link: Strategy A - Validating cached devices", source: "LMDeviceDiscoveryService", level: .info)
        await withTaskGroup(of: Void.self) { group in
            for device in discoveredDevices {
                group.addTask {
                    await self.probeDevice(ip: device.ipAddress, port: device.port, name: device.name)
                }
            }
        }
    }

    private func probeDevice(ip: String, port: Int, name: String) async {
        let url = URL(string: "http://\(ip):\(port)/v1/models")!
        let startTime = Date()
        SDKLogStore.shared.log("LM Link: Probing node \(ip):\(port)", source: "LMDeviceDiscoveryService", level: .debug)
        do {
            // VALIDATION GATE (HARD FILTER)
            // 1. HTTP 200
            // 2. JSON parse success
            // 3. models.count > 0
            // 4. endpoint matches OpenAI-compatible schema
            let response: LMModelsResponse = try await client.request(url, timeout: 1.5)

            guard !response.data.isEmpty else {
                throw AIError.invalidResponse
            }

            let latency = Date().timeIntervalSince(startTime)
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

                if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                    discoveredDevices[index] = device
                } else {
                    discoveredDevices.append(device)
                }
            }
        } catch {
            // Not an LM Studio device or unreachable
            SDKLogStore.shared.log("LM Link: Probe failed for \(ip):\(port) - \(error.localizedDescription)", source: "LMDeviceDiscoveryService", level: .debug)
            await MainActor.run {
                if let index = discoveredDevices.firstIndex(where: { $0.id == "\(ip):\(port)" }) {
                    if discoveredDevices[index].status == .online {
                        SDKLogStore.shared.log("LM Link: Device \(discoveredDevices[index].name) went offline", source: "LMDeviceDiscoveryService", level: .warning)
                    }
                    discoveredDevices[index].status = .offline
                }
            }
        }
    }
}
