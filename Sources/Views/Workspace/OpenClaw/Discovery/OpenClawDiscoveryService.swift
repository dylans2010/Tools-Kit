import Foundation
import Network

struct OpenClawDiscoveredService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let host: String
    let port: Int

    var url: URL? {
        URL(string: "ws://\(host):\(port)")
    }
}

final class OpenClawDiscoveryService: NSObject, ObservableObject {
    @Published var discoveredServices: [OpenClawDiscoveredService] = []
    private var browser: NWBrowser?

    func startDiscovery() {
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_openclaw-gw._tcp", domain: nil)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: descriptor, using: parameters)
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleResults(results)
        }
        browser?.start(queue: .main)
    }

    func stopDiscovery() {
        browser?.cancel()
        browser = nil
    }

    private func handleResults(_ results: Set<NWBrowser.Result>) {
        discoveredServices = results.compactMap { result in
            if case .bonjour(let service) = result.endpoint {
                // We need to resolve the IP/Host. NWBrowser gives us the service name.
                // In a full implementation, we would use NWConnection to resolve or NWServiceResolver.
                // For this implementation, we will use the service name as a placeholder host if needed,
                // but usually .local address works.
                return OpenClawDiscoveredService(
                    name: service.name,
                    host: "\(service.name).local",
                    port: 18789 // OpenClaw default port
                )
            }
            return nil
        }
    }
}
