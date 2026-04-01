import Foundation
import CryptoKit
class HashGeneratorBackend: ObservableObject {
    @Published var input = ""
    @Published var hash = ""
    func generate() { let d = Data(input.utf8); self.hash = SHA256.hash(data: d).map { String(format: "%02hhx", $0) }.joined() }
}
