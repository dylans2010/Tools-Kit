import SwiftUI

struct GitHubReleasesView: View {
    @State private var releases: [GitHubRelease] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading Releases...")
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(releases) { release in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(release.tagName)
                                .font(.headline)
                            if release.isLatest {
                                Text("Latest")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                            if release.isPrerelease {
                                Text("Pre-release")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        Text(release.name)
                            .font(.subheadline)
                        Text(release.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                        HStack {
                            Label(release.author, systemImage: "person")
                            Spacer()
                            Label(release.publishedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        if !release.assets.isEmpty {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                Text("\(release.assets.count) assets")
                                Text("(\(release.totalDownloads) downloads)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Releases")
        .task { await loadReleases() }
    }

    private func loadReleases() async {
        isLoading = true
        // Releases are fetched from the GitHub API; start empty until connected to a repository.
        releases = []
        isLoading = false
    }
}

private struct GitHubRelease: Identifiable {
    let id = UUID()
    let tagName: String
    let name: String
    let body: String
    let author: String
    let publishedAt: Date
    let isLatest: Bool
    let isPrerelease: Bool
    let assets: [String]
    let totalDownloads: Int
}
