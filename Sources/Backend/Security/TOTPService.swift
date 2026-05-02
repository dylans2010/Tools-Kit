import Foundation
import CryptoKit

class TOTPService {
    static let shared = TOTPService()

    private init() {}

    enum HashAlgorithm: String {
        case sha1, sha256, sha512
    }

    func generateTOTP(secret: String, digits: Int = 6, period: Int = 30, algorithm: HashAlgorithm = .sha1) -> String? {
        guard let secretData = decodeBase32(secret) else { return nil }

        let counter = UInt64(Date().timeIntervalSince1970) / UInt64(period)
        var counterNetworkOrder = counter.bigEndian
        let counterData = Data(bytes: &counterNetworkOrder, count: MemoryLayout.size(ofValue: counterNetworkOrder))

        let hmacData: Data
        switch algorithm {
        case .sha1:
            hmacData = Data(HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: SymmetricKey(data: secretData)))
        case .sha256:
            hmacData = Data(HMAC<SHA256>.authenticationCode(for: counterData, using: SymmetricKey(data: secretData)))
        case .sha512:
            hmacData = Data(HMAC<SHA512>.authenticationCode(for: counterData, using: SymmetricKey(data: secretData)))
        }

        let offset = Int(hmacData.last! & 0x0f)
        let truncatedHash = hmacData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> UInt32 in
            let be32 = ptr.load(fromByteOffset: offset, as: UInt32.self)
            return UInt32(bigEndian: be32)
        }

        let pin = (truncatedHash & 0x7fffffff) % UInt32(pow(10, Double(digits)))
        return String(format: "%0\(digits)d", pin)
    }

    func parseOTPAuthURL(_ urlString: String) -> TOTPData? {
        guard let url = URL(string: urlString),
              url.scheme == "otpauth",
              url.host == "totp" else { return nil }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        let issuer = queryItems?.first(where: { $0.name == "issuer" })?.value ?? "Unknown"
        let secret = queryItems?.first(where: { $0.name == "secret" })?.value ?? ""
        let digits = Int(queryItems?.first(where: { $0.name == "digits" })?.value ?? "6") ?? 6
        let period = Int(queryItems?.first(where: { $0.name == "period" })?.value ?? "30") ?? 30

        // Account name is usually in the path
        var account = url.path
        if account.hasPrefix("/") { account.removeFirst() }
        if let colonRange = account.range(of: ":") {
            account = String(account[colonRange.upperBound...])
        }

        return TOTPData(secret: secret, issuer: issuer, account: account, digits: digits, period: period)
    }

    func timeRemaining(period: Int = 30) -> Int {
        let time = Int(Date().timeIntervalSince1970)
        return period - (time % period)
    }

    // MARK: - Base32 Decoding

    private func decodeBase32(_ base32: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let base32 = base32.uppercased().replacingOccurrences(of: " ", with: "")
        var data = Data()
        var buffer: UInt32 = 0
        var bitsLeft: Int = 0

        for char in base32 {
            guard let val = alphabet.firstIndex(of: char) else { continue }
            let index = alphabet.distance(from: alphabet.startIndex, to: val)
            buffer = (buffer << 5) | UInt32(index)
            bitsLeft += 5
            if bitsLeft >= 8 {
                data.append(UInt8((buffer >> (bitsLeft - 8)) & 0xff))
                bitsLeft -= 8
            }
        }
        return data
    }
}
