import SwiftUI

struct PageEditorView: View {
    let page: NotebookPage
    let folderID: UUID
    let notebookID: UUID
    @StateObject private var manager = NotebooksManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var content: String
    @State private var isPreview = false
    @State private var showingAI = false
    @State private var aiResult = ""
    @State private var aiLoading = false
    @State private var aiTask = ""
    @State private var autosaveTask: Task<Void, Never>? = nil

    private let autosaveDelayNanoseconds: UInt64 = 2_000_000_000

    init(page: NotebookPage, folderID: UUID, notebookID: UUID) {
        self.page = page
        self.folderID = folderID
        self.notebookID = notebookID
        _title = State(initialValue: page.title)
        _content = State(initialValue: page.content)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // Modern Title Field
                TextField("Untitled", text: $title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .onChange(of: title) { _ in scheduleAutosave() }

                if isPreview {
                    ScrollView {
                        Text(renderPreview(content))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .transition(.opacity)
                } else {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Start typing your notes...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                        }

                        TextEditor(text: $content)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 16)
                            .onChange(of: content) { _ in scheduleAutosave() }
                    }
                    .transition(.opacity)
                }
            }

            // Footer Pill Badge
            VStack(spacing: 12) {
                if !aiResult.isEmpty {
                    aiOverlay
                }

                HStack {
                    HStack(spacing: 8) {
                        Text("\(content.split { $0.isWhitespace }.count) words")
                        Text("•")
                        Text("Edited \(page.updatedAt, style: .time)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(.systemGray6)))
                }
                .padding(.bottom, isPreview ? 20 : 80)
            }

            // Floating Formatting Toolbar
            if !isPreview {
                formattingToolbar
                    .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isPreview.toggle()
                    }
                } label: {
                    Image(systemName: isPreview ? "pencil" : "eye")
                }
                Button { showingAI = true } label: {
                    Image(systemName: "sparkles")
                }
            }
        }
        .confirmationDialog("AI Tools", isPresented: $showingAI, titleVisibility: .visible) {
            Button("Summarize Page") { runAI("Summarize", "Summarize the following notes concisely:\n\n\(content)") }
            Button("Rewrite Content") { runAI("Rewrite", "Rewrite and improve the following notes professionally:\n\n\(content)") }
            Button("Expand Notes") { runAI("Expand", "Expand and elaborate on these notes:\n\n\(content)") }
            Button("Generate Structure") { runAI("Structure", "Reorganize and structure these notes into a clear outline:\n\n\(content)") }
            if !manager.integrations.filter(\.isEnabled).isEmpty {
                Button("Use Integration…") { showingAI = false; showIntegrationPicker() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear { save() }
    }

    private var aiOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                Text("AI \(aiTask)")
                    .font(.headline)
                Spacer()
                Button { aiResult = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.7))
                }
            }

            if aiLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    Text(aiResult)
                        .font(.callout)
                        .lineSpacing(4)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .foregroundColor(.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }

    private var formattingToolbar: some View {
        HStack(spacing: 15) {
            toolbarIcon("bold", action: { wrap("**") })
            toolbarIcon("italic", action: { wrap("_") })
            toolbarIcon("h1", action: { insert("# ") })
            toolbarIcon("h2", action: { insert("## ") })
            toolbarIcon("list.bullet", action: { insert("- ") })
            toolbarIcon("link", action: { insert("[text](url)") })
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private func toolbarIcon(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    private func insert(_ markdown: String) {
        content += markdown
    }

    private func wrap(_ marker: String) {
        content += "\(marker)text\(marker)"
    }

    private func renderPreview(_ md: String) -> AttributedString {
        (try? AttributedString(markdown: md)) ?? AttributedString(md)
    }

    private func runAI(_ task: String, _ prompt: String) {
        aiTask = task
        aiLoading = true
        aiResult = "Loading…"
        Task {
            do {
                let result = try await AIService.shared.processText(prompt: prompt)
                await MainActor.run { aiResult = result; aiLoading = false }
            } catch {
                await MainActor.run { aiResult = "Error: \(error.localizedDescription)"; aiLoading = false }
            }
        }
    }

    private func showIntegrationPicker() {
        if let tool = manager.integrations.first(where: { $0.isEnabled }) {
            let prompt = tool.promptTemplate.replacingOccurrences(of: "{{content}}", with: content)
            runAI(tool.name, prompt)
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: autosaveDelayNanoseconds)
            if !Task.isCancelled { save() }
        }
    }

    private func save() {
        var updated = page
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Page" : title
        updated.content = content
        updated.updatedAt = Date()
        manager.updatePage(updated, in: folderID, notebookID: notebookID)
    }
}
