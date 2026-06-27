import Foundation
import CryptoKit
import UIKit

class TrustedLANPairingService {
    static let shared = TrustedLANPairingService()

    /// Generates a unique trust token for a device.
    /// In production, this token is issued by the Gateway after approval.
    func issueTrustToken(for deviceID: String, gatewaySecret: String) -> String {
        let data = deviceID.data(using: .utf8)!
        let key = SymmetricKey(data: gatewaySecret.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(signature).base64EncodedString()
    }

    func saveTrustToken(_ token: String, for deviceID: String) {
        OpenClawSecureStore.shared.saveToken(token, for: deviceID)
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "Trust Token Saved",
            description: "Device: \(deviceID)"
        )
    }

    func revokeTrust(for deviceID: String) {
        OpenClawSecureStore.shared.deleteToken(for: deviceID)
        OpenClawLoggerService.shared.log(
            level: .warning,
            category: .pairing,
            title: "Trust Revoked",
            description: "Device: \(deviceID)"
        )
    }
}
