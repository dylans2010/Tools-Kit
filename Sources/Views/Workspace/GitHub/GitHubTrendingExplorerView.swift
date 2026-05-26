import SwiftUI

struct GitHubTrendingExplorerView: View {
    @State private var trendingRepos: [GitHubRepository] = []
    @State private var isLoading = false
    @State private var selectedLanguage = "Swift"

    var body: some View {
        List {
            Section {
                Picker("Language", selection: $selectedLanguage) {
                    Text("Swift").tag("Swift")
                    Text("Kotlin").tag("Kotlin")
                    Text("Python").tag("Python")
                    Text("Rust").tag("Rust")
                    Text("Go").tag("Go")
                }
                .pickerStyle(.menu)
                .onChange(of: selectedLanguage) { _, _ in fetchTrending() }
            }

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else {
                ForEach(trendingRepos) { repo in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
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

                        HStack(spacing: 12) {
                            Label("\(repo.stargazersCount)", systemImage: "star.fill")
                            if let lang = repo.language {
                                Label(lang, systemImage: "circle.fill")
                            }
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 4)
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
                // Using search API for trending
                let response: GitHubSearchResponse = try await GitHubAPIClient.shared.request(.trending(language: selectedLanguage))
                await MainActor.run {
                    self.trendingRepos = response.items
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch trending: \(error)")
                isLoading = false
            }
        }
    }
}

struct GitHubSearchResponse: Codable {
    let items: [GitHubRepository]
}
