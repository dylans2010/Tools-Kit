import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PageEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let page: NotebookPage
    let folderID: UUID
    let notebookID: UUID

    @StateObject private var manager = NotebooksManager.shared

    @State private var title: String
    @State private var content: String
    @State private var attachments: [String]

    @State private var isPreview = false
    @State private var showSlashCommand = false
    @State private var showFormattingPopover = false

    // AI & Features
    @State private var showingAI = false
    @State private var aiResult = ""
    @State private var aiLoading = false
    @State private var aiTask = ""

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingFilePicker = false

    // New Sheets
    @State private var showingDictionary = false
    @State private var showingWordSuggestions = false
    @State private var showingAnalytics = false

    // Existing Sheets
    @State private var showingSearch = false
    @State private var showingCompare = false
    @State private var showingComments = false
    @State private var showingLogs = false
    @State private var showingPageInfo = false
    @State private var showingAIResult = false
    @State private var showingVersionHistory = false
    @State private var showingCitations = false
    @State private var showingUnsplash = false

    @State private var autosaveTask: Task<Void, Never>? = nil
    private let autosaveDelayNanoseconds: UInt64 = 1_500_000_000

    init(page: NotebookPage, folderID: UUID, notebookID: UUID) {
        self.page = page
        self.folderID = folderID
        self.notebookID = notebookID
        _title = State(initialValue: page.title)
        _content = State(initialValue: page.content)
        _attachments = State(initialValue: page.attachments)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                editorContent
                bottomToolbar
            }

            if showSlashCommand {
                slashCommandPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Page Title", text: $title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .onChange(of: title) { _, _ in scheduleAutosave() }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    isPreview.toggle()
                } label: {
                    Image(systemName: isPreview ? "pencil" : "eye")
                }

                Menu {
                    Button { showingPageInfo = true } label: { Label("Page Info", systemImage: "info.circle") }
                    Button { showingCitations = true } label: { Label("Citations", systemImage: "quote.opening") }
                    Button { showingSearch = true } label: { Label("Search Pages", systemImage: "magnifyingglass") }
                    Button { showingCompare = true } label: { Label("Compare Pages", systemImage: "arrow.left.and.right") }
                    Divider()
                    Button { showingComments = true } label: { Label("Comments", systemImage: "bubble.left.and.right") }
                    Button { showingLogs = true } label: { Label("Audit Logs", systemImage: "clock.arrow.circlepath") }
                    Button { showingVersionHistory = true } label: { Label("Version History", systemImage: "clock.badge.checkmark") }
                    Divider()
                    ShareLink(item: content, subject: Text(title))
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingDictionary) {
            DictionaryView(isPresented: $showingDictionary) { text in
                appendContent("\n\n\(text)")
            }
        }
        .sheet(isPresented: $showingWordSuggestions) {
            WordSuggestionsView(isPresented: $showingWordSuggestions, initialWord: "") { word in
                appendContent(word)
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            WritingAnalyticsView(documentText: content, documentTitle: title, isPresented: $showingAnalytics)
        }
        .sheet(isPresented: $showingPageInfo) {
            PageInfoView(page: page, content: content, title: $title, isPresented: $showingPageInfo)
        }
        .sheet(isPresented: $showingCitations) {
            CitationFormatsView()
        }
        .sheet(isPresented: $showingSearch) { NotebookSearchPageView() }
        .sheet(isPresented: $showingCompare) { NotebookComparePagesView() }
        .sheet(isPresented: $showingComments) { NotebookAddCommentsView(pageID: page.id) }
        .sheet(isPresented: $showingLogs) { NotebookAuditLogsView(pageID: page.id) }
        .sheet(isPresented: $showingAIResult) { aiResultSheet }
        .sheet(isPresented: $showingFilePicker) {
            FileImporterRepresentableView(allowedContentTypes: [.item], allowsMultipleSelection: true) { urls in
                importFiles(urls)
            }
        }
        .sheet(isPresented: $showingUnsplash) {
            UnsplashImagesView { photo in
                insertUnsplashImage(photo)
            }
        }
        .onChange(of: content) { oldValue, newValue in
            if newValue.hasSuffix("/") && !oldValue.hasSuffix("/") {
                showSlashCommand = true
            } else if !newValue.hasSuffix("/") {
                showSlashCommand = false
            }
            scheduleAutosave()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await importPhoto(newItem) }
        }
        .onDisappear { save() }
    }

    private var editorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isPreview {
                    Text((try? AttributedString(markdown: content)) ?? AttributedString(content))
                        .padding()
                } else {
                    TextEditor(text: $content)
                        .font(.body)
                        .frame(minHeight: 500)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 20) {
                toolbarButton(icon: "textformat", label: "Format") { showFormattingPopover = true }
                    .popover(isPresented: $showFormattingPopover) { formattingPopover }

                toolbarButton(icon: "slash.circle", label: "Insert") { showSlashCommand.toggle() }

                toolbarButton(icon: "paperclip", label: "Attach") { showingFilePicker = true }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                        Text("Photo").font(.system(size: 10))
                    }
                }

                toolbarButton(icon: "sparkles", label: "AI") { showingAI = true }
                    .confirmationDialog("AI Assistant", isPresented: $showingAI) {
                        Button("Summarize") { runAI("Summarize", "Summarize these notes: \(content)") }
                        Button("Action Items") { runAI("Action Items", "Extract action items: \(content)") }
                        Button("Cancel", role: .cancel) {}
                    }

                toolbarButton(icon: "chart.bar.doc.horizontal", label: "Analytics") { showingAnalytics = true }

                toolbarButton(icon: "book.closed", label: "Dictionary") { showingDictionary = true }

                toolbarButton(icon: "wand.and.stars", label: "Suggestions") { showingWordSuggestions = true }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(.ultraThinMaterial)
        }
    }

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(label).font(.system(size: 10))
            }
        }
        .foregroundColor(.primary)
    }

    private var formattingPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Formatting").font(.headline).padding(.bottom, 4)
            Group {
                formatItem(label: "Bold", icon: "bold") { wrap("**") }
                formatItem(label: "Italic", icon: "italic") { wrap("_") }
                formatItem(label: "Underline", icon: "underline") { wrap("__") }
                formatItem(label: "Strikethrough", icon: "strikethrough") { wrap("~~") }
            }
            Divider()
            Group {
                formatItem(label: "Heading 1", icon: "h1.circle") { insert("\n# ") }
                formatItem(label: "Heading 2", icon: "h2.circle") { insert("\n## ") }
                formatItem(label: "Heading 3", icon: "h3.circle") { insert("\n### ") }
            }
            Divider()
            Group {
                formatItem(label: "Inline Code", icon: "code") { wrap("`") }
                formatItem(label: "Blockquote", icon: "quote.opening") { insert("\n> ") }
            }
        }
        .padding()
        .frame(width: 200)
    }

    private func formatItem(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            showFormattingPopover = false
        }) {
            Label(label, systemImage: icon)
        }
    }

    private var slashCommandPanel: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("INSERT").font(.caption2.bold()).foregroundColor(.secondary).padding(.horizontal).padding(.vertical, 8)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        slashItem(label: "Heading 1", icon: "h1.circle") { insert("\n# ") }
                        slashItem(label: "Heading 2", icon: "h2.circle") { insert("\n## ") }
                        slashItem(label: "Heading 3", icon: "h3.circle") { insert("\n### ") }
                        slashItem(label: "Bullet List", icon: "list.bullet") { insert("\n- ") }
                        slashItem(label: "Numbered List", icon: "list.number") { insert("\n1. ") }
                        slashItem(label: "Divider", icon: "minus") { insert("\n---\n") }
                        slashItem(label: "Code Block", icon: "curlybraces") { insert("\n```\n\n```") }
                        slashItem(label: "Quote", icon: "quote.opening") { insert("\n> ") }
                        slashItem(label: "Table", icon: "tablecells") { insert("\n|  |  |\n|--|--|\n|  |  |\n") }
                        slashItem(label: "Image", icon: "photo") { showingUnsplash = true }
                        slashItem(label: "File", icon: "paperclip") { showingFilePicker = true }
                    }
                }
                .frame(maxHeight: 300)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
        .background(Color.black.opacity(0.1).onTapGesture { showSlashCommand = false })
    }

    @ViewBuilder
    private func slashItem(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            if content.hasSuffix("/") { content.removeLast() }
            action()
            showSlashCommand = false
        }) {
            HStack {
                Image(systemName: icon).frame(width: 24)
                Text(label)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .foregroundColor(.primary)
        Divider().padding(.leading, 40)
    }

    // MARK: - AI Result Sheet
    private var aiResultSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if aiLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else {
                        Text((try? AttributedString(markdown: aiResult)) ?? AttributedString(aiResult))
                            .padding()
                    }
                }
            }
            .navigationTitle("AI Result")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingAIResult = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Copy") { UIPasteboard.general.string = aiResult }
                }
            }
        }
    }

    // MARK: - Helpers
    private func insert(_ text: String) {
        content += text
    }

    private func wrap(_ marker: String) {
        content += marker + "text" + marker
    }

    private func appendContent(_ text: String) {
        content += text
    }

    private func runAI(_ task: String, _ prompt: String) {
        aiTask = task
        aiLoading = true
        showingAIResult = true
        Task {
            do {
                let result = try await AIService.shared.processText(prompt: prompt)
                await MainActor.run { aiResult = result; aiLoading = false }
            } catch {
                await MainActor.run { aiResult = "Error: \(error.localizedDescription)"; aiLoading = false }
            }
        }
    }

    private func importFiles(_ urls: [URL]) {
        for url in urls {
            attachments.insert(url.lastPathComponent, at: 0)
            content += "\n\n[\(url.lastPathComponent)](attachment://\(url.lastPathComponent))"
        }
        scheduleAutosave()
    }

    private func importPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let _ = try? await item.loadTransferable(type: Data.self) {
            let name = "image-\(Date().timeIntervalSince1970).jpg"
            attachments.insert(name, at: 0)
            content += "\n\n![\(name)](attachment://\(name))"
            scheduleAutosave()
        }
    }

    private func insertUnsplashImage(_ photo: UnsplashPhoto) {
        let imageURL = photo.urls.regular
        content += "\n\n![\(photo.altDescription ?? "Unsplash image")](\(imageURL))"
        scheduleAutosave()
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: autosaveDelayNanoseconds)
            if !Task.isCancelled { save() }
        }
    }

    private func save() {
        var updated = page
        updated.title = title.isEmpty ? "Untitled Page" : title
        updated.content = content
        updated.attachments = attachments
        updated.updatedAt = Date()
        manager.updatePage(updated, in: folderID, notebookID: notebookID)
    }
}

// MARK: - PageInfoView
struct PageInfoView: View {
    let page: NotebookPage
    let content: String
    @Binding var title: String
    @Binding var isPresented: Bool

    @State private var showIconPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section("Document Metadata") {
                    TextField("Title", text: $title)
                    LabeledContent("Created", value: page.createdAt.formatted(date: .long, time: .shortened))
                    LabeledContent("Modified", value: page.updatedAt.formatted(date: .long, time: .shortened))
                    LabeledContent("Words", value: "\(content.split { $0.isWhitespace }.count)")
                    LabeledContent("Characters", value: "\(content.count) / \(content.replacingOccurrences(of: " ", with: "").count)")
                    LabeledContent("Sentences", value: "\(content.components(separatedBy: CharacterSet(charactersIn: ".!?")).count)")
                    LabeledContent("Paragraphs", value: "\(content.components(separatedBy: "\n").count)")

                    let wc = content.split { $0.isWhitespace }.count
                    LabeledContent("Reading Time", value: "~ \(max(1, wc / 200)) min")
                    LabeledContent("Speaking Time", value: "~ \(max(1, wc / 130)) min")
                }

                Section("Content Analysis") {
                    let stats = WritingAnalyticsEngine.shared.computeStats(text: content)
                    let level = WritingAnalyticsEngine.shared.readabilityLevel(score: stats.readabilityScore)
                    LabeledContent("Readability", value: level.level)
                    LabeledContent("CEFR Level", value: level.cefr)
                    LabeledContent("Vocabulary Richness", value: String(format: "%.1f%%", stats.vocabularyRichness))
                }

                Section("Page Settings") {
                    Button("Page Icon") { showIconPicker = true }
                    ColorPicker("Page Color", selection: .constant(.blue))
                    Toggle("Cover Image", isOn: .constant(false))
                    Toggle("Show in Index", isOn: .constant(true))
                    Toggle("Lock Page", isOn: .constant(false))
                }

                Section("Export") {
                    Button("Export as PDF") {}
                    Button("Export as Markdown") {}
                    Button("Export as Plain Text") {}
                    Button("Copy Page Link") {}
                }
            }
            .navigationTitle("Page Info")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
