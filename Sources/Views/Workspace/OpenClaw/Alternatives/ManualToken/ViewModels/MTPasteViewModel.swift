import Foundation
import Observation

@Observable @MainActor
public final class MTPasteViewModel {
    public var token: String = ""
    public var isValid: Bool {
        return token.count >= 10
    }
    public init() {}
}
