import SwiftUI

struct GitHubTrendingExplorerView: View {
    @State private var trendingRepos: [GitHubRepository] = []
    @State private var isLoading = false
    @State private var selectedLanguage = "Swift"
    @State private var timeRange = "daily"

    let languages = ["Swift", "Kotlin", "Python", "Rust", "Go", "TypeScript", "C++", "Ruby"]
    let ranges = ["daily", "weekly", "monthly"]

    var body: some View {
        List {
            Section {
                HStack {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    Picker("Range", selection: $timeRange) {
                        Text("Today").tag("daily")
                        Text("This Week").tag("weekly")
                        Text("This Month").tag("monthly")
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: selectedLanguage) { _, _ in fetchTrending() }
                .onChange(of: timeRange) { _, _ in fetchTrending() }
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else {
                ForEach(trendingRepos) { repo in
                    NavigationLink(destination: RepoDetailView(repository: repo)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                }
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())

                                Text("\(repo.owner.login) /").foregroundStyle(.secondary)
                                Text(repo.name).bold()
                            }
                            .font(.subheadline)

                            if let desc = repo.description {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            HStack(spacing: 16) {
                                Label("\(repo.stargazersCount.formatted(.number.notation(.compactName)))", systemImage: "star.fill")
                                    .foregroundStyle(.orange)

                                Label("\(repo.forksCount.formatted(.number.notation(.compactName)))", systemImage: "arrow.triangle.branch")
                                    .foregroundStyle(.blue)

                                if let lang = repo.language {
                                    Label(lang, systemImage: "circle.fill")
                                        .foregroundStyle(.primary)
                                }
                            }
                            .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Trending")
        .onAppear(perform: fetchTrending)
    }

    private func fetchTrending() {
        isLoading = true
        Task {
            do {
                // Approximate trending using search API
                // In a real app, you might use a specific trending scraper/API
                let query = "language:\(selectedLanguage) created:>\(dateString(for: timeRange))"
                let response: GitHubSearchResponse = try await GitHubAPIClient.shared.request(.searchRepos(query: query))
                await MainActor.run {
                    self.trendingRepos = response.items.sorted { $0.stargazersCount > $1.stargazersCount }
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch trending: \(error)")
                isLoading = false
            }
        }
    }

    private func dateString(for range: String) -> String {
        let calendar = Calendar.current
        let date: Date
        switch range {
        case "daily": date = calendar.date(byAdding: .day, value: -1, to: Date())!
        case "weekly": date = calendar.date(byAdding: .day, value: -7, to: Date())!
        case "monthly": date = calendar.date(byAdding: .month, value: -1, to: Date())!
        default: date = Date()
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct GitHubSearchResponse: Codable {
    let items: [GitHubRepository]
}
