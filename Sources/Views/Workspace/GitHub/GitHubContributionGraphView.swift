import SwiftUI

struct GitHubContributionGraphView: View {
    let owner: String
    let repo: String
    @State private var repository: GitHubRepository?
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if let repoData = repository {
                Section("Repository Health") {
                    StatItem(label: "Stargazers", value: "\(repoData.stargazersCount)", icon: "star.fill", color: .orange)
                    StatItem(label: "Forks", value: "\(repoData.forksCount)", icon: "arrow.triangle.branch", color: .blue)
                    StatItem(label: "Watchers", value: "\(repoData.watchersCount)", icon: "eye.fill", color: .green)
                }

                Section("Activity Metadata") {
                    LabeledContent("Default Branch", value: repoData.defaultBranch)
                    LabeledContent("Main Language", value: repoData.language ?? "Unknown")
                    LabeledContent("Last Updated", value: repoData.updatedAt.formatted(date: .abbreviated, time: .omitted))
                }

                Section {
                    Link(destination: URL(string: repoData.htmlUrl)!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                }
            }
        }
        .navigationTitle("Repo Stats")
        .task {
            await fetchRepoData()
        }
    }

    private func fetchRepoData() async {
        isLoading = true
        do {
            repository = try await GitHubAPIClient.shared.request(.repoDetails(owner: owner, repo: repo))
            isLoading = false
        } catch {
            print("Failed to fetch repo data: \(error)")
            isLoading = false
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(color)
            Spacer()
            Text(value).font(.headline.bold())
        }
    }
}
