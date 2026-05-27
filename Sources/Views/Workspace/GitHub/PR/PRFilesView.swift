import SwiftUI

struct PRFilesView: View {
    let owner: String
    let repo: String
    let pullRequest: GitHubPullRequest

    @State private var files: [GitHubFileDiff] = []
    @State private var isLoading = false

    var body: some View {
        List(files, id: \.sha) { file in
            NavigationLink(destination: DiffView(fileDiff: file)) {
                HStack {
                    Image(systemName: fileStatusIcon(for: file.status))
                        .foregroundStyle(fileStatusColor(for: file.status))

                    VStack(alignment: .leading) {
                        Text(file.filename)
                            .font(.system(.subheadline, design: .monospaced))
                        Text("\(file.additions) additions, \(file.deletions) deletions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Files Changed")
        .overlay {
            if isLoading { ProgressView() }
        }
        .task {
            await fetchFiles()
        }
    }

    private func fetchFiles() async {
        isLoading = true
        do {
            let comparison: GitHubComparison = try await GitHubAPIClient.shared.request(.compare(owner: owner, repo: repo, base: pullRequest.base.ref, head: pullRequest.head.sha))
            files = comparison.files
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func fileStatusIcon(for status: String) -> String {
        switch status {
        case "added": return "plus.square.fill"
        case "removed": return "minus.square.fill"
        case "modified": return "pencil.square.fill"
        default: return "doc.fill"
        }
    }

    private func fileStatusColor(for status: String) -> Color {
        switch status {
        case "added": return .green
        case "removed": return .red
        case "modified": return .orange
        default: return .secondary
        }
    }
}
