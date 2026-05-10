import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var manager = ArticlesManager.shared
    @State private var fullArticle: Article? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingCollectionPicker = false
    @State private var showingAI = false
    @State private var aiResult: String = ""
    @State private var aiLoading = false
    @State private var aiTask: String = ""

    private var displayArticle: Article { fullArticle ?? article }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayArticle.title)
                        .font(.title2.bold())
                    Text(displayArticle.summary.isEmpty ? "Full article view" : displayArticle.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    HStack(spacing: 8) {
                        Label(displayArticle.language.uppercased(), systemImage: "globe")
                            .font(.caption)
                        if displayArticle.pageID != nil {
                            Label("Wikipedia", systemImage: "book.closed")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if isLoading {
                Section {
                    ProgressView("Loading article…")
                }
            } else if let err = errorMessage {
                Section {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                } header: {
                    Text("Error")
                }
            } else {
                Section {
                    renderedArticleText(displayArticle.content.isEmpty ? displayArticle.summary : displayArticle.content)
                        .textSelection(.enabled)
                } header: {
                    Text("Article")
                }
            }

            if !aiResult.isEmpty {
                Section {
                    if aiLoading {
                        ProgressView()
                    } else {
                        renderedArticleText(aiResult)
                            .textSelection(.enabled)
                    }
                } header: {
                    Text(aiTask)
                }
            }

            if let url = URL(string: displayArticle.sourceURL) {
                Section {
                    Link(destination: url) {
                        Label("Open Source", systemImage: "safari")
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingAI = true } label: {
                    Image(systemName: "sparkles")
                }
                Button { showingCollectionPicker = true } label: {
                    Image(systemName: "bookmark")
                }
            }
        }
        .sheet(isPresented: $showingCollectionPicker) {
            collectionPickerSheet
        }
        .confirmationDialog("AI Tools", isPresented: $showingAI, titleVisibility: .visible) {
            Button("Summarize") { runAI("Summarize", prompt: "Summarize this article concisely:\n\n\(displayArticle.content.prefix(4000))") }
            Button("Explain Simply") { runAI("Explain Simply", prompt: "Explain this article in simple terms for a beginner:\n\n\(displayArticle.content.prefix(4000))") }
            Button("Extract Key Points") { runAI("Extract Key Points", prompt: "Extract the key points from this article as a bullet list:\n\n\(displayArticle.content.prefix(4000))") }
            Button("Generate Related Topics") { runAI("Related Topics", prompt: "List 8 related Wikipedia topics based on this article: \(displayArticle.title)") }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { loadFullArticle() }
    }

    @ViewBuilder
    private func renderedArticleText(_ text: String) -> some View {
        if let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
                .lineSpacing(6)
        } else {
            Text(text)
                .lineSpacing(6)
        }
    }

    private var collectionPickerSheet: some View {
        NavigationStack {
            List {
                if manager.collections.isEmpty {
                    ContentUnavailableView {
                        Label("No Collections", systemImage: "folder")
                    } description: {
                        Text("Create a collection first to save articles.")
                    }
                } else {
                    ForEach(manager.collections) { col in
                        Button {
                            manager.saveArticle(displayArticle, to: col.id)
                            showingCollectionPicker = false
                        } label: {
                            Label(col.name, systemImage: col.icon)
                        }
                    }
                }
            }
            .navigationTitle("Save To Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCollectionPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadFullArticle() {
        guard displayArticle.content.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let full = try await manager.fetchArticle(title: article.title, language: article.language, pageID: article.pageID)
                await MainActor.run {
                    fullArticle = full
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func runAI(_ task: String, prompt: String) {
        aiTask = task
        aiLoading = true
        aiResult = "Loading…"
        Task {
            do {
                let result = try await AIService.shared.processText(prompt: prompt)
                await MainActor.run {
                    aiResult = result
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiResult = "Error: \(error.localizedDescription)"
                    aiLoading = false
                }
            }
        }
    }
}
