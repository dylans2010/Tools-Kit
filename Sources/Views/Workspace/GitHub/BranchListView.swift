import SwiftUI

/// Displays a list of branches for a repository.
struct BranchListView: View {
    let owner: String
    let repo: String

    @State private var branches: [GitHubBranch] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if branches.isEmpty && !isLoading {
                Text("No branches found.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(branches, id: \.name) { branch in
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.blue)
                        Text(branch.name)
                        Spacer()
                        if branch.protected {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Branches")
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            fetchBranches()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func fetchBranches() {
        isLoading = true
        Task {
            do {
                self.branches = try await GitHubAPIClient.shared.request(.branches(owner: owner, repo: repo))
                isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
