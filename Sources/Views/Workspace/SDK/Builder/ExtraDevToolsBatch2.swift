import SwiftUI
import CryptoKit
import Compression

// MARK: - Encoding & Security Tools

struct Base32EncoderDevTool: DevTool {
    let id = "base32-encoder"
    let name = "Base32 Encoder"
    let category: DevToolCategory = .encoding
    let icon = "text.quote"
    let description = "Encode text to Base32 (RFC 4648)"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Text to encode") { input in
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        let data = Data(input.utf8)
        var result = ""
        var bits = 0
        var value: UInt32 = 0
        for byte in data {
            value = (value << 8) | UInt32(byte)
            bits += 8
            while bits >= 5 {
                result.append(alphabet[Int((value >> (bits - 5)) & 31)])
                bits -= 5
            }
            value &= (1 << bits) - 1 // Maintain state without overflow
        }
        if bits > 0 {
            result.append(alphabet[Int((value << (5 - bits)) & 31)])
        }
        while result.count % 8 != 0 { result.append("=") }
        return result
    }}
}

struct Base32DecoderDevTool: DevTool {
    let id = "base32-decoder"
    let name = "Base32 Decoder"
    let category: DevToolCategory = .encoding
    let icon = "text.alignleft"
    let description = "Decode Base32 (RFC 4648) formatted text"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Base32 to decode") { input in
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let clean = input.uppercased().replacingOccurrences(of: "=", with: "")
        var bits = 0
        var value: UInt32 = 0
        var data = Data()
        for char in clean {
            guard let idx = alphabet.firstIndex(of: char) else { return "Invalid Base32" }
            value = (value << 5) | UInt32(alphabet.distance(from: alphabet.startIndex, to: idx))
            bits += 5
            if bits >= 8 {
                data.append(UInt8((value >> (bits - 8)) & 255))
                bits -= 8
                value &= (1 << bits) - 1
            }
        }
        return String(data: data, encoding: .utf8) ?? "Binary Data: \(data.count) bytes"
    }}
}

struct DataURIGeneratorDevTool: DevTool {
    let id = "data-uri-generator"
    let name = "Data URI Generator"
    let category: DevToolCategory = .encoding
    let icon = "link.icloud"
    let description = "Generate Data URIs from text or small assets"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text to convert to data URI") { input in
        let base64 = Data(input.utf8).base64EncodedString()
        return "data:text/plain;base64,\(base64)"
    }}
}

struct HMACGeneratorDevTool: DevTool {
    let id = "hmac-generator"
    let name = "HMAC Generator"
    let category: DevToolCategory = .security
    let icon = "lock.doc"
    let description = "Generate Hash-based Message Authentication Codes"
    func render() -> some View { HMACGeneratorView() }
}

struct HMACGeneratorView: View {
    @State private var message = ""
    @State private var key = ""
    @State private var output = ""

    var body: some View {
        Form {
            Section("Input") {
                TextField("Message", text: $message)
                TextField("Secret Key", text: $key)
            }
            Section {
                Button("Generate SHA256 HMAC") {
                    let keyData = SymmetricKey(data: Data(key.utf8))
                    let signature = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: keyData)
                    output = Data(signature).map { String(format: "%02x", $0) }.joined()
                }
                .disabled(message.isEmpty || key.isEmpty)
            }
            if !output.isEmpty {
                Section("Output") {
                    Text(output).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
    }
}

struct AESEncryptionDevTool: DevTool {
    let id = "aes-encryption"
    let name = "AES Encryption"
    let category: DevToolCategory = .security
    let icon = "lock.shield"
    let description = "Encrypt/Decrypt text using AES-GCM"
    func render() -> some View { AESEncryptionView() }
}

struct AESEncryptionView: View {
    @State private var input = ""
    @State private var key = "12345678901234567890123456789012" // 32 chars for AES-256
    @State private var output = ""
    @State private var isEncrypting = true

    var body: some View {
        Form {
            Picker("Mode", selection: $isEncrypting) {
                Text("Encrypt").tag(true)
                Text("Decrypt").tag(false)
            }.pickerStyle(.segmented)

            Section("Data") {
                TextEditor(text: $input).frame(height: 100)
            }
            Section("Key (32 characters)") {
                TextField("Key", text: $key)
            }
            Section {
                Button(isEncrypting ? "Encrypt" : "Decrypt") {
                    guard key.count == 32 else { return }
                    let symKey = SymmetricKey(data: Data(key.utf8))
                    if isEncrypting {
                        if let sealed = try? AES.GCM.seal(Data(input.utf8), using: symKey) {
                            output = sealed.combined?.base64EncodedString() ?? "Error"
                        }
                    } else {
                        if let data = Data(base64Encoded: input),
                           let sealed = try? AES.GCM.SealedBox(combined: data),
                           let decrypted = try? AES.GCM.open(sealed, using: symKey),
                           let str = String(data: decrypted, encoding: .utf8) {
                            output = str
                        } else { output = "Decryption Failed" }
                    }
                }
            }
            if !output.isEmpty {
                Section("Result") {
                    Text(output).textSelection(.enabled)
                }
            }
        }
    }
}

struct CreditCardValidatorDevTool: DevTool {
    let id = "cc-validator"
    let name = "Credit Card Validator"
    let category: DevToolCategory = .security
    let icon = "creditcard"
    let description = "Validate credit card numbers using Luhn algorithm"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter card number") { input in
        let digits = input.compactMap { Int(String($0)) }
        guard !digits.isEmpty else { return "Invalid Input" }
        var sum = 0
        for (index, digit) in digits.reversed().enumerated() {
            if index % 2 == 1 {
                let double = digit * 2
                sum += double > 9 ? double - 9 : double
            } else {
                sum += digit
            }
        }
        let isValid = sum % 10 == 0
        return isValid ? "✅ Valid Card Number" : "❌ Invalid Card Number"
    }}
}

struct IBANValidatorDevTool: DevTool {
    let id = "iban-validator"
    let name = "IBAN Validator"
    let category: DevToolCategory = .security
    let icon = "building.columns"
    let description = "Validate International Bank Account Numbers (MOD97)"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter IBAN") { input in
        let clean = input.replacingOccurrences(of: " ", with: "").uppercased()
        guard clean.count >= 4 else { return "Too short" }
        // Rearrange: move first 4 chars to end
        let rearranged = String(clean.dropFirst(4) + clean.prefix(4))
        var numeric = ""
        for char in rearranged {
            if let d = char.wholeNumberValue { numeric += "\(d)" }
            else if let v = char.asciiValue, v >= 65 && v <= 90 { numeric += "\(v - 55)" }
        }
        // BigInt Modulo 97
        var remainder = 0
        for char in numeric {
            if let d = Int(String(char)) {
                remainder = (remainder * 10 + d) % 97
            }
        }
        return remainder == 1 ? "✅ Valid IBAN" : "❌ Invalid IBAN (Checksum mismatch)"
    }}
}

struct PasswordStrengthDevTool: DevTool {
    let id = "password-strength"
    let name = "Password Strength"
    let category: DevToolCategory = .security
    let icon = "gauge.medium"
    let description = "Analyze password security and entropy"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter password") { input in
        var score = 0
        if input.count > 8 { score += 1 }
        if input.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if input.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if input.range(of: "[!@#$%^&*]", options: .regularExpression) != nil { score += 1 }
        let ratings = ["Weak", "Fair", "Good", "Strong", "Excellent"]
        return "Strength: \(ratings[score]) (\(score)/4)\nLength: \(input.count) characters"
    }}
}

struct JWTDebuggerDevTool: DevTool {
    let id = "jwt-debugger"
    let name = "JWT Debugger"
    let category: DevToolCategory = .security
    let icon = "personalhotspot"
    let description = "Decode and inspect JSON Web Tokens"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste JWT here") { input in
        let parts = input.components(separatedBy: ".")
        guard parts.count == 3 else { return "Invalid JWT format (expected 3 parts)" }
        func decode(_ part: String) -> String {
            var base64 = part.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            while base64.count % 4 != 0 { base64.append("=") }
            guard let data = Data(base64Encoded: base64), let str = String(data: data, encoding: .utf8) else { return "Error decoding" }
            return str
        }
        return "Header:\n\(decode(parts[0]))\n\nPayload:\n\(decode(parts[1]))\n\nSignature: \(parts[2].prefix(10))..."
    }}
}

struct CertificateInfoDevTool: DevTool {
    let id = "cert-info-gen"
    let name = "Cert Info Generator"
    let category: DevToolCategory = .security
    let icon = "cert.badge.checkmark"
    let description = "Generate mock X.509 certificate metadata"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Common Name (e.g. localhost)") { cn in
        "Subject: CN=\(cn), O=ToolsKit, C=US\nIssuer: CN=ToolsKit Root CA\nValid From: \(Date().formatted())\nSerial: \(UUID().uuidString.prefix(8).uppercased())"
    }}
}
