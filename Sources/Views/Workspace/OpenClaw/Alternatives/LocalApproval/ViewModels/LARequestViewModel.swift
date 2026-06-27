import Foundation
import Network
import Observation
import OSLog

@Observable @MainActor
public final class LARequestViewModel {
    public var state: LARequestState = .idle
    public init() {}
}

public enum LARequestState {
    case idle, waiting, approved, denied
}
