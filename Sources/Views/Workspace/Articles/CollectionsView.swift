import SwiftUI

struct CollectionsView: View {
    @StateObject private var manager = ArticlesManager.shared
    @State private var showingCreate = false

    var body: some View {
        List {
            if manager.collections.isEmpty {
                ContentUnavailableView {
                    Label("No Collections", systemImage: "folder")
                } description: {
                    Text("Create a collection to organize your saved articles.")
                } actions: {
                    Button("Create Collection") { showingCreate = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(manager.collections) { collection in
                    NavigationLink {
                        CollectionDetailView(collection: collection)
                    } label: {
                        Label {
                            HStack {
                                Text(collection.name)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("\(collection.articles.count) Articles")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: collection.icon)
                        }
                    }
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
