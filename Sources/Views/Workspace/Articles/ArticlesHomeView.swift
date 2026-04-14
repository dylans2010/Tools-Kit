import SwiftUI

struct ArticlesHomeView: View {
    @StateObject private var manager = ArticlesManager.shared
    @State private var showingSearch = false
    @State private var showingCollections = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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

                // Suggested topics
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Topics")
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
                HStack {
                    NavigationLink(destination: ArticleSearchView()) {
                        Image(systemName: "magnifyingglass")
                    }

                    Menu {
                        Button { showingCollections = true } label: {
                            Label("Collections", systemImage: "folder")
                        }

                        Divider()

                        ForEach(suggestedTopics, id: \.self) { topic in
                            NavigationLink(destination: ArticleSearchView(initialQuery: topic)) {
                                Label(topic, systemImage: "tag")
                            }
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
            if manager.recentArticles.isEmpty {
                Task {
                    _ = try? await manager.search(query: "Trending")
                }
            }
        }
    }

    private let suggestedTopics = [
        "Artificial Intelligence", "Space Exploration", "Climate Change",
        "Quantum Computing", "History", "Biology", "Mathematics", "Philosophy"
    ]

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
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
