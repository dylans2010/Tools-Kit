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
        try? await Task.sleep(nanoseconds: 300_000_000)
        releases = [
            GitHubRelease(tagName: "v2.0.0", name: "SDK 2.0 — Unified Platform", body: "Major release with unified WorkspaceSDK interface, kernel-based lifecycle management, service container DI, and enhanced connector system.", author: "maintainer", publishedAt: Date().addingTimeInterval(-86400), isLatest: true, isPrerelease: false, assets: ["ToolsKit-2.0.0.zip"], totalDownloads: 1250),
            GitHubRelease(tagName: "v2.0.0-rc.1", name: "SDK 2.0 Release Candidate", body: "Release candidate for testing. Includes all v2.0 features.", author: "maintainer", publishedAt: Date().addingTimeInterval(-604800), isLatest: false, isPrerelease: true, assets: ["ToolsKit-2.0.0-rc1.zip"], totalDownloads: 89),
            GitHubRelease(tagName: "v1.5.0", name: "AI Slides & Connector Improvements", body: "Added AI slide generation pipeline, enhanced connector health monitoring, fixed event bus memory leak.", author: "maintainer", publishedAt: Date().addingTimeInterval(-2592000), isLatest: false, isPrerelease: false, assets: ["ToolsKit-1.5.0.zip"], totalDownloads: 3400),
        ]
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
