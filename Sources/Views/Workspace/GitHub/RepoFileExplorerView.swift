import SwiftUI

/// Browse repository files and directories.
struct RepoFileExplorerView: View {
    let owner: String
    let repo: String
    let path: String
    var branch: String? = nil

    @State private var contents: [GitHubContent] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if contents.isEmpty && !isLoading {
                Text("Empty Directory")
                    .foregroundColor(.secondary)
            } else {
                ForEach(contents, id: \.sha) { item in
                    ZStack {
                        if item.type == "dir" {
                            NavigationLink(destination: RepoFileExplorerView(owner: owner, repo: repo, path: item.path, branch: branch)) {
                                EmptyView()
                            }
                            .opacity(0)

                            Label(item.name, systemImage: "folder.fill")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            NavigationLink(destination: FileEditorView(owner: owner, repo: repo, path: item.path, branch: branch)) {
                                EmptyView()
                            }
                            .opacity(0)

                            Label(item.name, systemImage: "doc.text")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(path.isEmpty ? "Files" : (path as NSString).lastPathComponent)
        .overlay {
            if isLoading { ProgressView() }
        }
        .onAppear {
            fetchContents()
        }
    }

    private func fetchContents() {
        isLoading = true
        Task {
            do {
                self.contents = try await GitHubAPIClient.shared.request(.contents(owner: owner, repo: repo, path: path, ref: branch))
                // Sort directories first
                self.contents.sort { (a, b) -> Bool in
                    if a.type == b.type { return a.name < b.name }
                    return a.type == "dir"
                }
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}
