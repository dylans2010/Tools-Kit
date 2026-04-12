import Foundation
import CryptoKit

final class HMACGeneratorBackend: ObservableObject {
    @Published var hmac: String = ""

    func generate(message: String, key: String) {
        let keyData = SymmetricKey(data: key.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: message.data(using: .utf8)!, using: keyData)
        self.hmac = Data(signature).map { String(format: "%02hhx", $0) }.joined()
    }
}
