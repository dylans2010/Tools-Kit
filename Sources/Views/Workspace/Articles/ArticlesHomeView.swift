import SwiftUI

struct ArticlesHomeView: View {
    @StateObject private var manager = ArticlesManager.shared
    @State private var trendingArticles: [Article] = []
    @State private var isFetchingTrending = false
    @State private var showingCollections = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Trending section
                if isFetchingTrending {
                    HStack { Spacer(); ProgressView("Loading trending…"); Spacer() }
                        .padding()
                } else if !trendingArticles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Trending Today", systemImage: "flame.fill")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(trendingArticles) { article in
                                    NavigationLink {
                                        ArticleDetailView(article: article)
                                            .onAppear { manager.addRecent(article) }
                                    } label: {
                                        TrendingArticleCard(article: article)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Continue Reading
                if !manager.recentArticles.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Continue Reading")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(manager.recentArticles.prefix(8)) { article in
                                    NavigationLink {
                                        ArticleDetailView(article: article)
                                    } label: {
                                        RecentArticleCard(article: article)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Suggested topics
                VStack(alignment: .leading, spacing: 10) {
                    Text("Explore Topics")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        ForEach(suggestedTopics, id: \.self) { topic in
                            NavigationLink {
                                ArticleSearchView(initialQuery: topic)
                            } label: {
                                TopicCard(title: topic)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Articles")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    NavigationLink {
                        ArticleSearchView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    Menu {
                        Button {
                            showingCollections = true
                        } label: {
                            Label("Collections", systemImage: "folder")
                        }
                        NavigationLink {
                            ArticleSearchView()
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCollections) {
            NavigationStack { CollectionsView() }
        }
        .onAppear {
            if trendingArticles.isEmpty { fetchTrending() }
        }
    }

    private let suggestedTopics = [
        "Artificial Intelligence", "Space Exploration", "Climate Change",
        "Quantum Computing", "History", "Biology", "Mathematics", "Philosophy"
    ]

    private func fetchTrending() {
        isFetchingTrending = true
        Task {
            do {
                let urlString = "https://en.wikipedia.org/w/api.php?action=query&list=mostviewed&pvimontop=true&pvimlimit=15&format=json"
                guard let url = URL(string: urlString) else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let items = (json?["query"] as? [String: Any])?["mostviewed"] as? [[String: Any]] ?? []
                let articles: [Article] = items.compactMap { item in
                    guard let title = item["title"] as? String,
                          !title.hasPrefix("Special:") && !title.hasPrefix("Wikipedia:") && !title.hasPrefix("Main Page") else { return nil }
                    let sourceURL = "https://en.wikipedia.org/wiki/\(title.replacingOccurrences(of: " ", with: "_"))"
                    return Article(title: title, summary: "", content: "", language: "en", sourceURL: sourceURL)
                }
                await MainActor.run {
                    trendingArticles = Array(articles.prefix(12))
                    isFetchingTrending = false
                }
            } catch {
                await MainActor.run { isFetchingTrending = false }
            }
        }
    }
}

// MARK: - Supporting Views

private struct TrendingArticleCard: View {
    let article: Article
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.orange.opacity(0.7), Color.red.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 200, height: 110)
                .cornerRadius(12)
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
                Text(article.title)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(10)
            }
            .frame(width: 200, height: 110)
        }
    }
}

private struct RecentArticleCard: View {
    let article: Article
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.subheadline.bold())
                .lineLimit(2)
                .frame(width: 150, alignment: .leading)
            Text(article.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(width: 150, alignment: .leading)
        }
        .padding(12)
        .frame(width: 174)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct CollectionChip: View {
    let collection: ArticleCollection
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: collection.icon)
            Text(collection.name).font(.subheadline.bold())
            Text("\(collection.articles.count)").font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

private struct TopicCard: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }
}

