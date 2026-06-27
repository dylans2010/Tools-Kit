import Foundation

public actor QRValidationEngine {
    public static let shared = QRValidationEngine()
    private init() {}

    public func validatePayload(_ payload: QRPayload) -> Bool {
        return payload.v == 1 && !payload.token.isEmpty
    }
}
