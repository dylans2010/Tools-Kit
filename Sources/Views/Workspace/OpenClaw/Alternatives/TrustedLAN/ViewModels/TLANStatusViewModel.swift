import Foundation
import Observation
@Observable @MainActor public final class TLANStatusViewModel {
    public var isConnected = false; public var pairedDeviceName: String?; public init() {}
}
