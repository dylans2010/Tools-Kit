import SwiftUI

struct DeveloperProfileView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var profile: DeveloperProfile
    @State private var showingImagePicker = false
    @State private var showingSaveAlert = false

    init() {
        _profile = State(initialValue: DeveloperPersistentStore.shared.profile)
    }

    var body: some View {
        Form {
            Section("Identity") {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.accentColor.opacity(0.1))
                        if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color.accentColor)
                        }
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
                TextField("Pronouns", text: $profile.pronouns)

                VStack(alignment: .leading) {
                    Text("Short Bio").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $profile.bio)
                        .frame(minHeight: 80)
                }
            }

            Section("Experience & Credits") {
                VStack(alignment: .leading) {
                    Text("Professional Experience").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $profile.experience)
                        .frame(minHeight: 80)
                }
                VStack(alignment: .leading) {
                    Text("Credits / Shoutouts").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $profile.credits)
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

                verificationStep(label: "Email Verification", status: !profile.contactEmail.isEmpty)
                verificationStep(label: "Developer Key Generated", status: !store.keys.isEmpty)
                verificationStep(label: "Identity Verified", status: profile.tier == .verified || profile.tier == .enterprise)
            }

            Section("Links & Contact") {
                TextField("Website", text: $profile.website)
                TextField("GitHub", text: $profile.github)
                TextField("LinkedIn", text: $profile.linkedin)
                TextField("Contact Email", text: $profile.contactEmail)
                TextField("Support Email", text: $profile.supportEmail)
            }

            Section("Privacy & Visibility") {
                Toggle("Public-facing Developer Page", isOn: $profile.isPublic)
                Text("Enabling this makes your profile and bio visible on Marketplace listing pages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Developer Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.saveProfile(profile)
                    showingSaveAlert = true
                }
            }
        }
        .alert("Profile Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        }
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
}
