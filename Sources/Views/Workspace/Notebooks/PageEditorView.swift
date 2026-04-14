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
    @State private var showingIntegrationPicker = false
    @FocusState private var isEditorFocused: Bool

    private let autosaveDelayNanoseconds: UInt64 = 2_000_000_000

    private var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    init(page: NotebookPage, folderID: UUID, notebookID: UUID) {
        self.page = page
        self.folderID = folderID
        self.notebookID = notebookID
        _title = State(initialValue: page.title)
        _content = State(initialValue: page.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title field
            TextField("Page title", text: $title)
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .onChange(of: title) { _ in scheduleAutosave() }

            Divider()

            // Formatting toolbar
            formattingToolbar

            Divider()

            if isPreview {
                ScrollView {
                    Text(renderPreview(content))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                TextEditor(text: $content)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .focused($isEditorFocused)
                    .onChange(of: content) { _ in scheduleAutosave() }
            }

            // Word count bar
            HStack {
                Text("\(wordCount) words · \(content.count) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(.systemGroupedBackground))

            // AI result panel
            if !aiResult.isEmpty {
                Divider()
                aiResultPanel
            }
        }
        .navigationTitle("")
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
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
        }
        .confirmationDialog("AI Writing Tools", isPresented: $showingAI, titleVisibility: .visible) {
            Button("Summarize Page") { runAI("Summarize", "Summarize the following notes concisely:\n\n\(content)") }
            Button("Rewrite & Improve") { runAI("Rewrite", "Rewrite and improve the following notes professionally:\n\n\(content)") }
            Button("Expand Notes") { runAI("Expand", "Expand and elaborate on these notes with more detail:\n\n\(content)") }
            Button("Generate Structure") { runAI("Structure", "Reorganize and structure these notes into a clear outline:\n\n\(content)") }
            Button("Fix Grammar & Spelling") { runAI("Grammar", "Fix all grammar and spelling errors in:\n\n\(content)") }
            Button("Generate Ideas") { runAI("Ideas", "Generate 5 related ideas or topics based on:\n\n\(content)") }
            if !manager.integrations.filter(\.isEnabled).isEmpty {
                Button("Custom Integration…") {
                    showingAI = false
                    showingIntegrationPicker = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Use Integration", isPresented: $showingIntegrationPicker, titleVisibility: .visible) {
            ForEach(manager.integrations.filter(\.isEnabled)) { tool in
                Button(tool.name) {
                    let prompt = tool.promptTemplate.replacingOccurrences(of: "{{content}}", with: content)
                    runAI(tool.name, prompt)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear { save() }
    }

    // MARK: - Formatting toolbar

    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                fmtButton("H1", sfIcon: nil) { insert("# ") }
                fmtButton("H2", sfIcon: nil) { insert("## ") }
                fmtButton("H3", sfIcon: nil) { insert("### ") }
                Divider().frame(height: 20)
                fmtButton(nil, sfIcon: "bold") { wrap("**") }
                fmtButton(nil, sfIcon: "italic") { wrap("_") }
                fmtButton(nil, sfIcon: "strikethrough") { wrap("~~") }
                Divider().frame(height: 20)
                fmtButton(nil, sfIcon: "list.bullet") { insert("- ") }
                fmtButton(nil, sfIcon: "list.number") { insert("1. ") }
                fmtButton(nil, sfIcon: "checkmark.square") { insert("- [ ] ") }
                Divider().frame(height: 20)
                fmtButton(nil, sfIcon: "chevron.left.slash.chevron.right") { wrap("`") }
                fmtButton("---", sfIcon: nil) { insert("\n---\n") }
                fmtButton(nil, sfIcon: "quote.bubble") { insert("> ") }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }

    private func fmtButton(_ label: String?, sfIcon: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if let icon = sfIcon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 32, height: 28)
                    .background(Color(.systemBackground))
                    .cornerRadius(6)
            } else if let text = label {
                Text(text)
                    .font(.caption.bold())
                    .frame(minWidth: 28, minHeight: 28)
                    .padding(.horizontal, 6)
                    .background(Color(.systemBackground))
                    .cornerRadius(6)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Panel

    private var aiResultPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 3)
                    .cornerRadius(2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI: \(aiTask)")
                        .font(.caption.bold())
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                }
                Spacer()
                if !aiLoading {
                    Button {
                        content += "\n\n" + aiResult
                        aiResult = ""
                        scheduleAutosave()
                    } label: {
                        Label("Insert", systemImage: "plus.circle.fill")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
                Button { aiResult = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            if aiLoading {
                HStack {
                    ProgressView()
                    Text("AI is thinking…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    Text(aiResult).font(.callout)
                }
                .frame(maxHeight: 160)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.08), Color.blue.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Helpers

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

