import SwiftUI

struct CrossIntelligenceHomeView: View {
    @State private var query = ""
    @State private var isSearching = false
    @State private var results: [String] = []
    @State private var insights: [WorkspaceInsight] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                searchHeader
                if isSearching {
                    ProgressView("Analyzing workspace...")
                        .padding()
                } else if !results.isEmpty {
                    searchResultsSection
                } else {
                    intelligenceInsightsSection
                }
            }
            .padding()
        }
        .navigationTitle("Intelligence")
        .searchable(text: $query, prompt: "Ask anything about your workspace...")
        .onSubmit(of: .search) {
            performSearch()
        }
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cross-App Intelligence")
                .font(.title2.bold())
            Text("Semantic search across all your notes, tasks, emails, and files.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.headline)
            ForEach(results, id: \.self) { result in
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text(result)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    private var intelligenceInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Insights")
                .font(.headline)

            if insights.isEmpty {
                Text("Scanning workspace for insights...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: insight.type == .recommendation ? "lightbulb.fill" : "chart.bar.fill")
                                .foregroundColor(insight.type == .recommendation ? .yellow : .blue)
                            Text(insight.title)
                                .font(.subheadline.bold())
                        }
                        Text(insight.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
        .task {
            loadInsights()
        }
    }

    private func loadInsights() {
        Task {
            do {
                let realInsights = try await IntelligenceFramework.shared.scanWorkspace()
                await MainActor.run {
                    self.insights = realInsights
                }
            } catch {
                print("Failed to scan workspace: \(error)")
            }
        }
    }

    private func performSearch() {
        isSearching = true
        Task {
            do {
                let response = try await AIOrchestrator.shared.queryWorkspace(query)
                await MainActor.run {
                    results = [response]
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }
}
