import SwiftUI

struct GlobalSearchView: View {
    @State private var query = ""
    @State private var results: [WorkspaceEntity] = []

    var body: some View {
        VStack {
            SearchBar(text: $query, placeholder: "Search across all apps...")
                .onChange(of: query) { newValue in
                    performSearch()
                }

            List(results) { entity in
                VStack(alignment: .leading) {
                    Text(entity.title).font(.headline)
                    Text(entity.type.rawValue).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Global Search")
    }

    private func performSearch() {
        Task {
            results = await SemanticSearchService.shared.search(query: query)
        }
    }
}
