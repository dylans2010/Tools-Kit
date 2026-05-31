import SwiftUI

struct DeveloperProfileView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @State private var showingEditSheet = false
    @State private var showingTierAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader

                VStack(alignment: .leading, spacing: 16) {
                    Text("Developer Stats").font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(label: "Apps Published", value: "12", icon: "app.badge.fill")
                        statCard(label: "API Reputation", value: "99.9", icon: "star.fill")
                        statCard(label: "Contributions", value: "1.4k", icon: "hammer.fill")
                        statCard(label: "Forum Rank", value: "Gold", icon: "medal.fill")
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Settings").font(.headline)

                    VStack(spacing: 1) {
                        settingRow(title: "Display Name", value: profileService.profile.displayName, icon: "person.fill")
                        settingRow(title: "Username", value: "@\(profileService.profile.username)", icon: "at")
                        settingRow(title: "Email", value: profileService.profile.email, icon: "envelope.fill")
                        settingRow(title: "Developer Tier", value: profileService.profile.tier.rawValue, icon: "crown.fill", action: { showingTierAlert = true })
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Developer Profile")
        .toolbar {
            Button("Edit") { showingEditSheet = true }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProfileSheet()
        }
        .alert("Tier Upgrade", isPresented: $showingTierAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("To upgrade your developer tier, please complete the organization verification process.")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.1))
                if !profileService.profile.avatarUrl.isEmpty, let url = URL(string: profileService.profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image { image.resizable() }
                        else { Image(systemName: "person.crop.circle.fill").resizable().foregroundStyle(.secondary) }
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(width: 100, height: 100)

            VStack(spacing: 4) {
                Text(profileService.profile.displayName).font(.title2.bold())
                Text(profileService.profile.tier.rawValue + " Developer").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func statCard(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.accentColor)
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func settingRow(title: String, value: String, icon: String, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24)
                Text(title).font(.subheadline)
                Spacer()
                Text(value).font(.subheadline).foregroundStyle(.secondary)
                if action != nil {
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }
}

struct EditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var profileService = DeveloperProfileService.shared
    @State private var name = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Information") {
                    TextField("Display Name", text: $name)
                    TextField("Email", text: $email)
                }
            }
            .navigationTitle("Edit Profile")
            .onAppear {
                name = profileService.profile.displayName
                email = profileService.profile.email
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var p = profileService.profile
                        p.displayName = name
                        p.email = email
                        profileService.updateProfile(p)
                        dismiss()
                    }
                }
            }
        }
    }
}
