import SwiftUI

struct GitHubRepoComparisonView: View {
    @State private var repo1 = ""
    @State private var repo2 = ""
    @State private var comparisonResult: ComparisonData?
    @State private var isLoading = false

    struct ComparisonData {
        let repo1: GitHubRepository
        let repo2: GitHubRepository
    }

    var body: some View {
        List {
            Section("Repository Comparison") {
                TextField("Owner/Repo 1", text: $repo1)
                    .autocapitalization(.none)
                TextField("Owner/Repo 2", text: $repo2)
                    .autocapitalization(.none)

                Button(action: compareRepos) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Compare Repositories").bold()
                    }
                }
                .disabled(isLoading || repo1.isEmpty || repo2.isEmpty)
            }

            if let data = comparisonResult {
                Section("Results") {
                    VStack(spacing: 16) {
                        HStack {
                            Text(data.repo1.name).font(.caption.bold()).frame(maxWidth: .infinity)
                            Text("VS").font(.caption2.bold()).foregroundStyle(.secondary)
                            Text(data.repo2.name).font(.caption.bold()).frame(maxWidth: .infinity)
                        }

                        CompareRow(label: "Stars", val1: data.repo1.stargazersCount, val2: data.repo2.stargazersCount)
                        CompareRow(label: "Forks", val1: data.repo1.forksCount, val2: data.repo2.forksCount)
                        CompareRow(label: "Watchers", val1: data.repo1.watchersCount, val2: data.repo2.watchersCount)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Repo Comparison")
    }

    private func compareRepos() {
        isLoading = true
        let parts1 = repo1.components(separatedBy: "/")
        let parts2 = repo2.components(separatedBy: "/")

        guard parts1.count == 2, parts2.count == 2 else {
            isLoading = false
            return
        }

        Task {
            do {
                async let r1: GitHubRepository = GitHubAPIClient.shared.request(.repoDetails(owner: parts1[0], repo: parts1[1]))
                async let r2: GitHubRepository = GitHubAPIClient.shared.request(.repoDetails(owner: parts2[0], repo: parts2[1]))

                let result = ComparisonData(repo1: try await r1, repo2: try await r2)

                await MainActor.run {
                    comparisonResult = result
                    isLoading = false
                }
            } catch {
                print("Failed to compare: \(error)")
                isLoading = false
            }
        }
    }
}

private struct CompareRow: View {
    let label: String
    let val1: Int
    let val2: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            HStack {
                Text("\(val1)").font(.headline).foregroundStyle(val1 >= val2 ? .green : .primary).frame(maxWidth: .infinity)
                Text("\(val2)").font(.headline).foregroundStyle(val2 >= val1 ? .green : .primary).frame(maxWidth: .infinity)
            }
        }
    }
}
