import SwiftUI

struct DeveloperProfileView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @State private var showingEditSheet = false
    @State private var showingTierAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                profileHeader

                VStack(alignment: .leading, spacing: 16) {
                    Text("Impact Metrics").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase).tracking(1)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(label: "Apps Published", value: "12", icon: "app.badge.fill")
                        statCard(label: "API Reliability", value: "99.9%", icon: "bolt.fill")
                        statCard(label: "Total Installs", value: "1.4k", icon: "arrow.down.circle.fill")
                        statCard(label: "Reputation", value: "Gold", icon: "star.fill")
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Security & Identity").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase).tracking(1)

                    VStack(spacing: 1) {
                        settingRow(title: "Identity", value: profileService.profile.displayName, icon: "person.text.rectangle.fill")
                        settingRow(title: "Email", value: profileService.profile.email, icon: "envelope.fill")
                        settingRow(title: "Tier", value: profileService.profile.tier.rawValue, icon: "crown.fill", action: { showingTierAlert = true })
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                }

                Button(role: .destructive) {
                    // logout/reset logic
                } label: {
                    Text("Sign Out")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Profile")
        .toolbar {
            Button { showingEditSheet = true } label: {
                Text("Edit").font(.subheadline.bold())
            }
        }
        .sheet(isPresented: $showingEditSheet) { EditProfileSheet() }
        .alert("Identity Tier", isPresented: $showingTierAlert) {
            Button("Dismiss", role: .cancel) { }
        } message: {
            Text("Your developer tier is determined by your organization verification status and historical application performance.")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.primary.opacity(0.03))
                if !profileService.profile.avatarUrl.isEmpty, let url = URL(string: profileService.profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image { image.resizable() }
                        else { Image(systemName: "person.crop.circle.fill").resizable().foregroundStyle(.quaternary) }
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                }
            }
            .frame(width: 80, height: 80)

            VStack(spacing: 4) {
                Text(profileService.profile.displayName).font(.headline)
                Text("@\(profileService.profile.username) • \(profileService.profile.tier.rawValue)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func statCard(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundStyle(.accentColor)
            Text(value).font(.title3.bold())
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func settingRow(title: String, value: String, icon: String, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Image(systemName: icon).font(.caption).foregroundStyle(.secondary).frame(width: 20)
                Text(title).font(.subheadline)
                Spacer()
                Text(value).font(.subheadline).foregroundStyle(.secondary)
                if action != nil {
                    Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold)).foregroundStyle(.quaternary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }
}
