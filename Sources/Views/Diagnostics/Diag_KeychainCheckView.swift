import SwiftUI
import Security
import LocalAuthentication

struct Diag_KeychainCheckView: View {
    @State private var keychainAccessible = false
    @State private var secureEnclaveAvailable = false
    @State private var biometricProtection = false
    @State private var testResults: [(String, Bool, String)] = []

    var body: some View {
        Form {
            Section("Keychain Status") {
                VStack(spacing: 12) {
                    Image(systemName: keychainAccessible ? "key.fill" : "key")
                        .font(.system(size: 48))
                        .foregroundStyle(keychainAccessible ? .green : .red)
                    Text(keychainAccessible ? "Keychain Accessible" : "Keychain Error")
                        .font(.headline)
                    Text("Keychain is used to securely store sensitive data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Tests") {
                ForEach(testResults, id: \.0) { result in
                    HStack {
                        Image(systemName: result.1 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.1 ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.0)
                                .font(.subheadline.weight(.medium))
                            Text(result.2)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Protection Classes") {
                Text("Protection classes are Keychain constants, not a device capability — the real check is the write/read/delete test above, plus the Secure Enclave and device-owner policy tests below it. No class is reported as 'Available' without a test.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Device-Owner Policy") {
                    Text(biometricProtection ? "Can evaluate" : "Unavailable")
                        .foregroundStyle(biometricProtection ? .green : .orange)
                }
                LabeledContent("Secure Enclave Key") {
                    Text(secureEnclaveAvailable ? "Created" : "Failed")
                        .foregroundStyle(secureEnclaveAvailable ? .green : .red)
                }
            }

            Section {
                Button("Run Tests") { runKeychainTests() }
            }
        }
        .navigationTitle("Keychain Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runKeychainTests() }
    }

    private func runKeychainTests() {
        var results: [(String, Bool, String)] = []

        let writeSuccess = testKeychainWrite()
        results.append(("Write Test", writeSuccess, writeSuccess ? "Can store data" : "Write failed"))
        keychainAccessible = writeSuccess

        let readSuccess = testKeychainRead()
        results.append(("Read Test", readSuccess, readSuccess ? "Can retrieve data" : "Read failed"))

        let deleteSuccess = testKeychainDelete()
        results.append(("Delete Test", deleteSuccess, deleteSuccess ? "Can remove data" : "Delete failed"))

        // Real tests, not hardcoded "true": Secure Enclave is probed by
        // actually creating a Secure Enclave key, and biometric protection
        // is probed via LAContext — the old version set both to true.
        let enclaveOK = testSecureEnclaveKey()
        results.append(("Secure Enclave", enclaveOK, enclaveOK ? "Secure Enclave key created" : "Secure Enclave key creation failed"))
        secureEnclaveAvailable = enclaveOK

        let biometricOK = testBiometricPolicy()
        results.append(("Biometric / Passcode Policy", biometricOK, biometricOK ? "Device-owner authentication can be evaluated" : "Device-owner authentication unavailable"))
        biometricProtection = biometricOK

        testResults = results
    }

    private func testKeychainWrite() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_key",
            kSecValueData as String: "test_value".data(using: .utf8)!
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private func testKeychainRead() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_key",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        return SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess
    }

    private func testSecureEnclaveKey() -> Bool {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ] as [String: Any]
        ]
        var error: Unmanaged<CFError>?
        return SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil
    }

    private func testBiometricPolicy() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    private func testKeychainDelete() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_key"
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
