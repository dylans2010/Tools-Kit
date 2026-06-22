import SwiftUI
import Security

struct Diag_ProvisioningProfileView: View {
    @State private var profiles: [ProfileInfo] = []
    @State private var isLoading = true
    @State private var entitlements: [(String, String)] = []

    struct ProfileInfo: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let details: String
        let icon: String
        let color: Color
    }

    var body: some View {
        List {
            Section("Provisioning Profiles") {
                if isLoading {
                    ProgressView("Scanning profiles...")
                } else if profiles.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.clock")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No provisioning profiles detected")
                            .font(.subheadline)
                        Text("App Store apps do not retain embedded profiles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    ForEach(profiles) { profile in
                        HStack {
                            Image(systemName: profile.icon)
                                .foregroundStyle(profile.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.subheadline.weight(.medium))
                                Text(profile.type)
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text(profile.details)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("App Entitlements") {
                if entitlements.isEmpty {
                    Text("Checking entitlements...")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entitlements, id: \.0) { ent in
                        LabeledContent(ent.0) {
                            Text(ent.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Code Signing") {
                let bundleID = Bundle.main.bundleIdentifier ?? "Unknown"
                LabeledContent("Bundle ID") {
                    Text(bundleID)
                        .font(.caption.monospaced())
                }

                let isDebug: Bool = {
                    #if DEBUG
                    return true
                    #else
                    return false
                    #endif
                }()
                LabeledContent("Build Type") {
                    Text(isDebug ? "Debug" : "Release")
                        .foregroundStyle(isDebug ? .orange : .green)
                }

                if let appStoreReceipt = Bundle.main.appStoreReceiptURL {
                    LabeledContent("Receipt") {
                        Text(FileManager.default.fileExists(atPath: appStoreReceipt.path) ? "Present" : "Not Found")
                            .font(.caption)
                    }
                }
            }

            Section {
                Button {
                    scanProfiles()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Provisioning Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { scanProfiles() }
    }

    private func scanProfiles() {
        isLoading = true
        var found: [ProfileInfo] = []

        if let embeddedPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
            if let data = FileManager.default.contents(atPath: embeddedPath) {
                let profileStr = String(data: data, encoding: .ascii) ?? ""
                let name = extractPlistValue(from: profileStr, key: "Name") ?? "Embedded Profile"
                let teamName = extractPlistValue(from: profileStr, key: "TeamName") ?? "Unknown Team"
                let uuid = extractPlistValue(from: profileStr, key: "UUID") ?? "Unknown"

                var profileType = "Development"
                if profileStr.contains("ProvisionsAllDevices") {
                    profileType = "Enterprise"
                } else if profileStr.contains("ProvisionedDevices") {
                    profileType = "Development/Ad Hoc"
                } else {
                    profileType = "App Store"
                }

                found.append(ProfileInfo(
                    name: name,
                    type: profileType,
                    details: "Team: \(teamName) | UUID: \(String(uuid.prefix(8)))...",
                    icon: "doc.fill",
                    color: .blue
                ))
            }
        }

        let profileDirs = [
            "/var/MobileDevice/ProvisioningProfiles/",
            "/var/db/ConfigurationProfiles/Settings/"
        ]

        for dir in profileDirs {
            if let files = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                for file in files where file.hasSuffix(".mobileprovision") || file.hasSuffix(".mobileconfig") {
                    found.append(ProfileInfo(
                        name: file,
                        type: file.hasSuffix(".mobileconfig") ? "Configuration Profile" : "Provisioning Profile",
                        details: "Found in \(dir)",
                        icon: file.hasSuffix(".mobileconfig") ? "gearshape.fill" : "doc.fill",
                        color: file.hasSuffix(".mobileconfig") ? .orange : .purple
                    ))
                }
            }
        }

        profiles = found

        var ents: [(String, String)] = []
        if let entitlementsDict = Bundle.main.infoDictionary {
            if let apsEnv = entitlementsDict["aps-environment"] as? String {
                ents.append(("Push Notifications", apsEnv))
            }
        }

        let bundleID = Bundle.main.bundleIdentifier ?? "Unknown"
        ents.append(("Application ID", bundleID))

        if let groupIDs = Bundle.main.infoDictionary?["com.apple.security.application-groups"] as? [String] {
            ents.append(("App Groups", groupIDs.joined(separator: ", ")))
        }

        #if DEBUG
        ents.append(("Debugger", "Attached (Debug build)"))
        #else
        ents.append(("Debugger", "Not attached (Release build)"))
        #endif

        entitlements = ents
        isLoading = false
    }

    private func extractPlistValue(from content: String, key: String) -> String? {
        guard let keyRange = content.range(of: "<key>\(key)</key>") else { return nil }
        let afterKey = content[keyRange.upperBound...]
        guard let stringStart = afterKey.range(of: "<string>"),
              let stringEnd = afterKey.range(of: "</string>") else { return nil }
        return String(afterKey[stringStart.upperBound..<stringEnd.lowerBound])
    }
}
