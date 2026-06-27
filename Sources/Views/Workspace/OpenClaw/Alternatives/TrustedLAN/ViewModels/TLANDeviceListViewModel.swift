import Foundation
import Observation
@Observable @MainActor public final class TLANDeviceListViewModel {
    public var devices: [TLANDevice] { TLANDeviceManagerService.shared.trustedDevices }; public init() {}
    public func removeDevice(id: String) { TLANDeviceManagerService.shared.removeDevice(id: id) }
}
