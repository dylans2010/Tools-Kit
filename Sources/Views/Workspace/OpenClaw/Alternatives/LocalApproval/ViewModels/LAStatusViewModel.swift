import Foundation
import Observation
@Observable @MainActor public final class LAStatusViewModel {
    public var isWaitingForApproval: Bool = false
    public init() {}
}
