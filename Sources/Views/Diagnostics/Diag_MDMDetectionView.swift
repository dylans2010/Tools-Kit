import SwiftUI
import Security

struct Diag_MDMDetectionView: View {
    @State private var checks: [(String, String, MDMStatus)] = []
    @State private var overallStatus: MDMStatus = .unknown
    @State private var hasChecked = false
    @State private var configProfiles: [String] = []

    enum MDMStatus: String {
        case detected = "Detected"
        case notDetected = "Not Detected"
        case unknown = "Unknown"

        var color: Color {
            switch self {
            case .detected: return .orange
            case .notDetected: return .green
            case .unknown: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .detected: return "exclamationmark.shield.fill"
            case .notDetected: return "checkmark.shield.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }

    var body: some View {
        Form {
            Section("MDM Enrollment Status") {
                VStack(spacing: 12) {
                    Image(systemName: overallStatus.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(overallStatus.color)
                    Text(overallStatus == .detected ? "MDM Profile Detected" : overallStatus == .notDetected ? "No MDM Detected" : "Checking...")
                        .font(.headline)
                    Text(overallStatus == .detected ? "This device appears to be managed" : overallStatus == .notDetected ? "Device appears unmanaged" : "Running checks...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("MDM Checks") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2.icon)
                            .foregroundStyle(check.2.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.1)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !configProfiles.isEmpty {
                Section("Detected Configuration Profiles") {
                    ForEach(configProfiles, id: \.self) { profile in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(.blue)
                            Text(profile)
                                .font(.subheadline)
                        }
                    }
                }
            }

            Section("What is MDM?") {
                Text("Mobile Device Management (MDM) allows organizations to remotely manage, configure, and restrict devices. MDM-enrolled devices may have restrictions on apps, settings, and data access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    runMDMChecks()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-run Checks")
                    }
                }
            }
        }
        .navigationTitle("MDM Detection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runMDMChecks() }
    }

    private func runMDMChecks() {
        var results: [(String, String, MDMStatus)] = []
        var profiles: [String] = []
        let fm = FileManager.default

        let mdmPaths = [
            "/var/db/ConfigurationProfiles/Settings/.profilesAreInstalled",
            "/Library/ConfigurationProfiles/",
            "/var/db/ConfigurationProfiles/"
        ]
        var mdmPathFound = false
        for path in mdmPaths {
            if fm.fileExists(atPath: path) {
                mdmPathFound = true
                break
            }
        }
        results.append(("Configuration Profiles Path", mdmPathFound ? "MDM profile directory found" : "No MDM profile directories detected", mdmPathFound ? .detected : .notDetected))

        let restrictedPaths = [
            "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles",
            "/var/ManagedPreferences/",
            "/var/db/ManagedPreferences/"
        ]
        var managedPrefsFound = false
        for path in restrictedPaths {
            if fm.fileExists(atPath: path) {
                managedPrefsFound = true
                break
            }
        }
        results.append(("Managed Preferences", managedPrefsFound ? "Managed preference files detected" : "No managed preferences found", managedPrefsFound ? .detected : .notDetected))

        let enrollmentQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        var enrollmentResult: CFTypeRef?
        let enrollmentStatus = SecItemCopyMatching(enrollmentQuery as CFDictionary, &enrollmentResult)
        let hasEnrollmentCerts = enrollmentStatus == errSecSuccess
        if hasEnrollmentCerts, let items = enrollmentResult as? [[String: Any]] {
            for item in items {
                if let label = item[kSecAttrLabel as String] as? String {
                    if label.lowercased().contains("mdm") || label.lowercased().contains("management") || label.lowercased().contains("profile") {
                        profiles.append(label)
                    }
                }
            }
        }
        results.append(("MDM Certificates", hasEnrollmentCerts ? "Device identity certificates found in keychain" : "No MDM certificates in keychain", hasEnrollmentCerts ? .detected : .notDetected))

        let defaults = UserDefaults.standard
        let supervisionKeys = ["isSupervisedDevice", "IsSupervised"]
        var isSupervised = false
        for key in supervisionKeys {
            if defaults.bool(forKey: key) {
                isSupervised = true
                break
            }
        }
        results.append(("Device Supervision", isSupervised ? "Device appears supervised" : "Not supervised", isSupervised ? .detected : .notDetected))

        let restrictionPaths = [
            "/var/mobile/Library/UserConfigurationProfiles/EffectiveUserSettings.plist",
            "/var/mobile/Library/ConfigurationProfiles/PublicInfo/EffectiveUserSettings.plist"
        ]
        var hasRestrictions = false
        for path in restrictionPaths {
            if fm.fileExists(atPath: path) {
                hasRestrictions = true
                break
            }
        }
        results.append(("Active Restrictions", hasRestrictions ? "Restriction profiles found" : "No restriction profiles", hasRestrictions ? .detected : .notDetected))

        let depPaths = ["/var/db/ConfigurationProfiles/Settings/CloudConfigurationDetails.plist"]
        var isDEP = false
        for path in depPaths {
            if fm.fileExists(atPath: path) {
                isDEP = true
                break
            }
        }
        results.append(("DEP Enrollment", isDEP ? "Device Enrollment Program detected" : "No DEP enrollment detected", isDEP ? .detected : .notDetected))

        checks = results
        configProfiles = profiles
        overallStatus = results.contains(where: { $0.2 == .detected }) ? .detected : .notDetected
        hasChecked = true
    }
}
