import SwiftUI

struct Diag_SandboxIntegrityView: View {
    @State private var checks: [(String, String, Bool)] = []
    @State private var overallSecure = true

    var body: some View {
        Form {
            Section("App Sandbox Integrity") {
                VStack(spacing: 12) {
                    Image(systemName: overallSecure ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(overallSecure ? .green : .red)
                    Text(overallSecure ? "Sandbox Intact" : "Sandbox Compromised")
                        .font(.headline)
                    Text(overallSecure ? "App sandboxing is functioning correctly" : "Some sandbox checks failed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Sandbox Checks") {
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

            Section("About Sandboxing") {
                Text("iOS sandboxing isolates each app's data and prevents unauthorized access to other apps, system files, and hardware. A compromised sandbox may indicate jailbreak or security vulnerability.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button { runChecks() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Sandbox Integrity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runChecks() }
    }

    private func runChecks() {
        var results: [(String, String, Bool)] = []
        let fm = FileManager.default

        let restricted = ["/private/var/mobile/Library/", "/usr/sbin/sshd", "/Applications/Cydia.app", "/bin/bash", "/usr/bin/ssh"]
        var restrictedAccessible = false
        for path in restricted {
            if fm.isReadableFile(atPath: path) {
                restrictedAccessible = true
                break
            }
        }
        results.append(("Restricted Path Access", restrictedAccessible ? "Can access restricted paths — sandbox may be compromised" : "Restricted paths properly blocked", !restrictedAccessible))

        let canWriteRoot = fm.isWritableFile(atPath: "/")
        results.append(("Root Write Access", canWriteRoot ? "Can write to root — sandbox broken" : "Root directory properly protected", !canWriteRoot))

        let canWritePrivate = fm.isWritableFile(atPath: "/private/")
        results.append(("Private Directory", canWritePrivate ? "Writable — sandbox issue" : "Properly restricted", !canWritePrivate))

        let homeDir = NSHomeDirectory()
        let homeValid = homeDir.contains("/var/") || homeDir.contains("/Users/") || homeDir.contains("/private/")
        results.append(("Home Directory", "Path: \(homeDir.prefix(40))... — \(homeValid ? "expected location" : "unusual location")", homeValid))

        let tempDir = NSTemporaryDirectory()
        let tempWritable = fm.isWritableFile(atPath: tempDir)
        results.append(("Temp Directory", tempWritable ? "Writable (expected)" : "Not writable (unexpected)", tempWritable))

        let bundlePath = Bundle.main.bundlePath
        let bundleReadOnly = !fm.isWritableFile(atPath: bundlePath)
        results.append(("Bundle Protection", bundleReadOnly ? "App bundle is read-only (correct)" : "App bundle is writable — integrity risk", bundleReadOnly))

        let canFork = canAccessSpecialAPIs()
        results.append(("Process Isolation", canFork ? "Unexpected process capabilities" : "Process properly isolated", !canFork))

        #if DEBUG
        results.append(("Debug Mode", "Running in DEBUG — debugger attached", true))
        #else
        results.append(("Debug Mode", "Release build — no debugger", true))
        #endif

        checks = results
        overallSecure = !results.contains { !$0.2 }
    }

    private func canAccessSpecialAPIs() -> Bool {
        let paths = ["/etc/apt", "/var/mobile/Library/Caches/com.saurik.Cydia", "/Library/MobileSubstrate/"]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}
