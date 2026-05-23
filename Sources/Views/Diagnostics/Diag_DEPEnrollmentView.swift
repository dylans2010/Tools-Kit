import SwiftUI

struct Diag_DEPEnrollmentView: View {
    @State private var checks: [(String, String, Bool)] = []
    @State private var isDEPEnrolled = false

    var body: some View {
        Form {
            Section("Device Enrollment Program (DEP)") {
                VStack(spacing: 12) {
                    Image(systemName: isDEPEnrolled ? "building.2.crop.circle.fill" : "building.2.crop.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(isDEPEnrolled ? .orange : .green)
                    Text(isDEPEnrolled ? "DEP Enrollment Detected" : "No DEP Enrollment")
                        .font(.headline)
                    Text(isDEPEnrolled ? "Device may be enrolled in Apple Business Manager" : "Device appears to be consumer-purchased")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Enrollment Checks") {
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

            Section("About DEP") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("DEP devices auto-enroll in MDM during setup", systemImage: "gear.badge").font(.caption)
                    Label("Cannot be removed by user — only by organization", systemImage: "lock.fill").font(.caption)
                    Label("Apple Business Manager (ABM) manages enrollment", systemImage: "building.2.fill").font(.caption)
                    Label("Affects resale value and usability", systemImage: "dollarsign.circle").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Impact for Repair Shops") {
                Text("DEP-enrolled devices may have restrictions that prevent factory reset or re-activation without the organization's MDM server. Always check DEP status before accepting a device for repair or purchase.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section { Button { checkDEP() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") } } }
        }
        .navigationTitle("DEP Enrollment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkDEP() }
    }

    private func checkDEP() {
        var results: [(String, String, Bool)] = []
        var enrolled = false
        let fm = FileManager.default

        let depFile = "/var/db/ConfigurationProfiles/Settings/CloudConfigurationDetails.plist"
        let hasDEP = fm.fileExists(atPath: depFile)
        if hasDEP { enrolled = true }
        results.append(("Cloud Configuration", hasDEP ? "DEP configuration file found" : "No DEP configuration", hasDEP))

        let profilesInstalled = fm.fileExists(atPath: "/var/db/ConfigurationProfiles/Settings/.profilesAreInstalled")
        if profilesInstalled { enrolled = true }
        results.append(("Configuration Profiles", profilesInstalled ? "Device has installed profiles" : "No installed profile markers", profilesInstalled))

        let mdmAgent = fm.fileExists(atPath: "/var/db/ConfigurationProfiles/Settings/com.apple.ManagedConfiguration.plist")
        if mdmAgent { enrolled = true }
        results.append(("MDM Agent", mdmAgent ? "Managed configuration present" : "No MDM agent detected", mdmAgent))

        let supervisionKeys = ["isSupervisedDevice", "IsSupervised"]
        let isSupervised = supervisionKeys.contains { UserDefaults.standard.bool(forKey: $0) }
        if isSupervised { enrolled = true }
        results.append(("Supervision Status", isSupervised ? "Device is supervised" : "Device is not supervised", isSupervised))

        let setupAssistant = fm.fileExists(atPath: "/var/mobile/Library/Preferences/com.apple.purplebuddy.plist")
        results.append(("Setup Assistant", setupAssistant ? "Setup assistant config found" : "No setup config detected", false))

        checks = results
        isDEPEnrolled = enrolled
    }
}
