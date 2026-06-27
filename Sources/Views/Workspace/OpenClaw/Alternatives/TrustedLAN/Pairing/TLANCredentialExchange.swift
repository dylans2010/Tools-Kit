import Foundation
public actor TLANCredentialExchange {
    public static let shared = TLANCredentialExchange(); private init() {}
    public func exchangeToken(_ token: TLANTrustToken) async throws {}
}
