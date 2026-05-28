import SwiftUI

struct DocumentationEditorView: View {
    @State private var sections: [DocSection] = []
    @State private var selectedPageId: UUID?
    @State private var isRawMode = false
    @State private var showingAddSection = false
    @State private var newSectionTitle = ""

    init() {
        // Load from UserDefaults or start with defaults
        if let data = UserDefaults.standard.data(forKey: "com.toolskit.developer.docs"),
           let decoded = try? JSONDecoder().decode([DocSection].self, from: data) {
            _sections = State(initialValue: decoded)
        } else {
            _sections = State(initialValue: [
                DocSection(title: "Getting Started", pages: [
                    DocPage(id: UUID(), title: "Overview", content: "# Welcome to your Project\n\nEdit this page to provide an overview.", lastModified: Date(), version: "1.0.0", isDraft: false)
                ])
            ])
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPageId) {
                ForEach($sections) { $section in
                    Section(section.title) {
                        ForEach($section.pages) { $page in
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
                            addPage(to: section)
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
                    sections.append(DocSection(title: newSectionTitle, pages: []))
                    newSectionTitle = ""
                    saveDocs()
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
                    .onChange(of: page.content.wrappedValue) { _, _ in saveDocs() }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Page Title", text: page.title)
                            .font(.title).bold()
                            .onChange(of: page.title.wrappedValue) { _, _ in saveDocs() }

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
                .onChange(of: page.isDraft.wrappedValue) { _, _ in saveDocs() }

            Button("Save") {
                page.wrappedValue.lastModified = Date()
                saveDocs()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func addPage(to section: DocSection) {
        if let index = sections.firstIndex(where: { $0.id == section.id }) {
            let newPage = DocPage(id: UUID(), title: "Untitled Page", content: "", lastModified: Date(), version: "1.0.0", isDraft: true)
            sections[index].pages.append(newPage)
            selectedPageId = newPage.id
            saveDocs()
        }
    }

    private func saveDocs() {
        if let encoded = try? JSONEncoder().encode(sections) {
            UserDefaults.standard.set(encoded, forKey: "com.toolskit.developer.docs")
        }
    }

    private func findPageBinding(for id: UUID) -> Binding<DocPage>? {
        for sectionIndex in sections.indices {
            if let pageIndex = sections[sectionIndex].pages.firstIndex(where: { $0.id == id }) {
                return Binding(
                    get: { sections[sectionIndex].pages[pageIndex] },
                    set: { sections[sectionIndex].pages[pageIndex] = $0 }
                )
            }
        }
        return nil
    }
}

struct DocSection: Identifiable, Codable, View {
    var id = UUID()
    var title: String
    var pages: [DocPage]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(pages) { page in
                Text(page.content).foregroundStyle(.secondary)
            }
        }
    }
}
