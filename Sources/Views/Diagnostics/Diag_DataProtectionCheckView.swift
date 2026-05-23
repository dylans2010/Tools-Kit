import SwiftUI
import Security

struct Diag_DataProtectionCheckView: View {
    @State private var checks: [(String, String, Bool)] = []
    @State private var hasChecked = false

    var body: some View {
        Form {
            Section("Data Protection") {
                VStack(spacing: 8) {
                    Image(systemName: "lock.rectangle.stack.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Data Protection Classes")
                        .font(.headline)
                    Text("Verify encryption levels for stored data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Protection Level Tests") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(check.2 ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0).font(.subheadline.weight(.medium))
                            Text(check.1).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Protection Classes") {
                VStack(alignment: .leading, spacing: 8) {
                    ProtectionClassRow(name: "Complete", description: "Only accessible when unlocked", level: "Highest")
                    ProtectionClassRow(name: "Until First Auth", description: "After first unlock until reboot", level: "High")
                    ProtectionClassRow(name: "Always", description: "Accessible anytime, encrypted", level: "Standard")
                    ProtectionClassRow(name: "None", description: "Not encrypted", level: "None")
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { runChecks() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Data Protection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runChecks() }
    }

    private func runChecks() {
        var results: [(String, String, Bool)] = []

        let testData = "DiagnosticTest".data(using: .utf8)!
        let protectionClasses: [(String, CFString, String)] = [
            ("Complete Protection", kSecAttrAccessibleWhenUnlocked, "Data only available when device is unlocked"),
            ("After First Unlock", kSecAttrAccessibleAfterFirstUnlock, "Available after first unlock until reboot"),
            ("Always Accessible", kSecAttrAccessibleAlways, "Available anytime (less secure)"),
            ("Passcode Set Only", kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, "Requires device passcode")
        ]

        for (name, protection, desc) in protectionClasses {
            let tag = "com.toolskit.dp.\(name.replacingOccurrences(of: " ", with: ""))".data(using: .utf8)!
            SecItemDelete([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "dptest_\(name)"
            ] as CFDictionary)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "dptest_\(name)",
                kSecValueData as String: testData,
                kSecAttrAccessible as String: protection
            ]

            let status = SecItemAdd(addQuery as CFDictionary, nil)
            let success = status == errSecSuccess
            results.append((name, success ? "\(desc) — write successful" : "\(desc) — write failed (code: \(status))", success))

            SecItemDelete([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "dptest_\(name)"
            ] as CFDictionary)
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("dp_test.txt")
        do {
            try testData.write(to: fileURL, options: .completeFileProtection)
            results.append(("File Protection", "Complete file protection write succeeded", true))
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            results.append(("File Protection", "File protection test failed: \(error.localizedDescription)", false))
        }

        checks = results
        hasChecked = true
    }
}

private struct ProtectionClassRow: View {
    let name: String
    let description: String
    let level: String

    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundStyle(level == "Highest" ? .green : level == "High" ? .blue : level == "Standard" ? .orange : .red)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.caption.weight(.medium))
                Text(description).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(level).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
