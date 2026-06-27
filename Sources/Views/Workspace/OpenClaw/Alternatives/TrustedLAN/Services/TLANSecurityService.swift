import Foundation
import CryptoKit
import Security
public actor TLANSecurityService {
    public static let shared = TLANSecurityService()
    private init() {}
    public func getAppInstallSecret() throws -> SymmetricKey {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: TLANConstants.keychainService, kSecAttrAccount as String: TLANConstants.appInstallSecretKey, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?; let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return SymmetricKey(data: data) }
        let newKey = SymmetricKey(size: .bits256); let keyData = newKey.withUnsafeBytes { Data($0) }
        let addQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: TLANConstants.keychainService, kSecAttrAccount as String: TLANConstants.appInstallSecretKey, kSecValueData as String: keyData, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]
        SecItemAdd(addQuery as CFDictionary, nil); return newKey
    }
    public func computeHMAC(for nonce: Data) throws -> Data {
        let secret = try getAppInstallSecret(); let hmac = HMAC<SHA256>.authenticationCode(for: nonce, using: secret); return Data(hmac)
    }
}
