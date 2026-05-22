import SwiftUI
import Security

struct Diag_SecureEnclaveView: View {
    @State private var isAvailable = false
    @State private var hasChecked = false
    @State private var testResult: String?

    var body: some View {
        Form {
            Section("Secure Enclave") {
                VStack(spacing: 12) {
                    Image(systemName: isAvailable ? "lock.shield.fill" : "lock.shield")
                        .font(.system(size: 60))
                        .foregroundStyle(isAvailable ? .green : .secondary)

                    Text(isAvailable ? "Secure Enclave Available" : "Checking...")
                        .font(.title2.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("About") {
                Text("The Secure Enclave is a hardware-based key manager that provides an extra layer of security. It generates and stores cryptographic keys that never leave the chip.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Test Secure Enclave Key Generation") {
                    testKeyGeneration()
                }

                if let result = testResult {
                    Text(result)
                        .font(.subheadline)
                        .foregroundStyle(result.contains("Success") ? .green : .orange)
                }
            }

            Section("Capabilities") {
                LabeledContent("Hardware Key Storage") {
                    Text(isAvailable ? "Yes" : "No")
                        .foregroundStyle(isAvailable ? .green : .red)
                }
                LabeledContent("Biometric-Bound Keys") {
                    Text(isAvailable ? "Supported" : "Not Available")
                }
                LabeledContent("Key Attestation") {
                    Text(isAvailable ? "Supported" : "Not Available")
                }
            }
        }
        .navigationTitle("Secure Enclave")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkAvailability() }
    }

    private func checkAvailability() {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
        ]
        var error: Unmanaged<CFError>?
        if let _ = SecKeyCreateRandomKey(attributes as CFDictionary, &error) {
            isAvailable = true
        } else {
            isAvailable = (error == nil)
        }
        hasChecked = true
    }

    private func testKeyGeneration() {
        let tag = "com.toolskit.diagnostics.se.test".data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false,
                kSecAttrApplicationTag as String: tag
            ] as [String: Any]
        ]

        var error: Unmanaged<CFError>?
        if let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) {
            if let publicKey = SecKeyCopyPublicKey(privateKey) {
                testResult = "Success - Key pair generated in Secure Enclave"
            } else {
                testResult = "Partial - Private key created but public key extraction failed"
            }
        } else {
            testResult = "Secure Enclave key generation not available on this device"
            isAvailable = false
        }
    }
}
