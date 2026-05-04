import SwiftUI

/// View for displaying decisions made across multiple related threads.
struct DecisionTimelineViewer: View {
    let threadID: String
    @State private var decisions: [DecisionEntry] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Decision Timeline")
                .font(.headline)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
            } else if decisions.isEmpty {
                Text("No formal decisions identified.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(decisions) { decision in
                            WorkspaceSurfaceCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(decision.timestamp, style: .date)
                                        .font(.caption2.bold())
                                        .foregroundStyle(.purple)
                                    Text(decision.title)
                                        .font(.subheadline.bold())
                                    Text(decision.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                                .frame(width: 200)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear(perform: loadDecisions)
    }

    private func loadDecisions() {
        isLoading = true
        Task {
            let allThreads = MailStorageService.shared.loadThreads(for: "all")
            if let thread = allThreads.first(where: { $0.id == threadID }) {
                decisions = (try? await DecisionIntelligenceEngine.shared.trackDecisions(for: thread)) ?? []
            }
            isLoading = false
        }
    }
}

/// Panel for converting email threads into structured data.
struct KnowledgeExtractionPanel: View {
    let thread: MailThread
    @State private var insights: [KnowledgeInsight] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Extracted Knowledge", systemImage: "books.vertical.fill")
                .font(.headline)

            if isLoading {
                ProgressView()
            } else {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.subheadline.bold())
                        Text(insight.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            ForEach(insight.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 10).bold())
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.workspaceSurface)
        .cornerRadius(12)
        .onAppear(perform: extract)
    }

    private func extract() {
        isLoading = true
        Task {
            insights = (try? await KnowledgeExtractionEngine.shared.extractKnowledge(from: thread)) ?? []
            isLoading = false
        }
    }
}
