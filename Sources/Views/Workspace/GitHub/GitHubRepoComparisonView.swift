import SwiftUI

struct GitHubRepoComparisonView: View {
    @State private var repo1 = ""
    @State private var repo2 = ""
    @State private var comparisonResult: ComparisonData?
    @State private var isLoading = false

    struct ComparisonData {
        let repo1: GitHubRepository
        let repo2: GitHubRepository
        let contributors1: Int
        let contributors2: Int
        let languages1: [String: Int]
        let languages2: [String: Int]
    }

    var body: some View {
        List {
            Section("Repository Comparison") {
                TextField("Owner/Repo 1", text: $repo1)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                TextField("Owner/Repo 2", text: $repo2)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

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
                Section("Head to Head") {
                    VStack(spacing: 20) {
                        HStack {
                            RepoHeader(repo: data.repo1).frame(maxWidth: .infinity)
                            Text("VS").font(.title3.bold()).foregroundStyle(.secondary)
                            RepoHeader(repo: data.repo2).frame(maxWidth: .infinity)
                        }

                        Divider()

                        CompareRow(label: "Stars", val1: data.repo1.stargazersCount, val2: data.repo2.stargazersCount)
                        CompareRow(label: "Forks", val1: data.repo1.forksCount, val2: data.repo2.forksCount)
                        CompareRow(label: "Watchers", val1: data.repo1.watchersCount, val2: data.repo2.watchersCount)
                        CompareRow(label: "Contributors", val1: data.contributors1, val2: data.contributors2)
                    }
                    .padding(.vertical)
                }

                Section("Top Languages") {
                    HStack(alignment: .top) {
                        LanguageList(languages: data.languages1).frame(maxWidth: .infinity)
                        Divider()
                        LanguageList(languages: data.languages2).frame(maxWidth: .infinity)
                    }
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

                async let c1: [GitHubContributor] = GitHubAPIClient.shared.request(.repoContributors(owner: parts1[0], repo: parts1[1]))
                async let c2: [GitHubContributor] = GitHubAPIClient.shared.request(.repoContributors(owner: parts2[0], repo: parts2[1]))

                async let l1: [String: Int] = GitHubAPIClient.shared.request(.repoLanguages(owner: parts1[0], repo: parts1[1]))
                async let l2: [String: Int] = GitHubAPIClient.shared.request(.repoLanguages(owner: parts2[0], repo: parts2[1]))

                let result = ComparisonData(
                    repo1: try await r1,
                    repo2: try await r2,
                    contributors1: (try? await c1.count) ?? 0,
                    contributors2: (try? await c2.count) ?? 0,
                    languages1: (try? await l1) ?? [:],
                    languages2: (try? await l2) ?? [:]
                )

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

private struct RepoHeader: View {
    let repo: GitHubRepository
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            Text(repo.name).font(.subheadline.bold()).multilineTextAlignment(.center)
        }
    }
}

private struct LanguageList: View {
    let languages: [String: Int]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let sorted = languages.sorted { $0.value > $1.value }.prefix(5)
            ForEach(Array(sorted), id: \.key) { lang, bytes in
                HStack {
                    Text(lang).font(.caption2)
                    Spacer()
                    Text("\(bytes.formatted(.number.notation(.compactName)))")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
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
            Text(label).font(.caption2.bold()).foregroundStyle(.secondary).textCase(.uppercase)
            HStack {
                Text("\(val1.formatted())").font(.headline).foregroundStyle(val1 >= val2 ? .green : .primary).frame(maxWidth: .infinity)
                Text("\(val2.formatted())").font(.headline).foregroundStyle(val2 >= val1 ? .green : .primary).frame(maxWidth: .infinity)
            }
        }
    }
}
