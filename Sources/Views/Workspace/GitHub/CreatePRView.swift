import SwiftUI

/// A form to create a new pull request.
struct CreatePRView: View {
    let owner: String
    let repo: String
    let onSuccess: () -> Void

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var head: String = ""
    @State private var base: String = "main"
    @State private var isSubmitting = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("PR Details") {
                    TextField("Title", text: $title)
                    TextField("Base Branch (e.g. main)", text: $base)
                    TextField("Head Branch (e.g. feature-branch)", text: $head)
                }

                Section("Description") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Pull Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPR()
                    }
                    .disabled(title.isEmpty || head.isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting { ProgressView() }
            }
        }
    }

    private func createPR() {
        isSubmitting = true

        struct PRPayload: Encodable {
            let title: String
            let body: String
            let head: String
            let base: String
        }

        let payload = PRPayload(title: title, body: bodyText, head: head, base: base)

        Task {
            do {
                let _: GitHubPullRequest = try await GitHubAPIClient.shared.request(.createPR(owner: owner, repo: repo), body: payload)
                await MainActor.run {
                    onSuccess()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}
