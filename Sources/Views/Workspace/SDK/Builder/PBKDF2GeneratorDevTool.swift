import SwiftUI
import CommonCrypto

struct PBKDF2GeneratorDevTool: DevTool {
    let id = "pbkdf2-generator"
    let name = "PBKDF2 Generator"
    let category: DevToolCategory = .security
    let icon = "key.fill"
    let description = "Generate key derivation using PBKDF2 with SHA256"

    func render() -> some View {
        PBKDF2GeneratorView()
    }
}

struct PBKDF2GeneratorView: View {
    @State private var password = ""
    @State private var salt = "staticsalt"
    @State private var iterations = 10000
    @State private var derivedKey = ""

    var body: some View {
        Form {
            Section("Parameters") {
                TextField("Password", text: $password)
                TextField("Salt", text: $salt)
                Stepper("Iterations: \(iterations)", value: $iterations, in: 1000...100000, step: 1000)
            }
            Button("Derive Key") {
                derive()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)

            if !derivedKey.isEmpty {
                Section("Derived Key (Hex)") {
                    Text(derivedKey)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func derive() {
        let passwordData = password.data(using: .utf8)!
        let saltData = salt.data(using: .utf8)!
        var derivedKeyData = Data(count: 32) // 256 bits
        let derivedKeyCount = derivedKeyData.count

        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                password, password.count,
                salt, salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                UInt32(iterations),
                derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                derivedKeyCount
            )
        }

        if result == kCCSuccess {
            derivedKey = derivedKeyData.map { String(format: "%02x", $0) }.joined()
        } else {
            derivedKey = "Error: \(result)"
        }
    }
}
