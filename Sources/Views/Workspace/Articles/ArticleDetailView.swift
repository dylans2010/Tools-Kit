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
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                if isLoading {
                    articleCard(title: "Loading", icon: "clock") {
                        HStack {
                            Spacer()
                            ProgressView("Loading article…")
                            Spacer()
                        }
                        .padding(.vertical, 24)
                    }
                } else if let err = errorMessage {
                    articleCard(title: "Error", icon: "exclamationmark.triangle.fill", accent: .red) {
                        Text(err)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    articleCard(title: "Article", icon: "doc.richtext") {
                        renderedArticleText(displayArticle.content.isEmpty ? displayArticle.summary : displayArticle.content)
                    }
                }

                if !aiResult.isEmpty {
                    articleCard(title: aiTask, icon: "sparkles", accent: .purple) {
                        if aiLoading {
                            ProgressView()
                        } else {
                            renderedArticleText(aiResult)
                        }
                    }
                }

                if let url = URL(string: displayArticle.sourceURL) {
                    Link(destination: url) {
                        HStack {
                            Label("Open Source", systemImage: "safari")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.14), Color(red: 0.10, green: 0.13, blue: 0.22), Color(red: 0.15, green: 0.08, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        )
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

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURL = displayArticle.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(displayArticle.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(displayArticle.summary.isEmpty ? "Full article view" : displayArticle.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    infoPill(icon: "globe", text: displayArticle.language.uppercased())
                    if displayArticle.pageID != nil {
                        infoPill(icon: "number", text: "Page ID")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private func articleCard<Content: View>(title: String, icon: String, accent: Color = .blue, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)

            content()
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(accent.opacity(0.18), lineWidth: 1))
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

    private func infoPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.10), in: Capsule())
            .foregroundStyle(.white)
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
            .navigationTitle("Save To Collection")
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
