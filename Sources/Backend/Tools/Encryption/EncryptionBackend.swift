import Foundation
import Combine
import CryptoKit

class EncryptionBackend: ObservableObject {
    @Published var inputText = ""
    @Published var keyText = ""
    @Published var outputText = ""
    @Published var error: String? = nil

    func encrypt() {
        error = nil
        guard let data = inputText.data(using: .utf8), !keyText.isEmpty else {
            error = "Input or Key missing"
            return
        }

        let key = SymmetricKey(data: SHA256.hash(data: keyText.data(using: .utf8)!))
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            outputText = sealedBox.combined!.base64EncodedString()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func decrypt() {
        error = nil
        guard let data = Data(base64Encoded: inputText), !keyText.isEmpty else {
            error = "Invalid base64 input or Key missing"
            return
        }

        let key = SymmetricKey(data: SHA256.hash(data: keyText.data(using: .utf8)!))
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            outputText = String(data: decryptedData, encoding: .utf8) ?? "Could not decode data"
        } catch {
            self.error = "Decryption failed: check your key"
        }
    }

    func clear() {
        inputText = ""
        keyText = ""
        outputText = ""
        error = nil
    }
}
