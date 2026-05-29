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
            VStack {
                Picker("Project", selection: $selectedAppID) {
                    Text("Select Project").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
                .padding()

                List(selection: $selectedPageID) {
                    ForEach(filteredPages) { page in
                        NavigationLink(value: page.id) {
                            HStack {
                                Image(systemName: page.isPublished ? "doc.plaintext.fill" : "doc.plaintext")
                                    .foregroundStyle(page.isPublished ? .green : .secondary)
                                Text(page.title)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .onDelete(perform: deletePages)
                }

                if selectedAppID != nil {
                    Button { showingAddPage = true } label: {
                        Label("Add Page", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
            }
            .navigationTitle("Docs")
            .toolbar {
                if showSaveIndicator {
                    ToolbarItem(placement: .status) {
                        Text("Saved").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        } detail: {
            if let page = selectedPage {
                editorView(page)
            } else {
                EmptyStateView(icon: "doc.text.magnifyingglass", title: "No Page Selected", message: "Select a page to edit or create a new one.")
            }
        }
        .sheet(isPresented: $showingAddPage) {
            addPageSheet
        }
    }

    private func editorView(_ page: DocumentationPage) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text(page.title).font(.title2.bold())
                    Text("Slug: \(page.slug)").font(.caption).monospaced().foregroundStyle(.tertiary)
                }
                Spacer()
                Button(page.isPublished ? "Unpublish" : "Publish") {
                    Task {
                        if page.isPublished {
                            try? await docService.unpublishPage(id: page.id)
                        } else {
                            try? await docService.publishPage(id: page.id)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(page.isPublished ? .red : .green)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))

            TextEditor(text: Binding(
                get: { page.content },
                set: { newContent in
                    var updated = page
                    updated.content = newContent
                    Task {
                        try? await docService.savePage(updated)
                        await MainActor.run {
                            withAnimation { showSaveIndicator = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSaveIndicator = false }
                            }
                        }
                    }
                }
            ))
            .font(.system(.body, design: .monospaced))
            .padding()

            HStack {
                Text("Last updated: \(page.updatedAt.formatted())")
                    .font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                if let publishedAt = page.publishedAt {
                    Text("Published: \(publishedAt.formatted())")
                        .font(.caption2).foregroundStyle(.green)
                }
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private var addPageSheet: some View {
        NavigationStack {
            Form {
                TextField("Page Title", text: $newPageTitle)
            }
            .navigationTitle("New Page")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddPage = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if let appID = selectedAppID {
                            Task {
                                let newPage = try? await docService.createPage(appID: appID, title: newPageTitle)
                                await MainActor.run {
                                    selectedPageID = newPage?.id
                                    newPageTitle = ""
                                    showingAddPage = false
                                }
                            }
                        }
                    }
                    .disabled(newPageTitle.isEmpty)
                }
            }
        }
    }

    private func deletePages(at offsets: IndexSet) {
        for index in offsets {
            let page = filteredPages[index]
            Task { try? await docService.deletePage(id: page.id) }
        }
    }
}
