import Foundation
import Network

@MainActor
@Observable
final class OpenClawDiscoveryService: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private let browser = NetServiceBrowser()
    private var discoveredServices: [NetService] = []

    var discoveredDevices: [OpenClawDevice] = []
    var isScanning = false

    override init() {
        super.init()
        browser.delegate = self
    }

    func startScanning() {
        discoveredServices.removeAll()
        discoveredDevices.removeAll()
        browser.searchForServices(ofType: "_openclaw-gw._tcp", inDomain: "local.")
        isScanning = true
    }

    func stopScanning() {
        browser.stop()
        isScanning = false
    }

    // MARK: - NetServiceBrowserDelegate

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        discoveredServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        discoveredServices.removeAll { $0 == service }
        updateDevices()
    }

    // MARK: - NetServiceDelegate

    func netServiceDidResolveAddress(_ sender: NetService) {
        updateDevices()
    }

    private func updateDevices() {
        discoveredDevices = discoveredServices.compactMap { service in
            guard let hostName = service.hostName else { return nil }
            let port = service.port
            return OpenClawDevice(
                id: service.name,
                name: service.name,
                host: hostName.trimmingCharacters(in: CharacterSet(charactersIn: ".")),
                port: port
            )
        }
    }
}
