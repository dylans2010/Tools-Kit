import Foundation
import Observation
@Observable @MainActor public final class PCStatusViewModel {
    public var isConnected: Bool = false
    public init() {}
}
