import SwiftUI

struct DeveloperProfileView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @State private var profile: DeveloperProfile
    @State private var showingSaveAlert = false
    @State private var isSaving = false

    init() {
        _profile = State(initialValue: DeveloperProfileService.shared.profile)
    }

    var body: some View {
        Form {
            Section("Public Profile") {
                avatarSection
                TextField("Display Name", text: $profile.displayName)
                TextField("Username", text: $profile.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            Section("Professional Information") {
                TextField("Organization", text: $profile.organization)
                TextField("Website", text: $profile.website)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextEditor(text: $profile.bio)
                    .frame(minHeight: 100)
            }

            Section("Developer Tier") {
                Picker("Tier", selection: $profile.tier) {
                    ForEach(DeveloperTier.allCases, id: \.self) { tier in
                        Text(tier.rawValue).tag(tier)
                    }
                }
            }

            Section {
                Button {
                    saveProfile()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save Profile Changes").bold()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Developer Profile")
        .alert("Profile Updated", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your professional developer profile has been synchronized successfully.")
        }
    }

    private var avatarSection: some View {
        HStack {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.1))
                if !profile.avatarUrl.isEmpty, let url = URL(string: profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else if phase.error != nil {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.red)
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

            VStack(alignment: .leading) {
                Button("Change Avatar") {
                    // Logic to update avatar URL
                }
                .font(.subheadline)
                Text("Square PNG or JPG, max 512KB").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.leading)
        }
        .padding(.vertical, 8)
    }

    private func saveProfile() {
        isSaving = true
        Task {
            try? await profileService.updateProfile(
                displayName: profile.displayName,
                legalName: profile.legalName,
                bio: profile.bio
            )
            await MainActor.run {
                isSaving = false
                showingSaveAlert = true
            }
        }
    }
}
