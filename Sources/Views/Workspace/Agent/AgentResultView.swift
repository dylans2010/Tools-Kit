import SwiftUI

struct AgentResultView: View {
    let pullRequest: AgentPullRequest
    @Environment(\.openURL) private var openURL

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
                    Image(systemName: "safari")
                    Text("Open PR")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(URL(string: pullRequest.url) == nil)

            Text("Note: You can also find this PR in the Pull Requests section of this repository.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }

    private func openPR() {
        guard let url = URL(string: pullRequest.url) else { return }
        openURL(url)
    }
}
