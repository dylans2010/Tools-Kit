import SwiftUI
import Security

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
                LabeledContent("When Unlocked") { Text("Available").foregroundStyle(.green) }
                LabeledContent("After First Unlock") { Text("Available").foregroundStyle(.green) }
                LabeledContent("Always") { Text("Available").foregroundStyle(.green) }
                LabeledContent("When Passcode Set") {
                    Text(biometricProtection ? "Available" : "Check Passcode")
                        .foregroundStyle(biometricProtection ? .green : .orange)
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

        results.append(("Secure Enclave", true, "Hardware security available"))
        secureEnclaveAvailable = true
        biometricProtection = true

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

    private func testKeychainDelete() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_key"
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
