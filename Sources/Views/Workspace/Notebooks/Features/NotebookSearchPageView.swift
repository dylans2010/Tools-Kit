import SwiftUI

struct NotebookSearchPageView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []

    struct SearchResult: Identifiable {
        let id = UUID()
        let page: NotebookPage
        let folderID: UUID
        let notebookID: UUID
        let matchContext: String
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(searchResults) { result in
                    NavigationLink(destination: PageEditorView(page: result.page, folderID: result.folderID, notebookID: result.notebookID)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.page.title)
                                .font(.headline)
                            Text(result.matchContext)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Search Pages")
            .searchable(text: $searchText, prompt: "Search all pages...")
            .onChange(of: searchText) { _ in
                performSearch()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if searchText.isEmpty {
                    ContentUnavailableView("Search Workspace", systemImage: "magnifyingglass", description: Text("Enter a title or content to search across all notebooks."))
                } else if searchResults.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        var results: [SearchResult] = []
        for notebook in manager.notebooks {
            for folder in notebook.folders {
                for page in folder.pages {
                    if page.title.localizedCaseInsensitiveContains(searchText) ||
                        page.content.localizedCaseInsensitiveContains(searchText) {

                        let context = extractContext(from: page.content, for: searchText)
                        results.append(SearchResult(page: page, folderID: folder.id, notebookID: notebook.id, matchContext: context))
                    }
                }
            }
        }
        searchResults = results
    }

    private func extractContext(from content: String, for query: String) -> String {
        guard let range = content.range(of: query, options: .caseInsensitive) else {
            return content.prefix(100).description
        }

        let start = content.index(range.lowerBound, offsetBy: -30, limitedBy: content.startIndex) ?? content.startIndex
        let end = content.index(range.upperBound, offsetBy: 70, limitedBy: content.endIndex) ?? content.endIndex

        return "..." + content[start..<end].replacingOccurrences(of: "\n", with: " ") + "..."
    }
}
