import SwiftUI

struct GitHubControlsView: View {
    @State private var user: GitHubAuthenticatedUser?
    @State private var scopes: [String] = []
    @State private var rateLimit: GitHubRateLimitResources?
    @State private var isLoading = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                userSection
                toolsSection
                authSection
                rateLimitSection
                managementSection
            }
            .navigationTitle("GitHub Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await refreshData()
            }
            .overlay {
                if isLoading && user == nil {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown Error")
            }
        }
    }

    @ViewBuilder
    private var userSection: some View {
        if let user = user {
            Section {
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: user.avatarUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name ?? user.login)
                            .font(.headline)
                        Text("@\(user.login)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)

                if let bio = user.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    StatItem(title: "Repos", value: "\(user.publicRepos)")
                    Divider()
                    StatItem(title: "Gists", value: "\(user.publicGists)")
                    Divider()
                    StatItem(title: "Followers", value: "\(user.followers)")
                }
                .padding(.vertical, 4)
            } header: {
                Text("Authenticated User")
            }
        }
    }

    @ViewBuilder
    private var toolsSection: some View {
        Section {
            NavigationLink(destination: GitHubNotificationsView()) {
                Label("Notifications", systemImage: "bell.badge")
            }
            if let login = user?.login {
                NavigationLink(destination: GitHubUserActivityView(username: login)) {
                    Label("Recent Activity", systemImage: "bolt.horizontal")
                }
            }
            NavigationLink(destination: GitHubGistListView()) {
                Label("My Gists", systemImage: "doc.plaintext")
            }
        } header: {
            Text("Tools & Services")
        }
    }

    @ViewBuilder
    private var authSection: some View {
        Section {
            HStack {
                Text("Token")
                Spacer()
                Text(maskedToken)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Authorized Scopes")
                    .font(.caption.bold())
                if scopes.isEmpty {
                    Text("No specific scopes detected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(scopes, id: \.self) { scope in
                                Text(scope)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            Button(role: .destructive) {
                logout()
            } label: {
                Label("Revoke Token & Logout", systemImage: "key.slash")
            }
        } header: {
            Text("Authentication")
        }
    }

    @ViewBuilder
    private var rateLimitSection: some View {
        if let rl = rateLimit {
            Section {
                RateLimitRow(title: "Core API", limit: rl.core)
                RateLimitRow(title: "Search API", limit: rl.search)
                RateLimitRow(title: "GraphQL", limit: rl.graphql)
            } header: {
                Text("API Rate Limits")
            }
        }
    }

    @ViewBuilder
    private var managementSection: some View {
        Section {
            Button {
                Task { await refreshData() }
            } label: {
                Label("Validate Connection", systemImage: "checkmark.seal")
            }

            Button {
                WorkspaceNotificationService.shared.post(title: "Cache Cleared", body: "GitHub API local cache has been reset.", category: .info)
            } label: {
                Label("Clear API Cache", systemImage: "trash")
            }
            .foregroundStyle(.secondary)
        } header: {
            Text("Management")
        }
    }

    private var maskedToken: String {
        guard let token = GitHubAuthManager.shared.getToken() else { return "None" }
        if token.count > 8 {
            return String(token.prefix(4)) + "...." + String(token.suffix(4))
        }
        return "********"
    }

    private func refreshData() async {
        isLoading = true
        do {
            async let userReq: (GitHubAuthenticatedUser, [AnyHashable: Any]) = GitHubAPIClient.shared.requestWithHeaders(.user)
            async let rlReq: GitHubRateLimitResponse = GitHubAPIClient.shared.request(.rateLimit)

            let (userData, headers) = try await userReq
            let rlData = try await rlReq

            await MainActor.run {
                self.user = userData
                self.rateLimit = rlData.resources

                if let scopeHeader = headers["x-oauth-scopes"] as? String {
                    self.scopes = scopeHeader.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                } else if let altScopeHeader = headers["X-OAuth-Scopes"] as? String {
                    self.scopes = altScopeHeader.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func logout() {
        GitHubAuthManager.shared.deleteToken()
        UserDefaults.standard.removeObject(forKey: "github_pat_token")
        dismiss()
    }
}

private struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RateLimitRow: View {
    let title: String
    let limit: GitHubRateLimit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(limit.remaining) / \(limit.limit)").font(.caption.monospaced())
            }
            ProgressView(value: Double(limit.used), total: Double(limit.limit))
                .tint(progressColor)
        }
        .padding(.vertical, 2)
    }

    private var progressColor: Color {
        let ratio = Double(limit.remaining) / Double(limit.limit)
        if ratio < 0.2 { return .red }
        if ratio < 0.5 { return .orange }
        return .green
    }
}
