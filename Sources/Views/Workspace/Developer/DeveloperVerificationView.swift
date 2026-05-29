import SwiftUI

struct DeveloperVerificationView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared

    var body: some View {
        List {
            Section("Verification Progress") {
                verificationRow(
                    title: "Email Verification",
                    description: "Confirm your contact email address.",
                    status: !profileService.profile.contactEmail.isEmpty
                )

                verificationRow(
                    title: "Organization Affiliation",
                    description: "Verify your status with a registered organization.",
                    status: profileService.profile.tier == .verified || profileService.profile.tier == .enterprise
                )

                verificationRow(
                    title: "Identity Check",
                    description: "Provide legal identification for enterprise access.",
                    status: profileService.profile.tier == .enterprise
                )
            }

            Section {
                Button("Start Next Step") {
                    // Start verification flow
                }
                .frame(maxWidth: .infinity)
                .disabled(profileService.profile.tier == .enterprise)
            }
        }
        .navigationTitle("Developer Verification")
    }

    private func verificationRow(title: String, description: String, status: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: status ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(status ? .green : .secondary)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
