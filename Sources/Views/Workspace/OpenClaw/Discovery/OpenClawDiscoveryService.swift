import Foundation
import Observation

struct OpenClawDiscoveredService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let host: String
    let ipAddress: String?
    let port: Int

    var url: URL? {
        // Prefer IP address if available for more reliable local connection
        if let ip = ipAddress {
            return URL(string: "ws://\(ip):\(port)")
        }
        // NetService.hostName usually ends with a dot, we need to handle that or use IP
        let cleanedHost = host.hasSuffix(".") ? String(host.dropLast()) : host
        return URL(string: "ws://\(cleanedHost):\(port)")
    }
}

@MainActor @Observable
final class OpenClawDiscoveryService: NSObject {
    static let shared = OpenClawDiscoveryService()

    var discoveredServices: [OpenClawDiscoveredService] = []

    private var browser: NetServiceBrowser?
    private var services: Set<NetService> = []
    private var pendingResolutions: Set<NetService> = []

    func startDiscovery() {
        stopDiscovery()
        discoveredServices.removeAll()
        services.removeAll()
        pendingResolutions.removeAll()

        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_openclaw-gw._tcp.", inDomain: "local.")
    }

    func stopDiscovery() {
        browser?.stop()
        browser = nil
        for service in services {
            service.stop()
        }
        services.removeAll()
        pendingResolutions.removeAll()
    }

    private func updateDiscoveredServices() {
        let allResolved = self.services.compactMap { service -> OpenClawDiscoveredService? in
            guard let host = service.hostName, service.port != -1 else { return nil }
            let ipAddress = self.extractIPAddress(from: service)
            return OpenClawDiscoveredService(
                name: service.name,
                host: host,
                ipAddress: ipAddress,
                port: service.port
            )
        }

        // Client-side host-name deduplication (Feature E.3)
        var deduped: [String: OpenClawDiscoveredService] = [:]
        for service in allResolved {
            // Deduplicate by host name to keep only one entry per machine
            let hostKey = service.host.lowercased()

            // If we already have this host, prefer the one without " (2)" style suffixes in name if possible,
            // or just take the latest one.
            if let existing = deduped[hostKey] {
                if !service.name.contains("(") && existing.name.contains("(") {
                    deduped[hostKey] = service
                }
            } else {
                deduped[hostKey] = service
            }
        }

        self.discoveredServices = Array(deduped.values)
    }

    private func extractIPAddress(from service: NetService) -> String? {
        guard let addresses = service.addresses else { return nil }

        for address in addresses {
            let data = address as Data
            guard data.count >= MemoryLayout<sockaddr_in>.size else { continue }

            let addr4 = data.withUnsafeBytes { $0.load(as: sockaddr_in.self) }

            if addr4.sin_family == sa_family_t(AF_INET) {
                var ip = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                var mutableAddr = addr4.sin_addr
                inet_ntop(AF_INET, &mutableAddr, &ip, socklen_t(INET_ADDRSTRLEN))
                return String(cString: ip)
            }
            // Optional: Handle IPv6 if needed, but for local network stability IPv4 is often preferred
        }
        return nil
    }
}

extension OpenClawDiscoveryService: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.insert(service)
        service.delegate = self
        service.resolve(withTimeout: 10.0)
        pendingResolutions.insert(service)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.remove(service)
        pendingResolutions.remove(service)
        updateDiscoveredServices()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        print("Discovery failed: \(errorDict)")
    }
}

extension OpenClawDiscoveryService: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        OpenClawDiagnosticsManager.shared.log("Bonjour resolved service: \(sender.name) at \(sender.hostName ?? "unknown host"):\(sender.port)", type: .network)
        pendingResolutions.remove(sender)
        updateDiscoveredServices()
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        OpenClawDiagnosticsManager.shared.log("Bonjour failed to resolve service \(sender.name): \(errorDict)", type: .error)
        pendingResolutions.remove(sender)
        services.remove(sender)
        updateDiscoveredServices()
    }
}
