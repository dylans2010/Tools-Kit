import SwiftUI
import Security

struct Diag_ConfigProfileAuditView: View {
    @State private var profiles: [ConfigProfile] = []
    @State private var isLoading = true
    @State private var summary: [(String, String)] = []

    struct ConfigProfile: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let path: String
        let icon: String
        let color: Color
    }

    var body: some View {
        List {
            Section("Configuration Profile Audit") {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Installed Profiles")
                        .font(.headline)
                    Text("Scan for MDM, VPN, certificate, and restriction profiles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Summary") {
                if isLoading {
                    ProgressView("Scanning...")
                } else {
                    ForEach(summary, id: \.0) { item in
                        LabeledContent(item.0) {
                            Text(item.1).font(.caption)
                        }
                    }
                }
            }

            if !profiles.isEmpty {
                Section("Detected Profiles (\(profiles.count))") {
                    ForEach(profiles, id: \.id) { profile in
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
                                Text(profile.path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            Section("Profile Types") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("MDM Enrollment: Remote device management", systemImage: "building.2.fill")
                        .font(.caption)
                    Label("VPN Configuration: Network tunnel setup", systemImage: "lock.shield.fill")
                        .font(.caption)
                    Label("WiFi Profile: Pre-configured network access", systemImage: "wifi")
                        .font(.caption)
                    Label("Email/Exchange: Mail account configuration", systemImage: "envelope.fill")
                        .font(.caption)
                    Label("Certificate: Trusted CA certificates", systemImage: "lock.doc.fill")
                        .font(.caption)
                    Label("Restrictions: Device feature limitations", systemImage: "hand.raised.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Check Manually") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings → General → VPN & Device Management")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Shows all installed configuration profiles")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
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
        .navigationTitle("Config Profile Audit")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { scanProfiles() }
    }

    private func scanProfiles() {
        isLoading = true
        var found: [ConfigProfile] = []
        let fm = FileManager.default

        let profileDirs: [(String, String)] = [
            ("/var/db/ConfigurationProfiles/", "System Profiles"),
            ("/var/mobile/Library/ConfigurationProfiles/", "User Profiles"),
            ("/var/MobileDevice/ProvisioningProfiles/", "Provisioning"),
            ("/Library/ConfigurationProfiles/", "Library Profiles")
        ]

        for (dir, category) in profileDirs {
            if let files = try? fm.contentsOfDirectory(atPath: dir) {
                for file in files {
                    let ext = (file as NSString).pathExtension.lowercased()
                    let profileType: String
                    let icon: String
                    let color: Color

                    switch ext {
                    case "mobileconfig":
                        profileType = "Configuration Profile"
                        icon = "doc.badge.gearshape"
                        color = .blue
                    case "mobileprovision":
                        profileType = "Provisioning Profile"
                        icon = "doc.fill"
                        color = .purple
                    case "plist":
                        profileType = "Property List"
                        icon = "doc.text.fill"
                        color = .orange
                    default:
                        profileType = category
                        icon = "doc.fill"
                        color = .secondary
                    }

                    found.append(ConfigProfile(name: file, type: profileType, path: dir, icon: icon, color: color))
                }
            }
        }

        if let embedded = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
            found.append(ConfigProfile(name: "embedded.mobileprovision", type: "App Provisioning", path: embedded, icon: "app.fill", color: .green))
        }

        profiles = found
        summary = [
            ("Total Profiles Found", "\(found.count)"),
            ("Configuration Profiles", "\(found.filter { $0.type == "Configuration Profile" }.count)"),
            ("Provisioning Profiles", "\(found.filter { $0.type.contains("Provisioning") }.count)"),
            ("System Config Files", "\(found.filter { $0.type == "Property List" }.count)")
        ]
        isLoading = false
    }
}
