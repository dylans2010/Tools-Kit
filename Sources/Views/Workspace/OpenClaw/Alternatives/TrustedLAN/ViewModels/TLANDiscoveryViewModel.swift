import Foundation
import Observation
import Network

@Observable @MainActor public final class TLANDiscoveryViewModel {
    public var results: [NWBrowser.Result] = []; public var isScanning = false
    public init() {}
    public func startDiscovery() async {
        isScanning = true; let stream = await TLANBonjourBrowser.shared.startBrowsing()
        for await newResults in stream { self.results = newResults }
    }
    public func stopDiscovery() async { await TLANBonjourBrowser.shared.stopBrowsing(); isScanning = false }
}
