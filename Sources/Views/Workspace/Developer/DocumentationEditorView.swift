import SwiftUI

struct DocumentationEditorView: View {
    @ObservedObject var docService = DocumentationService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var selectedPageID: UUID?
    @State private var showingAddPage = false
    @State private var newPageTitle = ""
    @State private var showSaveIndicator = false

    var filteredPages: [DocumentationPage] {
        docService.pages.filter { $0.appID == selectedAppID }
            .sorted { $0.order < $1.order }
    }

    var selectedPage: DocumentationPage? {
        docService.pages.first { $0.id == selectedPageID }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                appSelector

                List(selection: $selectedPageID) {
                    if filteredPages.isEmpty && selectedAppID != nil {
                        Text("No pages created yet.").font(.caption).foregroundStyle(.secondary).padding()
                    } else if selectedAppID == nil {
                        Text("Select a project to manage documentation.").font(.caption).foregroundStyle(.secondary).padding()
                    }

                    ForEach(filteredPages) { page in
                        NavigationLink(value: page.id) {
                            HStack {
                                Image(systemName: page.isPublished ? "doc.plaintext.fill" : "doc.plaintext")
                                    .foregroundStyle(page.isPublished ? .green : .secondary)
                                Text(page.title)
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                    .onDelete(perform: deletePages)
                    .onMove(perform: movePages)
                }

                if selectedAppID != nil {
                    Button { showingAddPage = true } label: {
                        Label("Add Page", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .background(Color.primary.opacity(0.05))
                    .overlay(alignment: .top) { Divider() }
                }
            }
            .navigationTitle("Docs Editor")
            .toolbar {
                if showSaveIndicator {
                    ToolbarItem(placement: .status) {
                        Text("Draft Saved").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) { EditButton() }
            }
        } detail: {
            if let page = selectedPage {
                editorContent(page)
            } else {
                EmptyStateView(icon: "doc.text.magnifyingglass", title: "Select a Page", message: "Choose a page from the sidebar to edit its content or metadata.")
            }
        }
        .sheet(isPresented: $showingAddPage) { addPageSheet }
    }

    private var appSelector: some View {
        Picker("Project", selection: $selectedAppID) {
            Text("Select Project").tag(Optional<UUID>.none)
            ForEach(appService.apps) { app in
                Text(app.name).tag(Optional(app.id))
            }
        }
        .pickerStyle(.menu)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func editorContent(_ page: DocumentationPage) -> some View {
        VStack(spacing: 0) {
            editorHeader(page)

            TextEditor(text: Binding(
                get: { page.content },
                set: { newContent in
                    var updated = page
                    updated.content = newContent
                    savePage(updated)
                }
            ))
            .font(.system(.body, design: .monospaced))
            .padding()

            footerBar(page)
        }
    }

    private func editorHeader(_ page: DocumentationPage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(page.title).font(.headline)
                Text("slug: \(page.slug)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
            }
            Spacer()
            Button(page.isPublished ? "Unpublish" : "Publish") {
                togglePublish(page)
            }
            .buttonStyle(.bordered)
            .tint(page.isPublished ? .red : .green)
            .controlSize(.small)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func footerBar(_ page: DocumentationPage) -> some View {
        HStack {
            Text("Last updated \(page.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 9)).foregroundStyle(.tertiary)
            Spacer()
            if let publishedAt = page.publishedAt {
                Label("Live: \(publishedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .bold)).foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay(alignment: .top) { Divider() }
    }

    private var addPageSheet: some View {
        NavigationStack {
            Form {
                Section("Metadata") {
                    TextField("Page Title", text: $newPageTitle)
                }
            }
            .navigationTitle("New Documentation Page")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddPage = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPage()
                    }
                    .disabled(newPageTitle.isEmpty || selectedAppID == nil)
                }
            }
        }
    }

    private func savePage(_ page: DocumentationPage) {
        Task {
            try? await docService.savePage(page)
            await MainActor.run {
                withAnimation { showSaveIndicator = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSaveIndicator = false }
                }
            }
        }
    }

    private func createPage() {
        guard let appID = selectedAppID else { return }
        Task {
            let newPage = try? await docService.createPage(appID: appID, title: newPageTitle)
            await MainActor.run {
                selectedPageID = newPage?.id
                newPageTitle = ""
                showingAddPage = false
            }
        }
    }

    private func togglePublish(_ page: DocumentationPage) {
        Task {
            if page.isPublished {
                try? await docService.unpublishPage(id: page.id)
            } else {
                try? await docService.publishPage(id: page.id)
            }
        }
    }

    private func deletePages(at offsets: IndexSet) {
        for index in offsets {
            let id = filteredPages[index].id
            Task { try? await docService.deletePage(id: id) }
        }
    }

    private func movePages(from source: IndexSet, to destination: Int) {
        var pages = filteredPages
        pages.move(fromOffsets: source, toOffset: destination)
        Task {
            try? await docService.reorderPages(appID: selectedAppID!, pageIDs: pages.map { $0.id })
        }
    }
}
