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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL = displayArticle.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(.systemGray5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(displayArticle.title)
                        .font(.title2.bold())

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading article…")
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    } else if let err = errorMessage {
                        Text(err).foregroundColor(.red)
                    } else {
                        Text(displayArticle.content.isEmpty ? displayArticle.summary : displayArticle.content)
                            .font(.body)
                            .lineSpacing(5)
                    }

                    // AI result
                    if !aiResult.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                            Text("AI: \(aiTask)")
                                .font(.caption.bold())
                                .foregroundColor(.purple)
                            if aiLoading {
                                ProgressView()
                            } else {
                                Text(aiResult)
                                    .font(.callout)
                                    .padding()
                                    .background(Color.purple.opacity(0.08))
                                    .cornerRadius(10)
                            }
                        }
                    }

                    // Source link
                    if let url = URL(string: displayArticle.sourceURL) {
                        Link("View on Wikipedia", destination: url)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingAI = true
                } label: {
                    Image(systemName: "sparkles")
                }

                Button {
                    showingCollectionPicker = true
                } label: {
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

    private var collectionPickerSheet: some View {
        NavigationStack {
            List {
                if manager.collections.isEmpty {
                    Text("No collections yet. Create one first.")
                        .foregroundColor(.secondary)
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
            .navigationTitle("Save to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                let full = try await manager.fetchArticle(title: article.title, language: article.language)
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
