import SwiftUI

struct DocumentationEditorView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var selectedPageId: UUID?
    @State private var isRawMode = false
    @State private var showingAddSection = false
    @State private var newSectionTitle = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPageId) {
                ForEach(store.docSections.indices, id: \.self) { sectionIndex in
                    Section(header: Text(store.docSections[sectionIndex].title)) {
                        ForEach(store.docSections[sectionIndex].pages.indices, id: \.self) { pageIndex in
                            let page = store.docSections[sectionIndex].pages[pageIndex]
                            NavigationLink(value: page.id) {
                                HStack {
                                    Text(page.title)
                                    if page.isDraft {
                                        Text("DRAFT").font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 4).padding(.vertical, 2)
                                            .background(.orange.opacity(0.1)).foregroundStyle(.orange)
                                    }
                                }
                            }
                        }

                        Button {
                            addPage(to: store.docSections[sectionIndex])
                        } label: {
                            Label("Add Page", systemImage: "plus.circle")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Documentation")
            .toolbar {
                Button { showingAddSection = true } label: { Image(systemName: "folder.badge.plus") }
            }
        } detail: {
            if let pageId = selectedPageId, let pageBinding = findPageBinding(for: pageId) {
                editorView(for: pageBinding)
            } else {
                Text("Select a page to edit").foregroundStyle(.secondary)
            }
        }
        .alert("New Section", isPresented: $showingAddSection) {
            TextField("Section Title", text: $newSectionTitle)
            Button("Cancel", role: .cancel) { newSectionTitle = "" }
            Button("Add") {
                if !newSectionTitle.isEmpty {
                    var currentSections = store.docSections
                    currentSections.append(DocumentationSection(title: newSectionTitle, pages: []))
                    store.saveDocSections(currentSections)
                    newSectionTitle = ""
                }
            }
        }
    }

    private func editorView(for page: Binding<DocPage>) -> some View {
        VStack(spacing: 0) {
            toolbar(for: page)

            if isRawMode {
                TextEditor(text: page.content)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .onChange(of: page.content.wrappedValue) { _, _ in store.saveDocSections(store.docSections) }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Page Title", text: page.title)
                            .font(.title).bold()
                            .onChange(of: page.title.wrappedValue) { _, _ in store.saveDocSections(store.docSections) }

                        Text("Markdown Preview").font(.caption).foregroundStyle(.secondary)

                        Text(page.content.wrappedValue)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Edit Page")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toolbar(for page: Binding<DocPage>) -> some View {
        HStack {
            Picker("Mode", selection: $isRawMode) {
                Text("Editor").tag(false)
                Text("Markdown").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)

            Spacer()

            Toggle("Draft", isOn: page.isDraft)
                .font(.caption)
                .onChange(of: page.isDraft.wrappedValue) { _, _ in store.saveDocSections(store.docSections) }

            Button("Save") {
                page.wrappedValue.lastModified = Date()
                store.saveDocSections(store.docSections)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func addPage(to section: DocumentationSection) {
        if let index = store.docSections.firstIndex(where: { $0.id == section.id }) {
            var currentSections = store.docSections
            let newPage = DocPage(id: UUID(), title: "Untitled Page", content: "", lastModified: Date(), version: "1.0.0", isDraft: true)
            currentSections[index].pages.append(newPage)
            store.saveDocSections(currentSections)
            selectedPageId = newPage.id
        }
    }

    private func findPageBinding(for id: UUID) -> Binding<DocPage>? {
        for sectionIndex in store.docSections.indices {
            if let pageIndex = store.docSections[sectionIndex].pages.firstIndex(where: { $0.id == id }) {
                return Binding(
                    get: { store.docSections[sectionIndex].pages[pageIndex] },
                    set: {
                        var currentSections = store.docSections
                        currentSections[sectionIndex].pages[pageIndex] = $0
                        store.saveDocSections(currentSections)
                    }
                )
            }
        }
        return nil
    }
}
