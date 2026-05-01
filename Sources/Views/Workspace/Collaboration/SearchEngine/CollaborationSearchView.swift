import SwiftUI

struct CollaborationSearchView: View {
    @StateObject private var searchEngine = CollaborationSearchEngine.shared
    @State private var query = ""
    @State private var results: [CollaborationSearchEngine.SearchResult] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $query)
                    .padding()
                    .onChange(of: query) { performSearch() }

                if isSearching {
                    ProgressView()
                        .padding()
                }

                List(results) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: iconName(for: result.type))
                                .foregroundColor(.blue)
                            Text(result.title).bold()
                        }
                        Text(result.snippet)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
                .overlay {
                    if results.isEmpty && !query.isEmpty && !isSearching {
                        ContentUnavailableView.search(text: query)
                    } else if query.isEmpty {
                        ContentUnavailableView("Global Search", systemImage: "magnifyingglass", description: Text("Search across all spaces, forks, and objects."))
                    }
                }
            }
            .navigationTitle("Search")
        }
    }

    private func performSearch() {
        guard !query.isEmpty else { results = []; return }
        isSearching = true
        // Simulate search delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            results = searchEngine.search(query: query, filter: .init())

            // Mock result for demo
            if results.isEmpty && query.count > 2 {
                results = [
                    CollaborationSearchEngine.SearchResult(objectID: UUID(), type: .notebook, title: "Q3 Strategy", snippet: "...focusing on workspace expansion and collaboration features...", score: 0.95)
                ]
            }
            isSearching = false
        }
    }

    private func iconName(for type: CollaborationFramework.WorkspaceObjectType) -> String {
        switch type {
        case .notebook: return "note.text"
        case .slideDeck: return "rectangle.on.rectangle.angled"
        case .meeting: return "video.fill"
        case .form: return "doc.text.below.ecg"
        case .spreadsheet: return "tablecells"
        case .mediaProject: return "film"
        }
    }
}
