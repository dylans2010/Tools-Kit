import Foundation
import CryptoKit

/// Implements RFC 6238 Time-based One-Time Password (TOTP) algorithm.
public final class TOTPService {
    public static let shared = TOTPService()

    private init() {}

    /// Generates a TOTP code for a given secret.
    public func generateTOTP(secret: String, digits: Int = 6, period: TimeInterval = 30) -> String? {
        guard let secretData = base32Decode(secret) else { return nil }

        let timeStep = Int64(Date().timeIntervalSince1970 / period)
        var counter = timeStep.bigEndian
        let counterData = Data(bytes: &counter, count: MemoryLayout.size(ofValue: counter))

        let key = SymmetricKey(data: secretData)
        let hash = HMAC<SHA1>.authenticationCode(for: counterData, using: key)

        var hashData = Data(hash)
        let offset = Int(hashData.last! & 0x0f)

        let truncatedHash = hashData.withUnsafeBytes { ptr -> UInt32 in
            let bytes = ptr.baseAddress!.advanced(by: offset).assumingMemoryBound(to: UInt32.self)
            return bytes.pointee.bigEndian & 0x7fffffff
        }

        let pin = truncatedHash % UInt32(pow(10, Double(digits)))
        return String(format: "%0\(digits)d", pin)
    }

    /// Decodes a Base32 string to Data.
    private func base32Decode(_ base32: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let stripped = base32.replacingOccurrences(of: "=", with: "").uppercased().filter { alphabet.contains($0) }

        var data = Data()
        var buffer: UInt64 = 0
        var bitsLeft: Int = 0

        for char in stripped {
            guard let index = alphabet.firstIndex(of: char) else { return nil }
            let val = UInt64(alphabet.distance(from: alphabet.startIndex, to: index))
            buffer = (buffer << 5) | val
            bitsLeft += 5
            if bitsLeft >= 8 {
                data.append(UInt8((buffer >> (bitsLeft - 8)) & 0xff))
                bitsLeft -= 8
            }
        }
        return data
    }
}
