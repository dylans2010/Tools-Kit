import SwiftUI

struct Diag_BackupStatusView: View {
    @State private var backupInfo: [(String, String)] = []

    var body: some View {
        Form {
            Section("Backup Status") {
                VStack(spacing: 8) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Device Backup Assessment")
                        .font(.headline)
                    Text("Check iCloud and local backup indicators")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Backup Indicators") {
                ForEach(backupInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption).foregroundStyle(.secondary) }
                }
            }

            Section("How to Manage Backups") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iCloud: Settings → [Your Name] → iCloud → iCloud Backup", systemImage: "icloud.fill").font(.caption)
                    Label("iTunes/Finder: Connect to Mac/PC and select Back Up", systemImage: "desktopcomputer").font(.caption)
                    Label("Check last backup: Settings → General → iPhone Storage", systemImage: "externaldrive.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section { Button { checkBackup() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") } } }
        }
        .navigationTitle("Backup Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkBackup() }
    }

    private func checkBackup() {
        var info: [(String, String)] = []
        let fm = FileManager.default

        let backupPlistPaths = [
            "/var/mobile/Library/Preferences/com.apple.MobileBackup.plist",
            "/var/mobile/Library/Preferences/com.apple.icloud.findmydeviced.plist"
        ]
        var backupConfigFound = false
        for path in backupPlistPaths {
            if fm.fileExists(atPath: path) {
                backupConfigFound = true
                if let attrs = try? fm.attributesOfItem(atPath: path),
                   let modified = attrs[.modificationDate] as? Date {
                    info.append(("Last Config Modified", DateFormatter.localizedString(from: modified, dateStyle: .medium, timeStyle: .short)))
                }
            }
        }
        info.append(("Backup Config Files", backupConfigFound ? "Found" : "Not accessible (sandboxed)"))

        if let storeReceipt = Bundle.main.appStoreReceiptURL {
            info.append(("App Store Receipt", fm.fileExists(atPath: storeReceipt.path) ? "Present" : "Not found"))
        }

        let ubiquitousContainer = fm.url(forUbiquityContainerIdentifier: nil)
        info.append(("iCloud Container", ubiquitousContainer != nil ? "Available" : "Not configured"))

        if let attrs = try? fm.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            let used = total - free
            let formatter = ByteCountFormatter()
            info.append(("Device Used Storage", formatter.string(fromByteCount: used)))
            info.append(("Device Free Storage", formatter.string(fromByteCount: free)))
        }

        info.append(("Device Name", UIDevice.current.name))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        backupInfo = info
    }
}
