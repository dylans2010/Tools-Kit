import SwiftUI

struct FolderDetailView: View {
    let folder: NotebookFolder
    let notebookID: UUID
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreatePage = false
    @State private var searchText = ""
    @State private var showingOverviewSheet = false
    @State private var overviewPage: NotebookPage?
    @State private var overviewText = ""
    @State private var overviewLoading = false
    @State private var overviewUseAI = false

    private var liveFolder: NotebookFolder {
        manager.notebooks
            .first(where: { $0.id == notebookID })?
            .folders.first(where: { $0.id == folder.id }) ?? folder
    }

    private var filteredPages: [NotebookPage] {
        if searchText.isEmpty {
            return liveFolder.pages
        } else {
            return liveFolder.pages.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        Group {
            if liveFolder.pages.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Pages",
                    message: "Create a page to start writing.",
                    action: { showingCreatePage = true },
                    actionLabel: "Create Page"
                )
            } else {
                List {
                    ForEach(filteredPages) { page in
                        NavigationLink {
                            PageEditorView(page: page, folderID: folder.id, notebookID: notebookID)
                        } label: {
                            HStack(spacing: 12) {
                                if let num = page.pageNumber {
                                    Text("\(num)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(page.title).font(.headline)
                                        if page.isMarked {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                    Text(page.content.prefix(80))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .contextMenu {
                            Button {
                                toggleMark(page)
                            } label: {
                                Label(page.isMarked ? "Unmark" : "Mark Page", systemImage: page.isMarked ? "star.slash" : "star")
                            }

                            Button {
                                assignPageNumber(page)
                            } label: {
                                Label("Assign Page Number", systemImage: "number")
                            }

                            Button {
                                overviewPage = page
                                overviewText = ""
                                overviewUseAI = false
                                showingOverviewSheet = true
                            } label: {
                                Label("Add Overview", systemImage: "text.below.photo")
                            }

                            Divider()

                            Button(role: .destructive) {
                                manager.deletePage(page, from: folder.id, notebookID: notebookID)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { idx in
                            manager.deletePage(filteredPages[idx], from: folder.id, notebookID: notebookID)
                        }
                    }
                    .onMove { from, to in
                        movePages(from: from, to: to)
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search Pages")
            }
        }
        .navigationTitle(liveFolder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreatePage = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreatePage) {
            CreatePageView(folderID: folder.id, notebookID: notebookID)
        }
        .sheet(isPresented: $showingOverviewSheet) {
            overviewSheet
        }
    }

    private var overviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let page = overviewPage {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Page", systemImage: "doc.text")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(page.title)
                                .font(.headline)
                            Text(page.content.prefix(200) + (page.content.count > 200 ? "..." : ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Overview", systemImage: "text.below.photo")
                            .font(.subheadline.weight(.semibold))

                        TextEditor(text: $overviewText)
                            .font(.body)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .topLeading) {
                                if overviewText.isEmpty {
                                    Text("Write a summary or let AI generate one...")
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 16)
                                        .padding(.leading, 12)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    Button {
                        generateAIOverview()
                    } label: {
                        HStack {
                            if overviewLoading {
                                ProgressView().controlSize(.small)
                            }
                            Label("AI Suggest Overview", systemImage: "sparkles")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(overviewLoading)

                    if overviewLoading {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("AI is scanning the page...").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Add Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingOverviewSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveOverview()
                        showingOverviewSheet = false
                    }
                    .bold()
                    .disabled(overviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func generateAIOverview() {
        guard let page = overviewPage else { return }
        overviewLoading = true
        Task {
            do {
                let prompt = """
                Analyze this page and provide a concise overview/summary:

                Title: \(page.title)
                Content: \(page.content)

                Provide a 2-3 sentence summary that captures the key points.
                """
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a helpful assistant that creates concise page summaries. Return only the summary text, no formatting."
                )
                await MainActor.run {
                    overviewText = result
                    overviewLoading = false
                }
            } catch {
                await MainActor.run {
                    overviewText = "Could not generate overview: \(error.localizedDescription)"
                    overviewLoading = false
                }
            }
        }
    }

    private func saveOverview() {
        guard let page = overviewPage else { return }
        var updated = page
        let overview = overviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !overview.isEmpty {
            let overviewBlock = "\n\n---\n**Overview:** \(overview)\n---\n"
            if updated.content.contains("**Overview:**") {
                if let range = updated.content.range(of: "---\\n\\*\\*Overview:\\*\\*.*?\\n---", options: .regularExpression) {
                    updated.content.replaceSubrange(range, with: "---\n**Overview:** \(overview)\n---")
                }
            } else {
                updated.content = overviewBlock + updated.content
            }
        }
        manager.updatePage(updated, in: folder.id, notebookID: notebookID)
    }

    private func toggleMark(_ page: NotebookPage) {
        var updated = page
        updated.isMarked.toggle()
        manager.updatePage(updated, in: folder.id, notebookID: notebookID)
    }

    private func assignPageNumber(_ page: NotebookPage) {
        var updated = page
        if let idx = liveFolder.pages.firstIndex(where: { $0.id == page.id }) {
            updated.pageNumber = idx + 1
        }
        manager.updatePage(updated, in: folder.id, notebookID: notebookID)
    }

    private func movePages(from source: IndexSet, to destination: Int) {
        var pages = liveFolder.pages
        pages.move(fromOffsets: source, toOffset: destination)
        var updatedFolder = liveFolder
        updatedFolder.pages = pages
        if let nb = manager.notebooks.first(where: { $0.id == notebookID }) {
            manager.updateFolder(updatedFolder, in: nb)
        }
    }
}
