import SwiftUI

struct FolderDetailView: View {
    let folder: NotebookFolder
    let notebookID: UUID
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreatePage = false
    @State private var searchText = ""

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
                .searchable(text: $searchText, prompt: "Search pages...")
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
