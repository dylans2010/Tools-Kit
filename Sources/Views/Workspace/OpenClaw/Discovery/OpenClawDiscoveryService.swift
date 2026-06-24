import Foundation

struct OpenClawDiscoveredService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let host: String
    let port: Int

    var url: URL? {
        // NetService.hostName usually ends with a dot, we need to handle that or use IP
        let cleanedHost = host.hasSuffix(".") ? String(host.dropLast()) : host
        return URL(string: "ws://\(cleanedHost):\(port)")
    }
}

final class OpenClawDiscoveryService: NSObject, ObservableObject {
    @Published var discoveredServices: [OpenClawDiscoveredService] = []

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
        DispatchQueue.main.async {
            self.discoveredServices = self.services.compactMap { service in
                guard let host = service.hostName, service.port != -1 else { return nil }
                return OpenClawDiscoveredService(
                    name: service.name,
                    host: host,
                    port: service.port
                )
            }
        }
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
        pendingResolutions.remove(sender)
        updateDiscoveredServices()
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        print("Failed to resolve service \(sender.name): \(errorDict)")
        pendingResolutions.remove(sender)
        services.remove(sender)
        updateDiscoveredServices()
    }
}
