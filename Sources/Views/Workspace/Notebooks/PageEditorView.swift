import SwiftUI

struct PageEditorView: View {
    let page: NotebookPage
    let folderID: UUID
    let notebookID: UUID
    @StateObject private var manager = NotebooksManager.shared

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
        VStack(spacing: 0) {
            // Formatting toolbar
            formattingToolbar

            Divider()

            if isPreview {
                ScrollView {
                    // Simple markdown-like preview
                    Text(renderPreview(content))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                TextEditor(text: $content)
                    .font(.body)
                    .padding()
                    .onChange(of: content) { _ in scheduleAutosave() }
            }

            // AI result overlay
            if !aiResult.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI: \(aiTask)")
                            .font(.caption.bold())
                            .foregroundColor(.purple)
                        Spacer()
                        Button { aiResult = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                    if aiLoading {
                        ProgressView()
                    } else {
                        ScrollView {
                            Text(aiResult).font(.callout)
                        }
                        .frame(maxHeight: 180)
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.07))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    isPreview.toggle()
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

    // MARK: - Formatting toolbar

    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                fmtButton("H1") { insert("# ") }
                fmtButton("H2") { insert("## ") }
                fmtButton("B", bold: true) { wrap("**") }
                fmtButton("I", italic: true) { wrap("_") }
                fmtButton("• List") { insert("- ") }
                fmtButton("1. List") { insert("1. ") }
                fmtButton("Code") { wrap("`") }
                fmtButton("---") { insert("\n---\n") }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(.systemGray6))
    }

    private func fmtButton(_ label: String, bold: Bool = false, italic: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(bold ? .caption.bold() : italic ? .caption.italic() : .caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemBackground))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func insert(_ markdown: String) {
        content += markdown
    }

    private func wrap(_ marker: String) {
        content += "\(marker)text\(marker)"
    }

    // MARK: - Preview

    private func renderPreview(_ md: String) -> AttributedString {
        (try? AttributedString(markdown: md)) ?? AttributedString(md)
    }

    // MARK: - AI

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
        // Handled via separate sheet if needed; for now use first enabled integration
        if let tool = manager.integrations.first(where: { $0.isEnabled }) {
            let prompt = tool.promptTemplate.replacingOccurrences(of: "{{content}}", with: content)
            runAI(tool.name, prompt)
        }
    }

    // MARK: - Autosave

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
