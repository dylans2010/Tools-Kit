import SwiftUI

struct ArticleSearchView: View {
    var initialQuery: String = ""
    @State private var searchText: String = ""
    @State private var selectedLanguage: String = "en"
    @State private var results: [Article] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @StateObject private var manager = ArticlesManager.shared

    private let languages = [
        ("en", "English"), ("es", "Spanish"), ("fr", "French"),
        ("de", "German"), ("it", "Italian"), ("pt", "Portuguese"),
        ("ja", "Japanese"), ("zh", "Chinese")
    ]

    var body: some View {
        List {
            Section {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
            }

            Section {
                if isLoading {
                    ProgressView("Searching…")
                } else if let error = errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                } else if results.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(results) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                                .onAppear { manager.addRecent(article) }
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
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Wikipedia…")
        .navigationTitle("Search Articles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !initialQuery.isEmpty {
                searchText = initialQuery
                performSearch(initialQuery)
            }
        }
        .onChange(of: searchText) { _, newValue in
            debounceSearch(newValue)
        }
        .onChange(of: selectedLanguage) { _, _ in
            if !searchText.isEmpty { performSearch(searchText) }
        }
    }

    @State private var searchTask: Task<Void, Never>? = nil

    private let debounceDelayNanoseconds: UInt64 = 500_000_000

    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: debounceDelayNanoseconds)
            if !Task.isCancelled {
                performSearch(query)
            }
        }
    }

    private func performSearch(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { results = []; return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let found = try await manager.search(query: q, language: selectedLanguage)
                await MainActor.run {
                    results = found
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
