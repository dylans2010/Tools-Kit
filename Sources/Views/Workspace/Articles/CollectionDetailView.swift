import SwiftUI

struct CollectionDetailView: View {
    let collection: ArticleCollection
    @StateObject private var manager = ArticlesManager.shared

    private var liveCollection: ArticleCollection {
        manager.collections.first(where: { $0.id == collection.id }) ?? collection
    }

    var body: some View {
        Group {
            if liveCollection.articles.isEmpty {
                ContentUnavailableView {
                    Label("No Articles", systemImage: collection.icon)
                } description: {
                    Text("Save articles from the search view to add them here.")
                }
            } else {
                List {
                    ForEach(liveCollection.articles) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.title).font(.headline)
                                Text(article.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { idx in
                            manager.removeArticle(liveCollection.articles[idx], from: collection.id)
                        }
                    }
                }
            }
        }
        .navigationTitle(liveCollection.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
