import SwiftUI

struct CommitIntelligenceView: View {
    let commit: CollaborationCommit
    @State private var summary: String = "Generating summary..."
    @State private var impact: String = "Analyzing impact..."
    @State private var isAnalyzing = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Commit Intelligence")
                    .font(.headline)
                Spacer()
                if isAnalyzing {
                    ProgressView()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                InfoBlock(title: "Summary", content: summary)
                InfoBlock(title: "Semantic Impact", content: impact)
            }
            .opacity(isAnalyzing ? 0.5 : 1.0)
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(12)
        .task {
            await analyzeCommit()
        }
    }

    private func analyzeCommit() async {
        isAnalyzing = true
        do {
            summary = try await CommitIntelligenceService.shared.generateCommitSummary(data: commit.dataSnapshot)
            impact = try await CommitIntelligenceService.shared.explainSemanticDiff(old: Data(), new: commit.dataSnapshot)
        } catch {
            summary = "Failed to generate summary."
        }
        isAnalyzing = false
    }
}

struct InfoBlock: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Text(content)
                .font(.subheadline)
        }
    }
}
