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
        ScrollView {
            VStack(spacing: 14) {
                compactHeader
                featuredSection
                if !manager.recentArticles.isEmpty { recentSection }
                if !manager.collections.isEmpty { collectionSection }
            }
            .padding(16)
        }
        .navigationTitle("Articles")
        .sheet(isPresented: $showingCollections) { CollectionsView() }
        .sheet(isPresented: $showingAISheet) { aiAssistantSheet }
        .onAppear { if featuredArticles.isEmpty { loadFeaturedArticles() } }
        .refreshable { loadFeaturedArticles() }
    }

    private var compactHeader: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Articles")
                        .font(.title3.bold())
                    Text("Read, summarize, and rewrite with quick AI help.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                NavigationLink(destination: ArticleSearchView()) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                Button { showingCollections = true } label: {
                    Image(systemName: "folder")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                Button { showingAISheet = true } label: {
                    Image(systemName: "sparkles")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var aiAssistantSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Article Tools")
                        .font(.headline)
                    Text("Use natural language—short requests like \"give me key takeaways\" or \"rewrite for beginners\" work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Ask naturally or paste article text…", text: $aiPrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    quickActionGrid

                    Button("Analyze", action: runAI)
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                    if aiLoading {
                        WorkspaceSkeletonLine()
                        WorkspaceSkeletonLine(widthRatio: 0.8)
                    } else if let aiError {
                        Text(aiError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let aiInsights {
                        Text(aiInsights.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ForEach(aiInsights.keyPoints, id: \.self) { point in
                            Text("• \(point)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
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

    private var quickActionGrid: some View {
        HStack(spacing: 8) {
            aiQuickAction("Executive Brief", icon: "doc.text.magnifyingglass") {
                runAI(using: "Give me an executive brief from this article.")
            }
            aiQuickAction("Debate Lens", icon: "bubble.left.and.bubble.right") {
                runAI(using: "Explain both sides and main assumptions.")
            }
            aiQuickAction("Study Notes", icon: "lightbulb.max.fill") {
                runAI(using: "Turn this into study notes and action steps.")
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkspaceSectionHeader(title: "Featured")
            if isLoadingFeatured {
                WorkspaceSurfaceCard { WorkspaceSkeletonLine() }
                WorkspaceSurfaceCard { WorkspaceSkeletonLine(widthRatio: 0.7) }
            } else if featuredArticles.isEmpty {
                Text("No featured articles. Pull to refresh.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(featuredArticles.prefix(8)) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        FeaturedArticleRow(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkspaceSectionHeader(title: "Continue Reading")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(manager.recentArticles.prefix(8)) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            RecentArticleCard(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkspaceSectionHeader(title: "Collections")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(manager.collections) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                        } label: {
                            CollectionChip(collection: collection)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

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
                    aiError = "We couldn’t process that yet. You can type naturally and keep it short; we’ll infer details."
                    aiLoading = false
                }
            }
        }
    }

    private func aiQuickAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }
}

private struct FeaturedArticleRow: View {
    let article: Article
    var body: some View {
        WorkspaceSurfaceCard {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "doc.text.fill").foregroundStyle(.orange))
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(article.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
            }
        }
    }
}

private struct RecentArticleCard: View {
    let article: Article
    var body: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(article.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .frame(width: 170, alignment: .leading)
        }
        .frame(width: 190)
    }
}

private struct CollectionChip: View {
    let collection: ArticleCollection
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: collection.icon)
            Text(collection.name)
                .font(.subheadline.weight(.semibold))
            Text("\(collection.articles.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}
