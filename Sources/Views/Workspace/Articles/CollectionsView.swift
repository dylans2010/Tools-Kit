import SwiftUI

struct CollectionsView: View {
    @StateObject private var manager = ArticlesManager.shared
    @State private var showingCreate = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if manager.collections.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Collections",
                        message: "Create a collection to organize your saved articles.",
                        action: { showingCreate = true },
                        actionLabel: "Create Collection"
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(manager.collections) { collection in
                            NavigationLink {
                                CollectionDetailView(collection: collection)
                            } label: {
                                CollectionCard(collection: collection)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateCollectionView()
        }
    }
}

private struct CollectionCard: View {
    let collection: ArticleCollection
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: collection.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color(hex: collection.colorHex) ?? .blue)
                .cornerRadius(10)

            Text(collection.name)
                .font(.subheadline.bold())
                .lineLimit(1)

            Text("\(collection.articles.count) articles")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
