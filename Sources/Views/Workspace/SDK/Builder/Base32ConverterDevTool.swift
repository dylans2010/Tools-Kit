import SwiftUI

struct Base32ConverterDevTool: DevTool {
    let id = "base32-converter"
    let name = "Base32 Converter"
    let category: DevToolCategory = .encoding
    let icon = "32.square"
    let description = "Convert text to Base32 representation (RFC 4648)"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter text") { input in
            base32Encode(Array(input.utf8))
        }
    }

    private func base32Encode(_ data: [UInt8]) -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var result = ""
        var buffer: UInt32 = 0
        var bitsLeft = 0

        for byte in data {
            buffer = (buffer << 8) | UInt32(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                let index = Int((buffer >> (bitsLeft - 5)) & 0x1F)
                result.append(alphabet[index])
                bitsLeft -= 5
            }
        }

        if bitsLeft > 0 {
            let index = Int((buffer << (5 - bitsLeft)) & 0x1F)
            result.append(alphabet[index])
        }

        while result.count % 8 != 0 {
            result.append("=")
        }

        return result
    }
}
