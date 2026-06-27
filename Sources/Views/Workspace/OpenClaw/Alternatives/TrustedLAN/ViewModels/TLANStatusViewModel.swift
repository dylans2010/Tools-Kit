import Foundation
import Network
import Observation
import OSLog

@Observable @MainActor public final class TLANStatusViewModel {
    public var isConnected = false
    public var pairedDeviceName: String?

    public init() {
        Task {
            await checkStatus()
        }
    }

    private func checkStatus() async {
        // Real implementation would check active connection
        let devices = TLANDeviceManagerService.shared.trustedDevices
        if let first = devices.first {
            self.isConnected = true
            self.pairedDeviceName = first.name
        }
    }
}
