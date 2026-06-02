import SwiftUI
import CryptoKit

struct FileHashDevTool: DevTool {
    let id = "file-hash"
    let name = "File Hash Calculator"
    let category: DevToolCategory = .utilities
    let icon = "number.square"
    let description = "Calculate real MD5 and SHA256 checksums for text input"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter text to hash") { input in
            guard let data = input.data(using: .utf8) else { return "Encoding error" }
            let sha256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
            return "Input: \(data.count) bytes\n\nSHA256:\n\(sha256)\n\nMD5:\n\(md5)"
        }
    }
}
