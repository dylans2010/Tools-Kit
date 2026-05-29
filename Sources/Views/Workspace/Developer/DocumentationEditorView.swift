import SwiftUI

struct DocumentationEditorView: View {
    @ObservedObject var docService = DocumentationService.shared
    @State private var selectedPageID: UUID?
    @State private var page: DocumentationPage?
    @State private var isSaving = false

    var body: some View {
        HStack(spacing: 0) {
            // Page List
            List(selection: $selectedPageID) {
                Section("Your Documentation") {
                    if docService.pages.isEmpty {
                        Text("No pages yet.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(docService.pages) { p in
                            Text(p.title).tag(p.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(width: 250)

            Divider()

            // Editor
            Group {
                if page != nil {
                    VStack(spacing: 0) {
                        TextField("Page Title", text: Binding(
                            get: { page?.title ?? "" },
                            set: { page?.title = $0 }
                        ))
                        .font(.title2.bold())
                        .padding()

                        Divider()

                        TextEditor(text: Binding(
                            get: { page?.content ?? "" },
                            set: { page?.content = $0 }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "book.and.wrench")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Select a page to edit or create a new one.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Documentation Editor")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    createNewPage()
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCurrentPage()
                }
                .disabled(page == nil)
            }
        }
        .onChange(of: selectedPageID) { newID in
            if let id = newID {
                page = docService.pages.first { $0.id == id }
            }
        }
    }

    private func createNewPage() {
        Task {
            let newPage = try? await docService.createPage(appID: UUID(), title: "New Page")
            await MainActor.run {
                if let p = newPage {
                    selectedPageID = p.id
                    page = p
                }
            }
        }
    }

    private func saveCurrentPage() {
        guard let p = page else { return }
        isSaving = true
        Task {
            try? await docService.savePage(p)
            await MainActor.run {
                isSaving = false
            }
        }
    }
}
