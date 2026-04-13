import SwiftUI

struct NotebookSidebarView: View {
    let notebook: Notebook
    let notebookID: UUID
    @StateObject private var manager = NotebooksManager.shared
    @Binding var selectedFolder: NotebookFolder?
    @Binding var selectedPage: NotebookPage?

    private var liveNotebook: Notebook {
        manager.notebooks.first(where: { $0.id == notebookID }) ?? notebook
    }

    var body: some View {
        List {
            ForEach(liveNotebook.folders) { folder in
                Section(header: Text(folder.name).font(.caption.bold())) {
                    ForEach(folder.pages) { page in
                        Button {
                            selectedFolder = folder
                            selectedPage = page
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(page.title)
                                    .font(.subheadline)
                                    .foregroundColor(selectedPage?.id == page.id ? .accentColor : .primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(liveNotebook.name)
    }
}
