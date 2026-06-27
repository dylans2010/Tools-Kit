import Foundation
import Observation
@Observable @MainActor public final class LADeviceListViewModel {
    public var devices: [LADevice] { LADeviceManagerService.shared.trustedDevices }
    public init() {}
}
