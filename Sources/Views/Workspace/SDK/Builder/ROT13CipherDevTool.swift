import SwiftUI

struct ROT13CipherDevTool: DevTool {
    let id = "rot13-cipher"
    let name = "ROT13 Cipher"
    let category: DevToolCategory = .encoding
    let icon = "lock.rotation"
    let description = "Encode/decode text using ROT13 substitution cipher"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter text to encode/decode") { input in
            input.unicodeScalars.map { scalar in
                let v = scalar.value
                if (65...90).contains(v) {
                    return String(UnicodeScalar((v - 65 + 13) % 26 + 65)!)
                } else if (97...122).contains(v) {
                    return String(UnicodeScalar((v - 97 + 13) % 26 + 97)!)
                }
                return String(scalar)
            }.joined()
        }
    }
}
