import SwiftUI

struct ArticlesHomeView: View {
    @StateObject private var manager = ArticlesManager.shared
    @State private var showingCollections = false
    @State private var showingAISheet = false
    @State private var featuredArticles: [Article] = []
    @State private var isLoadingFeatured = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: ArticlesManager.AIArticleInsights?

    private let featuredTopics = ["Artificial Intelligence", "Space Exploration", "Technology", "Science"]

    var body: some View {
        List {
            Section("Overview") {
                HStack(spacing: 12) {
                    StatLabel(label: "Featured", value: "\(featuredArticles.count)")
                    StatLabel(label: "Recent", value: "\(manager.recentArticles.count)")
                    StatLabel(label: "Collections", value: "\(manager.collections.count)")
                }
            }

            Section("Featured") {
                if isLoadingFeatured {
                    ProgressView("Loading featured articles…")
                } else if featuredArticles.isEmpty {
                    Text("No featured articles. Pull to refresh.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(featuredArticles.prefix(8)) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            ArticleRowLabel(article: article)
                        }
                    }
                }
            }

            if !manager.recentArticles.isEmpty {
                Section("Continue Reading") {
                    ForEach(manager.recentArticles.prefix(8)) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            ArticleRowLabel(article: article)
                        }
                    }
                }
            }

            if !manager.collections.isEmpty {
                Section("Collections") {
                    ForEach(manager.collections) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                        } label: {
                            Label {
                                HStack {
                                    Text(collection.name)
                                    Spacer()
                                    Text("\(collection.articles.count)")
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: collection.icon)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Articles")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                NavigationLink(destination: ArticleSearchView()) {
                    Image(systemName: "magnifyingglass")
                }

                Menu {
                    Button { showingCollections = true } label: {
                        Label("Collections", systemImage: "folder")
                    }
                    Button { showingAISheet = true } label: {
                        Label("AI Assistant", systemImage: "sparkles")
                    }
                    Divider()
                    Button { runAI(using: "Give me a concise executive brief from this article.") } label: {
                        Label("Executive Brief", systemImage: "doc.text.magnifyingglass")
                    }
                    Button { runAI(using: "Explain both sides and key assumptions.") } label: {
                        Label("Debate Lens", systemImage: "bubble.left.and.bubble.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCollections) { CollectionsView() }
        .sheet(isPresented: $showingAISheet) { aiAssistantSheet }
        .onAppear { if featuredArticles.isEmpty { loadFeaturedArticles() } }
        .refreshable { loadFeaturedArticles() }
    }

    // MARK: - AI Sheet

    private var aiAssistantSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ask naturally or paste article text…", text: $aiPrompt, axis: .vertical)
                } header: {
                    Text("AI Article Tools")
                } footer: {
                    Text("Use natural language—short requests like \"give me key takeaways\" or \"rewrite for beginners\" work.")
                }

                Section("Quick Actions") {
                    HStack(spacing: 8) {
                        Button("Brief") { runAI(using: "Give me an executive brief from this article.") }
                            .buttonStyle(.bordered)
                        Button("Debate") { runAI(using: "Explain both sides and main assumptions.") }
                            .buttonStyle(.bordered)
                        Button("Study") { runAI(using: "Turn this into study notes and action steps.") }
                            .buttonStyle(.bordered)
                    }
                }

                Section {
                    Button("Analyze", action: runAI)
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                    if aiLoading {
                        ProgressView("Analyzing…")
                    } else if let aiError {
                        Label(aiError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    } else if let aiInsights {
                        Text(aiInsights.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ForEach(aiInsights.keyPoints, id: \.self) { point in
                            Label(point, systemImage: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAISheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Logic

    private func loadFeaturedArticles() {
        isLoadingFeatured = true
        Task {
            var results: [Article] = []
            for topic in featuredTopics {
                if let fetched = try? await manager.search(query: topic) {
                    results.append(contentsOf: fetched.prefix(2))
                }
            }
            await MainActor.run {
                featuredArticles = results
                isLoadingFeatured = false
            }
        }
    }

    private func runAI() {
        runAI(using: aiPrompt)
    }

    private func runAI(using input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let insights = try await manager.generateArticleInsights(
                    articleText: text,
                    instruction: "Understand intent from natural language, summarize clearly, extract key points, rewrite in requested tone if implied, and expand missing context."
                )
                await MainActor.run {
                    aiInsights = insights
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "We couldn't process that yet. You can type naturally and keep it short; we'll infer details."
                    aiLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct ArticleRowLabel: View {
    let article: Article
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(.headline)
                .lineLimit(2)
            Text(article.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

private struct StatLabel: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
