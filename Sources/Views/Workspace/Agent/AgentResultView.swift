import SwiftUI

struct AgentResultView: View {
    let pullRequest: AgentPullRequest
    @State private var prDetails: GitHubPullRequest?
    @State private var isLoading = false
    @State private var showingPRDetail = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Result Ready")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(pullRequest.title ?? "Pull Request Created")
                    .font(.subheadline.bold())
                if let desc = pullRequest.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

            Button(action: openPR) {
                HStack {
                    Image(systemName: "tray.full.fill")
                    Text("Open in PR View")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Text("Note: You can also find this PR in the Pull Requests section of this repository.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .sheet(isPresented: $showingPRDetail) {
            if let pr = prDetails {
                let components = pullRequest.url.components(separatedBy: "/")
                NavigationView {
                    PRDetailView(owner: components[3], repo: components[4], pullRequest: pr)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") { showingPRDetail = false }
                            }
                        }
                }
            }
        }
        .overlay {
            if isLoading { ProgressView() }
        }
    }

    private func openPR() {
        let components = pullRequest.url.components(separatedBy: "/")
        guard components.count >= 7,
              let number = Int(components[6]),
              let owner = components.indices.contains(3) ? components[3] : nil,
              let repo = components.indices.contains(4) ? components[4] : nil else { return }

        isLoading = true
        Task {
            do {
                let pr: GitHubPullRequest = try await GitHubAPIClient.shared.request(.prDetails(owner: owner, repo: repo, number: number))
                await MainActor.run {
                    self.prDetails = pr
                    self.isLoading = false
                    self.showingPRDetail = true
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}
