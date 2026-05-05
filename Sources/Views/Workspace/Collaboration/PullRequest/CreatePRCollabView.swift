import SwiftUI

struct CreatePRCollabView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var prManager = PullRequestManager.shared

    let spaceID: UUID

    @State private var title = ""
    @State private var description = ""
    @State private var sourceBranch = ""
    @State private var targetBranch = "main"
    @State private var selectedRepo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("PR Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...10)
                }

                Section("Branches") {
                    TextField("Source Branch", text: $sourceBranch)
                    TextField("Target Branch", text: $targetBranch)
                }

                Section("Repository") {
                    TextField("Repository Name", text: $selectedRepo)
                }
            }
            .navigationTitle("Create Pull Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPR()
                    }
                    .disabled(title.isEmpty || sourceBranch.isEmpty || selectedRepo.isEmpty)
                }
            }
        }
    }

    private func createPR() {
        _ = prManager.createPullRequest(
            spaceID: spaceID,
            title: title,
            description: description,
            sourceBranchID: UUID(), // In real app, select from repo branches
            targetBranchID: UUID()
        )
        dismiss()
    }
}
