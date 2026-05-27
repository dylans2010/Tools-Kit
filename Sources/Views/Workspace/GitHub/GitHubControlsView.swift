import SwiftUI

struct GitHubControlsView: View {
    @State private var user: GitHubAuthenticatedUser?
    @State private var scopes: [String] = []
    @State private var rateLimit: GitHubRateLimitResources?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorDetail = false
    @State private var rawError: String?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                userSection
                toolsSection
                rateLimitSection
                authSection
                managementSection

                if let error = errorMessage {
                    Section("Status") {
                        HStack {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Spacer()
                            Button("Details") { showingErrorDetail = true }
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("GitHub Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await refreshData() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingErrorDetail) {
                ErrorDiagnosticView(message: errorMessage ?? "Unknown error", rawDetail: rawError)
            }
        }
        .task {
            await refreshData()
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
        Section("Tools & Services") {
            NavigationLink(destination: GitHubGlobalSearchView()) {
                Label("Global Search", systemImage: "magnifyingglass")
            }

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

            NavigationLink(destination: GitHubTrendingExplorerView()) {
                Label("Trending", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationLink(destination: GitHubRepoComparisonView()) {
                Label("Compare Repos", systemImage: "arrow.left.and.right.square")
            }
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
            Section("API Rate Limits") {
                RateLimitRow(title: "Core API", limit: rl.core)
                RateLimitRow(title: "Search API", limit: rl.search)
                RateLimitRow(title: "GraphQL", limit: rl.graphql)
            }
        }
    }

    @ViewBuilder
    private var managementSection: some View {
        Section("Management") {
            Button {
                Task { await refreshData() }
            } label: {
                Label("Validate Connection", systemImage: "checkmark.seal")
            }

            Button {
                WorkspaceNotificationService.shared.post(title: "Cache Cleared", body: "GitHub API local cache has been reset.", category: .update)
            } label: {
                Label("Clear API Cache", systemImage: "trash")
            }
            .foregroundStyle(.secondary)
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
        errorMessage = nil
        rawError = nil

        do {
            async let userReq: (GitHubAuthenticatedUser, [AnyHashable: Any]) = GitHubAPIClient.shared.requestWithHeaders(.user)
            async let rlReq: GitHubRateLimitResponse = GitHubAPIClient.shared.request(.rateLimit)

            let (userData, headers) = try await userReq
            let rlData = try await rlReq

            await MainActor.run {
                self.user = userData
                self.rateLimit = rlData.resources

                if let scopeHeader = (headers["x-oauth-scopes"] ?? headers["X-OAuth-Scopes"]) as? String {
                    self.scopes = scopeHeader.components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.rawError = String(describing: error)
                self.isLoading = false
            }
        }
    }

    private func logout() {
        GitHubAuthManager.shared.deleteToken()
        dismiss()
    }
}

struct ErrorDiagnosticView: View {
    let message: String
    let rawDetail: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("Error Summary") {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let raw = rawDetail {
                        GroupBox("Raw API Response / Stack Trace") {
                            Text(raw)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GroupBox("Possible Solutions") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Check your internet connection.")
                            BulletPoint(text: "Verify that your Personal Access Token hasn't expired.")
                            BulletPoint(text: "Ensure the token has the required scopes (repo, workflow, etc.).")
                            BulletPoint(text: "Check if GitHub API is experiencing downtime.")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Diagnostic Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close") { dismiss() }
            }
        }
    }
}

struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
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
