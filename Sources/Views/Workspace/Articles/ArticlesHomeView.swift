import SwiftUI

struct ArticlesHomeView: View {
    @StateObject private var manager = ArticlesManager.shared
    @State private var showingCollections = false
    @State private var featuredArticles: [Article] = []
    @State private var isLoadingFeatured = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiInsights: ArticlesManager.AIArticleInsights?

    private let featuredTopics = ["Artificial Intelligence", "Space Exploration", "Technology", "Science"]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                Section {
                    VStack(spacing: 16) {
                        aiCard
                        featuredSection
                        if !manager.recentArticles.isEmpty { recentSection }
                        if !manager.collections.isEmpty { collectionSection }
                    }
                    .padding(16)
                } header: {
                    HStack {
                        Text("Articles")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        NavigationLink(destination: ArticleSearchView()) {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        Button { showingCollections = true } label: {
                            Label("Collections", systemImage: "folder")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .overlay(Divider(), alignment: .bottom)
                }
            }
        }
        .navigationTitle("Articles")
        .sheet(isPresented: $showingCollections) { CollectionsView() }
        .onAppear { if featuredArticles.isEmpty { loadFeaturedArticles() } }
        .refreshable { loadFeaturedArticles() }
    }

    private var aiCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("AI Reading Assistant")
                    .font(.headline)
                TextField("Paste article text or ask for a rewrite tone…", text: $aiPrompt)
                    .textFieldStyle(.roundedBorder)
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
        let text = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let insights = try await manager.generateArticleInsights(
                    articleText: text,
                    instruction: "Summarize, extract key points, rewrite clearly, and expand missing details."
                )
                await MainActor.run {
                    aiInsights = insights
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Could not process that article text. Try a shorter passage or clearer rewrite request."
                    aiLoading = false
                }
            }
        }
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
