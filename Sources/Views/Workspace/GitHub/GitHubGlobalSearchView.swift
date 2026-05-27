import SwiftUI

struct GitHubGlobalSearchView: View {
    @State private var query = ""
    @State private var searchType = "repositories"
    @State private var results: [SearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum SearchResult: Identifiable {
        case repository(GitHubRepository)
        case user(GitHubUser)
        case issue(GitHubIssue)

        var id: String {
            switch self {
            case .repository(let r): return "repo-\(r.id)"
            case .user(let u): return "user-\(u.id)"
            case .issue(let i): return "issue-\(i.id)"
            }
        }
    }

    let searchTypes = [
        "repositories": "Repos",
        "users": "Users",
        "issues": "Issues"
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search GitHub...", text: $query)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit { performSearch() }

                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Picker("Search Type", selection: $searchType) {
                    ForEach(searchTypes.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        Text(value).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: searchType) { _, _ in if !query.isEmpty { performSearch() } }
            }
            .padding()
            .background(Color(.systemBackground))

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if results.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "Search GitHub" : "No Results",
                    systemImage: "magnifyingglass",
                    description: Text(query.isEmpty ? "Find repositories, users, or issues across all of GitHub." : "Try a different search term.")
                )
            } else {
                List(results) { result in
                    switch result {
                    case .repository(let repo):
                        NavigationLink(destination: RepoDetailView(repository: repo)) {
                            RepoSearchRow(repo: repo)
                        }
                    case .user(let user):
                        HStack {
                            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())

                            Text(user.login).font(.headline)
                        }
                    case .issue(let issue):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(issue.title).font(.subheadline.bold())
                            HStack {
                                Text("#\(issue.number)").foregroundStyle(.secondary)
                                Text(issue.state.rawValue).font(.caption2.bold()).foregroundStyle(issue.state == .open ? .green : .red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Global Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performSearch() {
        guard !query.isEmpty else { return }
        isLoading = true
        results = []

        Task {
            do {
                switch searchType {
                case "repositories":
                    let response: GitHubGlobalSearchResponse<GitHubRepository> = try await GitHubAPIClient.shared.request(.globalSearch(type: "repositories", query: query))
                    results = response.items.map { .repository($0) }
                case "users":
                    let response: GitHubGlobalSearchResponse<GitHubUser> = try await GitHubAPIClient.shared.request(.globalSearch(type: "users", query: query))
                    results = response.items.map { .user($0) }
                case "issues":
                    let response: GitHubGlobalSearchResponse<GitHubIssue> = try await GitHubAPIClient.shared.request(.globalSearch(type: "issues", query: query))
                    results = response.items.map { .issue($0) }
                default:
                    break
                }
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

private struct RepoSearchRow: View {
    let repo: GitHubRepository
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repo.fullName).font(.headline)
            if let desc = repo.description {
                Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            HStack {
                Label("\(repo.stargazersCount)", systemImage: "star.fill")
                if let lang = repo.language {
                    Label(lang, systemImage: "circle.fill")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
