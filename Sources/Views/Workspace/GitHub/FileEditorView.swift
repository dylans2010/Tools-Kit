import SwiftUI

/// View and edit a file.
struct FileEditorView: View {
    let owner: String
    let repo: String
    let path: String
    var branch: String? = nil

    @State private var fileContent: GitHubContent?
    @State private var text: String = ""
    @State private var isLoading = false
    @State private var isEditing = false
    @State private var showingCommitComposer = false

    var body: some View {
        VStack {
            if isEditing {
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
            } else {
                ScrollView {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .navigationTitle((path as NSString).lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Save") {
                        showingCommitComposer = true
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCommitComposer) {
            CommitComposerView(owner: owner, repo: repo, path: path, branch: branch, currentSHA: fileContent?.sha, originalContent: text) { updated in
                self.fileContent = updated
                self.isEditing = false
                fetchFile()
            }
        }
        .overlay {
            if isLoading { ProgressView() }
        }
        .onAppear {
            fetchFile()
        }
    }

    private func fetchFile() {
        isLoading = true
        Task {
            do {
                let content: GitHubContent = try await GitHubAPIClient.shared.request(.contents(owner: owner, repo: repo, path: path, ref: branch))
                self.fileContent = content
                if let base64 = content.content, let decodedData = Data(base64Encoded: base64.replacingOccurrences(of: "\n", with: ""), options: .ignoreUnknownCharacters) {
                    self.text = String(data: decodedData, encoding: .utf8) ?? "Unable to decode file content."
                }
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}
