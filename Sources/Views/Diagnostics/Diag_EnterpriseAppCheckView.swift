import SwiftUI
import Security

struct Diag_EnterpriseAppCheckView: View {
    @State private var checks: [(String, String, Bool)] = []
    @State private var enterpriseIndicators: Int = 0

    var body: some View {
        Form {
            Section("Enterprise App Detection") {
                VStack(spacing: 12) {
                    Image(systemName: enterpriseIndicators > 0 ? "building.2.fill" : "building.2")
                        .font(.system(size: 52))
                        .foregroundStyle(enterpriseIndicators > 0 ? .orange : .green)
                    Text(enterpriseIndicators > 0 ? "Enterprise Configuration Detected" : "No Enterprise Management")
                        .font(.headline)
                    Text(enterpriseIndicators > 0 ? "\(enterpriseIndicators) enterprise indicators found" : "Device appears to be consumer-owned")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Enterprise Checks") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(check.2 ? .orange : .green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0).font(.subheadline.weight(.medium))
                            Text(check.1).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("What is Enterprise Management?") {
                Text("Enterprise management (MDM) allows organizations to remotely manage devices, enforce policies, install apps, and restrict features. Enterprise-enrolled devices may have limited functionality.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Check Manually") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings → General → VPN & Device Management")
                        .font(.caption)
                    Text("Settings → General → Profiles")
                        .font(.caption)
                }
            }

            Section { Button { runChecks() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") } } }
        }
        .navigationTitle("Enterprise App Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runChecks() }
    }

    private func runChecks() {
        var results: [(String, String, Bool)] = []
        var indicators = 0
        let fm = FileManager.default

        let mdmPaths = [
            "/var/db/ConfigurationProfiles/Settings/.profilesAreInstalled",
            "/var/db/ConfigurationProfiles/Settings/CloudConfigurationDetails.plist"
        ]
        let hasMDMFiles = mdmPaths.contains { fm.fileExists(atPath: $0) }
        if hasMDMFiles { indicators += 1 }
        results.append(("MDM Profiles", hasMDMFiles ? "MDM configuration files detected" : "No MDM files found", hasMDMFiles))

        let managedPaths = ["/var/ManagedPreferences/", "/var/ManagedPreferences/mobile/"]
        let hasManaged = managedPaths.contains { fm.fileExists(atPath: $0) }
        if hasManaged { indicators += 1 }
        results.append(("Managed Preferences", hasManaged ? "Managed preference files detected" : "No managed preferences", hasManaged))

        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        var certResult: CFTypeRef?
        let certStatus = SecItemCopyMatching(certQuery as CFDictionary, &certResult)
        let hasCerts = certStatus == errSecSuccess && (certResult as? [[String: Any]])?.isEmpty == false
        if hasCerts { indicators += 1 }
        results.append(("Enterprise Certificates", hasCerts ? "Identity certificates found in keychain" : "No enterprise certificates", hasCerts))

        let supervisionKeys = ["isSupervisedDevice", "IsSupervised"]
        let isSupervised = supervisionKeys.contains { UserDefaults.standard.bool(forKey: $0) }
        if isSupervised { indicators += 1 }
        results.append(("Device Supervision", isSupervised ? "Device appears supervised" : "Device is not supervised", isSupervised))

        if let embedded = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
           let data = FileManager.default.contents(atPath: embedded),
           let str = String(data: data, encoding: .ascii) {
            let isEnterprise = str.contains("ProvisionsAllDevices")
            if isEnterprise { indicators += 1 }
            results.append(("Enterprise Provisioning", isEnterprise ? "Enterprise provisioning profile detected" : "Standard provisioning", isEnterprise))
        }

        checks = results
        enterpriseIndicators = indicators
    }
}
