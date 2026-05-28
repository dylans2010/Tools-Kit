import SwiftUI

struct DocumentationEditorView: View {
    @State private var sections: [DocSection] = [
        DocSection(title: "Getting Started", pages: [
            DocPage(id: UUID(), title: "Overview", content: "# Welcome to GitHub Pro", lastModified: Date(), version: "1.0.0", isDraft: false),
            DocPage(id: UUID(), title: "Installation", content: "Steps to install...", lastModified: Date(), version: "1.0.0", isDraft: false)
        ]),
        DocSection(title: "API Reference", pages: [
            DocPage(id: UUID(), title: "Authentication", content: "Auth details...", lastModified: Date(), version: "1.0.0", isDraft: true)
        ])
    ]

    @State private var selectedPageId: UUID?
    @State private var isRawMode = false

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
                    }
                }
            }
            .navigationTitle("Documentation")
            .toolbar {
                Button { /* Add Section */ } label: { Image(systemName: "folder.badge.plus") }
            }
        } detail: {
            if let pageId = selectedPageId {
                editorView(for: pageId)
            } else {
                Text("Select a page to edit").foregroundStyle(.secondary)
            }
        }
    }

    private func editorView(for pageId: UUID) -> some View {
        VStack(spacing: 0) {
            toolbar

            if isRawMode {
                TextEditor(text: .constant("# Content"))
                    .font(.system(.body, design: .monospaced))
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rich Editor Placeholder").font(.title).bold()
                        Text("This is where the rich content editor with Markdown support would render.").foregroundStyle(.secondary)

                        codeBlockSample
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Edit Page")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var toolbar: some View {
        HStack {
            Picker("Mode", selection: $isRawMode) {
                Text("Rich Text").tag(false)
                Text("Markdown").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            Button("Preview") {}.buttonStyle(.bordered)
            Button("Publish") {}.buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private var codeBlockSample: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Swift").font(.caption.bold())
                Spacer()
                Button { /* Copy */ } label: { Image(systemName: "doc.on.doc").font(.caption) }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))

            Text("import ToolsKit\n\nlet client = GitHubClient()\nclient.authenticate()")
                .font(.system(size: 12, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.05))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DocSection: Identifiable {
    let id = UUID()
    var title: String
    var pages: [DocPage]
}
