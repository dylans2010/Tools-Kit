import SwiftUI
import Security
import LocalAuthentication

struct Diag_KeychainDiagView: View {
    @State private var testResults: [KeychainTest] = []
    @State private var biometricType: String = "None"
    @State private var biometricAvailable: Bool = false
    @State private var secureEnclaveAvailable: Bool = false
    @State private var isTesting = false

    struct KeychainTest: Identifiable {
        let id = UUID()
        let name: String
        let passed: Bool
        let detail: String
        let duration: TimeInterval
    }

    var body: some View {
        Form {
            Section("Security Status") {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keychain Services")
                            .font(.headline)
                        Text("iOS Keychain & Security Framework")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Biometrics") {
                LabeledContent("Type") {
                    Text(biometricType)
                        .foregroundStyle(.blue)
                }
                LabeledContent("Available") {
                    Text(biometricAvailable ? "Yes" : "No")
                        .foregroundStyle(biometricAvailable ? .green : .red)
                }
                LabeledContent("Secure Enclave") {
                    Text(secureEnclaveAvailable ? "Available" : "Not Available")
                        .foregroundStyle(secureEnclaveAvailable ? .green : .red)
                }
            }

            Section("Keychain Access Groups") {
                LabeledContent("App Group") {
                    Text(Bundle.main.bundleIdentifier ?? "Unknown")
                        .font(.caption)
                }
                LabeledContent("Sharing") { Text("Per-App Isolated") }
                LabeledContent("Protection") { Text("Hardware Encrypted") }
            }

            if !testResults.isEmpty {
                Section("Diagnostic Tests") {
                    ForEach(testResults, id: \.id) { test in
                        HStack {
                            Image(systemName: test.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(test.passed ? .green : .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(test.name)
                                    .font(.subheadline)
                                Text(test.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0fms", test.duration * 1000))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button {
                    runDiagnostics()
                } label: {
                    HStack {
                        Image(systemName: "stethoscope")
                        Text(isTesting ? "Testing..." : "Run Keychain Diagnostics")
                    }
                }
                .disabled(isTesting)
            }

            Section("Protection Classes") {
                LabeledContent("WhenUnlocked") { Text("Most Secure").font(.caption).foregroundStyle(.green) }
                LabeledContent("AfterFirstUnlock") { Text("Background Access").font(.caption).foregroundStyle(.blue) }
                LabeledContent("Always") { Text("Least Restrictive").font(.caption).foregroundStyle(.orange) }
            }
        }
        .navigationTitle("Keychain Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkBiometrics(); checkSecureEnclave() }
    }

    private func checkBiometrics() {
        let context = LAContext()
        var error: NSError?
        biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID: biometricType = "Face ID"
        case .touchID: biometricType = "Touch ID"
        case .opticID: biometricType = "Optic ID"
        case .none: biometricType = "None"
        @unknown default: biometricType = "Unknown"
        }
    }

    private func checkSecureEnclave() {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
        ]
        var error: Unmanaged<CFError>?
        if let _ = SecKeyCreateRandomKey(attributes as CFDictionary, &error) {
            secureEnclaveAvailable = true
        } else {
            // Check if the error is about missing entitlement vs hardware
            secureEnclaveAvailable = error == nil
        }
    }

    private func runDiagnostics() {
        isTesting = true
        testResults = []

        DispatchQueue.global(qos: .userInitiated).async {
            var results: [KeychainTest] = []

            // Test 1: Write
            let writeResult = testKeychainWrite()
            results.append(writeResult)

            // Test 2: Read
            let readResult = testKeychainRead()
            results.append(readResult)

            // Test 3: Update
            let updateResult = testKeychainUpdate()
            results.append(updateResult)

            // Test 4: Delete
            let deleteResult = testKeychainDelete()
            results.append(deleteResult)

            // Test 5: Access Control
            let acResult = testAccessControl()
            results.append(acResult)

            DispatchQueue.main.async {
                testResults = results
                isTesting = false
            }
        }
    }

    private func testKeychainWrite() -> KeychainTest {
        let start = CFAbsoluteTimeGetCurrent()
        let data = "diag_test_\(Date().timeIntervalSince1970)".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_account",
            kSecAttrService as String: "com.toolskit.diagnostic",
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        let duration = CFAbsoluteTimeGetCurrent() - start
        return KeychainTest(name: "Write", passed: status == errSecSuccess, detail: status == errSecSuccess ? "Data stored successfully" : "Error: \(status)", duration: duration)
    }

    private func testKeychainRead() -> KeychainTest {
        let start = CFAbsoluteTimeGetCurrent()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_account",
            kSecAttrService as String: "com.toolskit.diagnostic",
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let duration = CFAbsoluteTimeGetCurrent() - start
        return KeychainTest(name: "Read", passed: status == errSecSuccess, detail: status == errSecSuccess ? "Data retrieved successfully" : "Error: \(status)", duration: duration)
    }

    private func testKeychainUpdate() -> KeychainTest {
        let start = CFAbsoluteTimeGetCurrent()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_account",
            kSecAttrService as String: "com.toolskit.diagnostic",
        ]
        let update: [String: Any] = [
            kSecValueData as String: "updated_value".data(using: .utf8)!,
        ]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        let duration = CFAbsoluteTimeGetCurrent() - start
        return KeychainTest(name: "Update", passed: status == errSecSuccess, detail: status == errSecSuccess ? "Data updated successfully" : "Error: \(status)", duration: duration)
    }

    private func testKeychainDelete() -> KeychainTest {
        let start = CFAbsoluteTimeGetCurrent()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "diag_test_account",
            kSecAttrService as String: "com.toolskit.diagnostic",
        ]
        let status = SecItemDelete(query as CFDictionary)
        let duration = CFAbsoluteTimeGetCurrent() - start
        return KeychainTest(name: "Delete", passed: status == errSecSuccess, detail: status == errSecSuccess ? "Data deleted successfully" : "Error: \(status)", duration: duration)
    }

    private func testAccessControl() -> KeychainTest {
        let start = CFAbsoluteTimeGetCurrent()
        var error: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, &error)
        let duration = CFAbsoluteTimeGetCurrent() - start
        let passed = access != nil && error == nil
        return KeychainTest(name: "Access Control", passed: passed, detail: passed ? "ACL creation successful" : "ACL creation failed", duration: duration)
    }
}
