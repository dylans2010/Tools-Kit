import Foundation
import CryptoKit

enum HashAlgorithm: String, CaseIterable, Identifiable {
    case md5 = "MD5"
    case sha1 = "SHA-1"
    case sha256 = "SHA-256"
    case sha512 = "SHA-512"

    var id: String { self.rawValue }
}

class HashGeneratorBackend: ObservableObject {
    @Published var inputText = ""
    @Published var resultHash = ""
    @Published var selectedAlgorithm: HashAlgorithm = .sha256

    func generate() {
        let data = Data(inputText.utf8)

        switch selectedAlgorithm {
        case .md5:
            self.resultHash = Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        case .sha1:
            self.resultHash = Insecure.SHA1.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        case .sha256:
            self.resultHash = SHA256.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        case .sha512:
            self.resultHash = SHA512.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
        }
    }

    func clear() {
        inputText = ""
        resultHash = ""
    }
}
