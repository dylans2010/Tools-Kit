import SwiftUI

struct DeveloperProfileView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @State private var profile: DeveloperProfile
    @State private var showingSaveAlert = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    init() {
        _profile = State(initialValue: DeveloperProfileService.shared.profile)
    }

    var body: some View {
        Form {
            Section("Identity") {
                avatarSection

                TextField("Display Name", text: $profile.displayName)
                    .textContentType(.name)
                TextField("Legal Name", text: $profile.legalName)
                    .textContentType(.name)
                TextField("Username", text: $profile.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                TextField("Pronouns", text: $profile.pronouns)

                VStack(alignment: .leading) {
                    Text("Short Bio").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $profile.bio)
                        .frame(minHeight: 80)
                }
            }

            Section("Professional Info") {
                VStack(alignment: .leading) {
                    Text("Professional Experience").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $profile.experience)
                        .frame(minHeight: 80)
                }
                VStack(alignment: .leading) {
                    Text("Credits & Contributions").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $profile.credits)
                        .frame(minHeight: 80)
                }
            }

            Section("Verification & Tier") {
                HStack {
                    Label("Tier", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                    Spacer()
                    Text(profile.tier.rawValue)
                        .font(.subheadline.bold())
                }

                verificationStep(label: "Contact Email Set", status: !profile.contactEmail.isEmpty)
                verificationStep(label: "Active API Key", status: !keyService.keys.filter { !$0.isRevoked }.isEmpty)
                verificationStep(label: "Identity Verified", status: profile.verificationStatus == .verified)
            }

            Section("Links & Contact") {
                HStack {
                    Image(systemName: "link")
                    TextField("Website", text: $profile.website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                HStack {
                    Image(systemName: "at")
                    TextField("GitHub Username", text: $profile.github)
                        .autocapitalization(.none)
                }
                HStack {
                    Image(systemName: "network")
                    TextField("LinkedIn URL", text: $profile.linkedin)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                HStack {
                    Image(systemName: "envelope")
                    TextField("Contact Email", text: $profile.contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                HStack {
                    Image(systemName: "lifepreserver")
                    TextField("Support Email", text: $profile.supportEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }

            Section("Privacy Settings") {
                Toggle("Public Profile Visibility", isOn: $profile.isPublic)
                Text("When enabled, your display name and bio are visible on Marketplace listings for your published apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Address") {
                TextField("Street", text: $profile.address.street)
                TextField("City", text: $profile.address.city)
                TextField("State/Province", text: $profile.address.state)
                TextField("Postal Code", text: $profile.address.postalCode)
                TextField("Country", text: $profile.address.country)
            }
        }
        .navigationTitle("Developer Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!hasChanges)
                }
            }
        }
        .alert("Profile Updated", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your developer profile changes have been successfully persisted.")
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred.")
        }
    }

    private var avatarSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.1))
                if !profile.avatarUrl.isEmpty, let url = URL(string: profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            ProgressView()
                        }
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

            VStack(alignment: .leading, spacing: 4) {
                Text("Profile Photo").font(.subheadline.bold())
                Button("Change Photo") {
                    // Logic for image picking using FileImporterView or similar
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 8)
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

    private var hasChanges: Bool {
        // Simple comparison for functional check
        profile.displayName != profileService.profile.displayName ||
        profile.username != profileService.profile.username ||
        profile.bio != profileService.profile.bio ||
        profile.contactEmail != profileService.profile.contactEmail ||
        profile.isPublic != profileService.profile.isPublic
    }

    private func saveProfile() {
        isSaving = true
        Task {
            do {
                try await profileService.saveProfile(profile)
                await MainActor.run {
                    isSaving = false
                    showingSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
