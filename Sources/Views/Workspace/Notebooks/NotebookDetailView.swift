import SwiftUI

struct NotebookDetailView: View {
    let notebook: Notebook
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreateFolder = false

    private var liveNotebook: Notebook {
        manager.notebooks.first(where: { $0.id == notebook.id }) ?? notebook
    }

    var body: some View {
        Group {
            if liveNotebook.folders.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No Folders",
                    message: "Create a folder to organize your pages.",
                    action: { showingCreateFolder = true },
                    actionLabel: "Create Folder"
                )
            } else {
                List {
                    ForEach(liveNotebook.folders) { folder in
                        NavigationLink {
                            FolderDetailView(folder: folder, notebookID: notebook.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.name).font(.headline)
                                    Text("\(folder.pages.count) pages").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { idx in
                            manager.deleteFolder(liveNotebook.folders[idx], from: notebook.id)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(liveNotebook.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreateFolder = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateFolder) {
            CreateFolderView(notebookID: notebook.id)
        }
    }
}
