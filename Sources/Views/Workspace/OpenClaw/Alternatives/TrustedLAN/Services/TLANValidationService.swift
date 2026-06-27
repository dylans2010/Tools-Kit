import Foundation
public actor TLANValidationService {
    public static let shared = TLANValidationService()
    private init() {}
    public func validateMessage(_ data: Data) throws -> TLANMessage {
        let message = try JSONDecoder().decode(TLANMessage.self, from: data)
        if message.type.isEmpty { throw TLANError.invalidMessage }
        return message
    }
}
