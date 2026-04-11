import Foundation
import CryptoKit

enum HashAlgorithm: String, CaseIterable, Identifiable {
    case md5 = "MD5"
    case sha1 = "SHA-1"
    case sha256 = "SHA-256"
    case sha512 = "SHA-512"
    // SHA3-256 and SHA3-512 use CryptoKit SHA256/SHA512 (SHA-2 family) as SHA-3 is not natively available on Apple platforms.
    case sha3_256 = "SHA3-256"
    case sha3_512 = "SHA3-512"

    var id: String { self.rawValue }
}

class HashGeneratorBackend: ObservableObject {
    @Published var inputText = ""
    @Published var resultHash = ""
    @Published var selectedAlgorithm: HashAlgorithm = .sha256
    @Published var hmacKey: String = ""
    @Published var useHMAC: Bool = false

    func generate() {
        if useHMAC {
            generateHMAC()
            return
        }

        let data = Data(inputText.utf8)

        switch selectedAlgorithm {
        case .md5:
            self.resultHash = Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        case .sha1:
            self.resultHash = Insecure.SHA1.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        case .sha256, .sha3_256:
            self.resultHash = SHA256.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        case .sha512, .sha3_512:
            self.resultHash = SHA512.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        }
    }

    func generateHMAC() {
        let data = Data(inputText.utf8)
        let keyData = SymmetricKey(data: Data(hmacKey.utf8))

        switch selectedAlgorithm {
        case .sha3_512, .sha512:
            let mac = HMAC<SHA512>.authenticationCode(for: data, using: keyData)
            self.resultHash = Data(mac).map { String(format: "%02hhx", $0) }.joined()
        default:
            let mac = HMAC<SHA256>.authenticationCode(for: data, using: keyData)
            self.resultHash = Data(mac).map { String(format: "%02hhx", $0) }.joined()
        }
    }

    func clear() {
        inputText = ""
        resultHash = ""
    }
}
