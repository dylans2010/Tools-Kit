import Foundation

public actor QRCredentialExchange {
    public static let shared = QRCredentialExchange()
    private init() {}

    public func finalizePairing(token: QRTrustToken) async throws {
        // Finalize
    }
}
