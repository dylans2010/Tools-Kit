import SwiftUI

/// Displays details of a specific pull request and allows merging.
struct PRDetailView: View {
    let owner: String
    let repo: String
    let pullRequest: GitHubPullRequest

    @State private var comparison: GitHubComparison?
    @State private var isMerging = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(pullRequest.title)
                        .font(.title2.bold())

                    HStack {
                        Capsule()
                            .fill(pullRequest.state == "open" ? Color.accentColor : .secondary)
                            .overlay(Text(pullRequest.state.capitalized).font(.caption.bold()).foregroundStyle(.white))
                            .frame(width: 60, height: 24)

                        Text("\(pullRequest.user.login) wants to merge \(pullRequest.head.ref) into \(pullRequest.base.ref)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                if let body = pullRequest.body, !body.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description").font(.headline)
                        Text(body).font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let comparison = comparison {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Changes").font(.headline)
                        HStack {
                            StatBox(label: "Commits", value: "\(comparison.commits.count)", color: .blue)
                            StatBox(label: "Files", value: "\(comparison.files.count)", color: .orange)
                            StatBox(label: "Additions", value: "+\(comparison.files.reduce(0) { $0 + $1.additions })", color: .green)
                        }
                    }
                }

                if pullRequest.state == "open" {
                    VStack(spacing: 12) {
                        Button {
                            mergePullRequest()
                        } label: {
                            if isMerging {
                                ProgressView().tint(.white)
                            } else {
                                Text("Merge Pull Request")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .disabled(isMerging)

                        Button {
                            closePullRequest()
                        } label: {
                            Text("Close Pull Request")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemRed))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .disabled(isMerging)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("PR #\(pullRequest.number)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchComparison()
        }
    }

    private func fetchComparison() {
        Task {
            do {
                self.comparison = try await GitHubAPIClient.shared.request(.compare(owner: owner, repo: repo, base: pullRequest.base.ref, head: pullRequest.head.sha))
            } catch {}
        }
    }

    private func mergePullRequest() {
        isMerging = true
        Task {
            do {
                try await GitHubAPIClient.shared.requestEmpty(.mergePR(owner: owner, repo: repo, number: pullRequest.number))
                isMerging = false
                dismiss()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    isMerging = false
                }
            }
        }
    }

    private func closePullRequest() {
        isMerging = true
        struct UpdatePRPayload: Encodable {
            let state: String
        }
        let payload = UpdatePRPayload(state: "closed")

        Task {
            do {
                try await GitHubAPIClient.shared.requestEmpty(.updatePR(owner: owner, repo: repo, number: pullRequest.number), body: payload)
                isMerging = false
                dismiss()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    isMerging = false
                }
            }
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(value).font(.headline).foregroundColor(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
