import SwiftUI

struct FolderDetailView: View {
    let folder: NotebookFolder
    let notebookID: UUID
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreatePage = false

    private var liveFolder: NotebookFolder {
        manager.notebooks
            .first(where: { $0.id == notebookID })?
            .folders.first(where: { $0.id == folder.id }) ?? folder
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
                    ForEach(liveFolder.pages) { page in
                        NavigationLink {
                            PageEditorView(page: page, folderID: folder.id, notebookID: notebookID)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(page.title).font(.headline)
                                Text(page.content.prefix(80))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { idx in
                            manager.deletePage(liveFolder.pages[idx], from: folder.id, notebookID: notebookID)
                        }
                    }
                }
                .listStyle(.plain)
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
}
