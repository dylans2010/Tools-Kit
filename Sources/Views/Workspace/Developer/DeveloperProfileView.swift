import SwiftUI

struct DeveloperProfileView: View {
    @State private var profile = DeveloperProfile(
        displayName: "Jules Engineer",
        legalName: "Jules Verne",
        username: "jules_dev",
        pronouns: "they/them",
        bio: "Full-stack developer building Tools-Kit integrations.",
        website: "https://jules.dev",
        github: "github.com/julesdev",
        linkedin: "linkedin.com/in/julesdev",
        contactEmail: "jules@example.com",
        supportEmail: "support@jules.dev",
        isPublic: true,
        tier: .verified,
        skills: ["Swift", "SwiftUI", "Combine", "GraphQL"],
        preferredLanguages: ["Swift", "TypeScript", "Rust"]
    )

    @State private var showingImagePicker = false

    var body: some View {
        Form {
            Section("Identity") {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.accentColor.opacity(0.1))
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(width: 80, height: 80)

                    Button("Update Avatar") {
                        showingImagePicker = true
                    }
                }
                .padding(.vertical, 8)

                TextField("Display Name", text: $profile.displayName)
                TextField("Legal Name", text: $profile.legalName)
                TextField("Username", text: $profile.username)
                    .disabled(true) // Usually fixed
                TextField("Pronouns", text: $profile.pronouns)

                VStack(alignment: .leading) {
                    Text("Short Bio").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $profile.bio)
                        .frame(minHeight: 80)
                }
            }

            Section("Verification & Trust") {
                HStack {
                    Label("Status", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                    Spacer()
                    Text(profile.tier.rawValue)
                        .font(.subheadline.bold())
                }

                verificationStep(label: "Email Verification", status: true)
                verificationStep(label: "Phone Verification", status: true)
                verificationStep(label: "Government ID", status: true)
                verificationStep(label: "Organization Affiliation", status: false)

                if profile.tier != .enterprise {
                    Button("Start Enterprise Verification") {
                        // Action
                    }
                    .foregroundStyle(.blue)
                }
            }

            Section("Links & Contact") {
                TextField("Website", text: $profile.website)
                TextField("GitHub", text: $profile.github)
                TextField("LinkedIn", text: $profile.linkedin)
                TextField("Contact Email", text: $profile.contactEmail)
                TextField("Support Email", text: $profile.supportEmail)
            }

            Section("Development Profile") {
                HStack {
                    Text("Skills")
                    Spacer()
                    Text(profile.skills.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("Preferred SDK Languages")
                    Spacer()
                    Text(profile.preferredLanguages.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                LabeledContent("Member Since", value: profile.joinedDate.formatted(date: .long, time: .omitted))
            }

            Section("Privacy & Visibility") {
                Toggle("Public-facing Developer Page", isOn: $profile.isPublic)
                Text("Enabling this makes your profile and bio visible on Marketplace listing pages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advanced Scopes Requirements")
                        .font(.headline)
                    Text("The following fields must be completed before requesting High or Critical risk scopes:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    requirementCheckmark(label: "Tax ID / Business Registration", status: false)
                    requirementCheckmark(label: "Physical Business Address", status: true)
                    requirementCheckmark(label: "Data Handling Policy URL", status: true)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Developer Profile")
    }

    private func verificationStep(label: String, status: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Image(systemName: status ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(status ? .green : .secondary)
        }
    }

    private func requirementCheckmark(label: String, status: Bool) -> some View {
        HStack {
            Image(systemName: status ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(status ? .green : .red)
            Text(label)
                .font(.caption)
            Spacer()
        }
    }
}
