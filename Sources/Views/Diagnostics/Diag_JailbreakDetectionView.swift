import SwiftUI

struct Diag_JailbreakDetectionView: View {
    @State private var checks: [(String, Bool, String)] = []
    @State private var isJailbroken = false
    @State private var hasChecked = false

    var body: some View {
        Form {
            Section("Jailbreak Status") {
                VStack(spacing: 12) {
                    Image(systemName: isJailbroken ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(isJailbroken ? .red : .green)
                    Text(isJailbroken ? "Jailbreak Detected" : "No Jailbreak Detected")
                        .font(.headline)
                    Text(isJailbroken ? "This device may be compromised" : "Device integrity appears intact")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Security Checks") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.1 ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(check.1 ? .red : .green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.2)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !hasChecked {
                Section {
                    Button {
                        runChecks()
                    } label: {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                            Text("Run Security Check")
                        }
                    }
                }
            }
        }
        .navigationTitle("Jailbreak Detection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runChecks() }
    }

    private func runChecks() {
        var results: [(String, Bool, String)] = []
        let fm = FileManager.default

        let cydiaExists = fm.fileExists(atPath: "/Applications/Cydia.app")
        results.append(("Cydia App", cydiaExists, cydiaExists ? "Cydia found on device" : "Cydia not present"))

        let aptExists = fm.fileExists(atPath: "/private/var/lib/apt/")
        results.append(("APT Directory", aptExists, aptExists ? "Package manager detected" : "No package manager"))

        let sshExists = fm.fileExists(atPath: "/usr/sbin/sshd")
        results.append(("SSH Daemon", sshExists, sshExists ? "SSH server found" : "No SSH server"))

        let substrateExists = fm.fileExists(atPath: "/Library/MobileSubstrate/")
        results.append(("MobileSubstrate", substrateExists, substrateExists ? "Substrate framework detected" : "Not present"))

        let bashExists = fm.fileExists(atPath: "/bin/bash")
        results.append(("Bash Shell", bashExists, bashExists ? "Shell accessible" : "Shell not accessible"))

        let canWrite = fm.isWritableFile(atPath: "/private/")
        results.append(("Write Access", canWrite, canWrite ? "Can write to restricted paths" : "Properly restricted"))

        let canFork = canOpenSpecialPath()
        results.append(("Fork Test", canFork, canFork ? "Process forking possible" : "Sandboxed properly"))

        checks = results
        isJailbroken = results.contains { $0.1 }
        hasChecked = true
    }

    private func canOpenSpecialPath() -> Bool {
        let paths = ["/etc/apt", "/usr/bin/ssh", "/var/mobile/Library/Caches/com.saurik.Cydia"]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}
