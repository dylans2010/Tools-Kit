import Foundation
import Observation

@Observable
public final class PCSecurityService {
    public static let shared = PCSecurityService()
    public private(set) var lockoutEnd: Date?
    private init() {}
    public func setLockout(duration: TimeInterval) { lockoutEnd = Date().addingTimeInterval(duration) }
    public var isLocked: Bool {
        guard let end = lockoutEnd else { return false }
        return end > Date()
    }
}
