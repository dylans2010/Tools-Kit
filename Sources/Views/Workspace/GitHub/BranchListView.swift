import SwiftUI

/// Displays a list of branches for a repository.
struct BranchListView: View {
    let owner: String
    let repo: String
    var selectedBranch: String?
    var onSelect: ((String) -> Void)?

    @State private var branches: [GitHubBranch] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateBranch = false
    @State private var newBranchName = ""
    @State private var baseBranch = "main"

    var body: some View {
        List {
            if branches.isEmpty && !isLoading {
                Text("No branches found.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(branches, id: \.name) { branch in
                    Button {
                        onSelect?(branch.name)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundStyle(branch.name == selectedBranch ? .primary : .secondary)
                            Text(branch.name)
                                .fontWeight(branch.name == selectedBranch ? .bold : .regular)
                            Spacer()
                            if branch.protected {
                                Image(systemName: "shield.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            if branch.name == selectedBranch {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        if !branch.protected {
                            Button(role: .destructive) {
                                deleteBranch(branch.name)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Branches")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateBranch = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateBranch) {
            NavigationStack {
                Form {
                    Section {
                        TextField("New Branch Name", text: $newBranchName)
                        Picker("Base Branch", selection: $baseBranch) {
                            ForEach(branches, id: \.name) { branch in
                                Text(branch.name).tag(branch.name)
                            }
                        }
                    } header: {
                        Text("Branch Info")
                    }
                }
                .navigationTitle("New Branch")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingCreateBranch = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            createBranch()
                        }
                        .disabled(newBranchName.isEmpty)
                    }
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            if let selected = selectedBranch {
                baseBranch = selected
            } else if let first = branches.first?.name {
                baseBranch = first
            }
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
                let fetched: [GitHubBranch] = try await GitHubAPIClient.shared.request(.branches(owner: owner, repo: repo))
                await MainActor.run {
                    self.branches = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func deleteBranch(_ name: String) {
        Task {
            do {
                try await GitHubAPIClient.shared.requestEmpty(.deleteRef(owner: owner, repo: repo, ref: "heads/\(name)"))
                fetchBranches()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func createBranch() {
        guard let baseSha = branches.first(where: { $0.name == baseBranch })?.commit.sha else { return }

        struct CreateRefPayload: Encodable, Sendable {
            let ref: String
            let sha: String
        }

        let payload = CreateRefPayload(ref: "refs/heads/\(newBranchName)", sha: baseSha)

        Task {
            do {
                try await GitHubAPIClient.shared.requestEmpty(.createRef(owner: owner, repo: repo), body: payload)
                await MainActor.run {
                    showingCreateBranch = false
                    newBranchName = ""
                    fetchBranches()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
