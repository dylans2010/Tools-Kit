import SwiftUI
import Security

struct Diag_SystemIntegrityCheckView: View {
    @State private var checks: [(String, String, IntegrityStatus)] = []
    @State private var overallStatus: IntegrityStatus = .unknown

    enum IntegrityStatus {
        case secure, compromised, unknown
        var color: Color { switch self { case .secure: return .green; case .compromised: return .red; case .unknown: return .secondary } }
        var icon: String { switch self { case .secure: return "checkmark.shield.fill"; case .compromised: return "exclamationmark.shield.fill"; case .unknown: return "questionmark.circle.fill" } }
    }

    var body: some View {
        Form {
            Section("System Integrity") {
                VStack(spacing: 12) {
                    Image(systemName: overallStatus.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(overallStatus.color)
                    Text(overallStatus == .secure ? "System Integrity Verified" : overallStatus == .compromised ? "Integrity Issues Detected" : "Checking...")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Integrity Checks") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2.icon).foregroundStyle(check.2.color).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0).font(.subheadline.weight(.medium))
                            Text(check.1).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section { Button { runChecks() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") } } }
        }
        .navigationTitle("System Integrity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runChecks() }
    }

    private func runChecks() {
        var results: [(String, String, IntegrityStatus)] = []
        let fm = FileManager.default

        let jailbreakPaths = [
            "/Applications/Cydia.app", "/Library/MobileSubstrate/", "/usr/sbin/sshd",
            "/etc/apt", "/usr/bin/ssh", "/var/cache/apt", "/var/lib/cydia",
            "/var/mobile/Library/Caches/com.saurik.Cydia/", "/bin/bash",
            "/private/var/stash", "/usr/libexec/sftp-server"
        ]
        let foundPaths = jailbreakPaths.filter { fm.fileExists(atPath: $0) }
        results.append(("Jailbreak Detection", foundPaths.isEmpty ? "No jailbreak artifacts found" : "Found: \(foundPaths.first ?? "")", foundPaths.isEmpty ? .secure : .compromised))

        let canWriteSystem = fm.isWritableFile(atPath: "/private/") || fm.isWritableFile(atPath: "/")
        results.append(("System Partition", canWriteSystem ? "System partition is writable — unusual" : "System partition is read-only (expected)", !canWriteSystem ? .secure : .compromised))

        let canOpenCydia = UIApplication.shared.canOpenURL(URL(string: "cydia://")!)
        results.append(("URL Scheme Check", canOpenCydia ? "Cydia URL scheme accessible" : "No unauthorized URL schemes detected", !canOpenCydia ? .secure : .compromised))

        let suspectLibs = ["substrate", "substitute", "frida", "cycript"]
        var foundInjection = false
        let frameworks = Bundle.allFrameworks.compactMap { bundle -> String? in
            guard let path = bundle.bundlePath.components(
                separatedBy: "/").last else { return nil }
            return path
        }
        for fw in frameworks {
            let lowered = fw.lowercased()
            if suspectLibs.contains(where: { lowered.contains($0) }) {
                foundInjection = true
                break
            }
        }
        results.append(("Code Injection", foundInjection ? "Suspicious library injection detected" : "No code injection detected", !foundInjection ? .secure : .compromised))

        #if DEBUG
        results.append(("Debug Build", "Running in DEBUG mode — expected during development", .secure))
        #else
        results.append(("Release Build", "Running in RELEASE mode", .secure))
        #endif

        let bundleReadOnly = !fm.isWritableFile(atPath: Bundle.main.bundlePath)
        results.append(("Bundle Integrity", bundleReadOnly ? "App bundle is properly signed and sealed" : "Bundle is writable — may be tampered", bundleReadOnly ? .secure : .compromised))

        let seAttrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
        ]
        var seError: Unmanaged<CFError>?
        let seKey = SecKeyCreateRandomKey(seAttrs as CFDictionary, &seError)
        results.append(("Secure Enclave", seKey != nil ? "Secure Enclave operational" : "SE test inconclusive", seKey != nil ? .secure : .unknown))

        checks = results
        let compromisedCount = results.filter { $0.2 == .compromised }.count
        overallStatus = compromisedCount > 0 ? .compromised : .secure
    }
}
