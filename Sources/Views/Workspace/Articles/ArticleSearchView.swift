import SwiftUI
import Combine

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
        ("ja", "Japanese"), ("zh", "Chinese"), ("ar", "Arabic"),
        ("ru", "Russian"), ("ko", "Korean"), ("nl", "Dutch"),
        ("pl", "Polish"), ("sv", "Swedish"), ("tr", "Turkish")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Language scroll picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(languages, id: \.0) { code, name in
                        Button {
                            selectedLanguage = code
                        } label: {
                            Text(name)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedLanguage == code ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundColor(selectedLanguage == code ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Searching…")
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else if let error = errorMessage {
                    Text(error).foregroundColor(.red).listRowSeparator(.hidden)
                } else if results.isEmpty && !searchText.isEmpty {
                    Text("No results found.").foregroundColor(.secondary).listRowSeparator(.hidden)
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
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.plain)
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
        .onChange(of: searchText) { newValue in
            debounceSearch(newValue)
        }
        .onChange(of: selectedLanguage) { _ in
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
