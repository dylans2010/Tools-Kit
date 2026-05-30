import SwiftUI

struct ComplianceChecklistView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    var body: some View {
        List {
            Section("Management & Legal Compliance") {
                complianceRow(label: "Developer Profile Complete", met: profileService.computeProfileCompleteness() > 0.8)
                complianceRow(label: "Contact Email Verified", met: !profileService.profile.contactEmail.isEmpty)
                complianceRow(label: "Support Terms Configured", met: !profileService.profile.supportEmail.isEmpty)
                complianceRow(label: "Privacy Policy Documented", met: !profileService.profile.website.isEmpty)
            }

            Section("App Readiness") {
                complianceRow(label: "Active App Registration", met: !appService.apps.isEmpty)
                complianceRow(label: "Version String Formatted", met: appService.apps.allSatisfy { $0.version.contains(".") })
                complianceRow(label: "Bundle IDs Unique", met: Set(appService.apps.map { $0.bundleId }).count == appService.apps.count)
            }
        }
        .navigationTitle("Compliance Checklist")
    }

    private func complianceRow(label: String, met: Bool) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Image(systemName: met ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(met ? .green : .orange)
        }
    }
}
