import Foundation
import Network
import Observation
import OSLog

@Observable @MainActor public final class TLANDeviceListViewModel {
    public var devices: [TLANDevice] { TLANDeviceManagerService.shared.trustedDevices }

    public init() {}

    public func removeDevice(id: String) {
        TLANDeviceManagerService.shared.removeDevice(id: id)
    }

    public func forgetAllDevices() {
        for device in devices {
            TLANDeviceManagerService.shared.removeDevice(id: device.id)
        }
    }
}
