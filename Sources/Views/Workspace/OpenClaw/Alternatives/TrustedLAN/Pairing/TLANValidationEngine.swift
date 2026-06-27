import Foundation
public actor TLANValidationEngine {
    public static let shared = TLANValidationEngine(); private init() {}
    public func validateResponse(_ m: TLANMessage) throws -> Bool { return m.type != "ERROR" }
}
