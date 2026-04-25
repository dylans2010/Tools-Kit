import SwiftUI

/// A composer to create a new commit (via the contents API).
struct CommitComposerView: View {
    let owner: String
    let repo: String
    let path: String
    var branch: String? = nil
    let currentSHA: String?
    let originalContent: String

    @State private var message: String = ""
    @State private var content: String = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) var dismiss

    var onCommit: (GitHubContent) -> Void

    init(owner: String, repo: String, path: String, branch: String? = nil, currentSHA: String?, originalContent: String, onCommit: @escaping (GitHubContent) -> Void) {
        self.owner = owner
        self.repo = repo
        self.path = path
        self.branch = branch
        self.currentSHA = currentSHA
        self.originalContent = originalContent
        self.onCommit = onCommit
        _content = State(initialValue: originalContent)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Commit Message") {
                    TextField("Update \(path)", text: $message)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Commit Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Commit") {
                        submitCommit()
                    }
                    .disabled(message.isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                }
            }
        }
    }

    private func submitCommit() {
        isSubmitting = true

        let base64Content = content.data(using: .utf8)?.base64EncodedString() ?? ""

        struct CommitPayload: Encodable {
            let message: String
            let content: String
            let sha: String?
        }

        struct CommitPayload: Encodable {
            let message: String
            let content: String
            let sha: String?
            let branch: String?
        }

        let payload = CommitPayload(message: message, content: base64Content, sha: currentSHA, branch: branch)

        Task {
            do {
                let updatedContent: GitHubContent = try await GitHubAPIClient.shared.request(.contents(owner: owner, repo: repo, path: path, ref: nil), body: payload)
                await MainActor.run {
                    onCommit(updatedContent)
                    dismiss()
                }
            } catch {
                // In a real app, show alert
                isSubmitting = false
            }
        }
    }
}
