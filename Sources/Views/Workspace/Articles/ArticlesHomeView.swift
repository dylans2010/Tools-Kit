import SwiftUI

struct ArticlesHomeView: View {
    @StateObject private var manager = ArticlesManager.shared
    @State private var showingSearch = false
    @State private var showingCollections = false
    @State private var featuredArticles: [Article] = []
    @State private var isLoadingFeatured = false

    private let featuredTopics = ["Artificial Intelligence", "Space Exploration", "Technology", "Science"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Featured Articles section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Featured Articles")
                            .font(.headline)
                        Spacer()
                        if isLoadingFeatured {
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal)

                    if featuredArticles.isEmpty && !isLoadingFeatured {
                        Text("Pull to refresh or search for articles")
                            .foregroundColor(.secondary)
                            .font(.callout)
                            .padding(.horizontal)
                    } else {
                        ForEach(featuredArticles.prefix(8)) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                            } label: {
                                FeaturedArticleRow(article: article)
                            }
                            .buttonStyle(.plain)
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

                // Collections
                if !manager.collections.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Collections")
                                .font(.headline)
                            Spacer()
                            NavigationLink("See All") {
                                CollectionsView()
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(manager.collections) { collection in
                                    NavigationLink {
                                        CollectionDetailView(collection: collection)
                                    } label: {
                                        CollectionChip(collection: collection)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Browse Topics
                VStack(alignment: .leading, spacing: 10) {
                    Text("Browse Topics")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        ForEach(featuredTopics, id: \.self) { topic in
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
                HStack {
                    NavigationLink(destination: ArticleSearchView()) {
                        Image(systemName: "magnifyingglass")
                    }
                    Menu {
                        Button { showingCollections = true } label: {
                            Label("Collections", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCollections) {
            CollectionsView()
        }
        .onAppear {
            if featuredArticles.isEmpty {
                loadFeaturedArticles()
            }
        }
        .refreshable {
            loadFeaturedArticles()
        }
    }

    private func loadFeaturedArticles() {
        isLoadingFeatured = true
        Task {
            var results: [Article] = []
            for topic in featuredTopics {
                if let articles = try? await manager.search(query: topic) {
                    results.append(contentsOf: articles.prefix(2))
                }
            }
            await MainActor.run {
                featuredArticles = results
                isLoadingFeatured = false
            }
        }
    }
}

// MARK: - Supporting Views

private struct FeaturedArticleRow: View {
    let article: Article
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.orange)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text(article.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

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
