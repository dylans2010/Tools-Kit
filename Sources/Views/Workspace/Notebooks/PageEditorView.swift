import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

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
    @State private var customAIPrompt = ""
    @State private var showingCustomAIInput = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingFilePicker = false

    // New Sheets
    @State private var showingDictionary = false
    @State private var showingWordSuggestions = false
    @State private var showingAnalytics = false
    @State private var showingEssayDrafting = false
    @State private var showingScanNotebooks = false
    @State private var showingTaskConsolidation = false
    @State private var showingMindMap = false
    @State private var showingFlashcards = false
    @State private var showingReferences = false
    @State private var showingSpeechNotes = false

    // Existing Sheets
    @State private var showingSearch = false
    @State private var showingIntegrationsPicker = false
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
        .sheet(isPresented: $showingIntegrationsPicker) {
            IntegrationsPickerView(isPresented: $showingIntegrationsPicker) { tool in
                runIntegration(tool)
            }
        }
        .sheet(isPresented: $showingEssayDrafting) {
            EssayDraftingView()
        }
        .sheet(isPresented: $showingScanNotebooks) {
            ScanNotebooksView()
        }
        .sheet(isPresented: $showingTaskConsolidation) {
            NavigationStack { NotebookTaskConsolidationView() }
        }
        .sheet(isPresented: $showingMindMap) {
            NavigationStack { NotebookMindMapGeneratorView() }
        }
        .sheet(isPresented: $showingFlashcards) {
            NavigationStack { NotebookFlashcardGeneratorView(content: content) }
        }
        .sheet(isPresented: $showingReferences) {
            NavigationStack { NotebookReferenceManagerView(content: content) }
        }
        .sheet(isPresented: $showingSpeechNotes) {
            SpeechNotesView { text in
                appendContent("\n\n\(text)")
            }
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
                    previewContent
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

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let lines = content.components(separatedBy: "\n")
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if isImageLine(trimmed) {
                    renderImageLine(trimmed)
                } else if isAttachmentLine(trimmed) {
                    renderAttachmentLine(trimmed)
                } else {
                    MarkdownRenderedView(markdown: line)
                }
            }
        }
    }

    private func isImageLine(_ line: String) -> Bool {
        line.hasPrefix("![") && line.contains("](") && line.hasSuffix(")")
    }

    private func isAttachmentLine(_ line: String) -> Bool {
        line.hasPrefix("[") && line.contains("](attachment://") && line.hasSuffix(")")
    }

    private func renderImageLine(_ line: String) -> some View {
        let urlString = extractURL(from: line)
        let altText = extractAltText(from: line)
        return VStack(alignment: .leading, spacing: 4) {
            if let url = URL(string: urlString), urlString.hasPrefix("http") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        imageErrorPlaceholder(altText)
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    @unknown default:
                        imageErrorPlaceholder(altText)
                    }
                }
            } else {
                imageErrorPlaceholder(altText)
            }
            if !altText.isEmpty {
                Text(altText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }

    private func renderAttachmentLine(_ line: String) -> some View {
        let fileName = extractLinkText(from: line)
        let ext = (fileName as NSString).pathExtension.lowercased()
        let isImage = ["jpg", "jpeg", "png", "gif", "webp", "heic", "bmp", "tiff", "svg"].contains(ext)
        let isPDF = ext == "pdf"
        let isVideo = ["mp4", "mov", "avi", "mkv", "m4v"].contains(ext)
        let isAudio = ["mp3", "wav", "m4a", "aac", "flac"].contains(ext)

        return HStack(spacing: 12) {
            Image(systemName: isImage ? "photo" : isPDF ? "doc.richtext" : isVideo ? "film" : isAudio ? "waveform" : "paperclip")
                .font(.title3)
                .foregroundStyle(isImage ? .blue : isPDF ? .red : isVideo ? .purple : isAudio ? .orange : .secondary)
                .frame(width: 40, height: 40)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.subheadline.weight(.medium))
                Text(ext.uppercased() + " file")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func imageErrorPlaceholder(_ alt: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(alt.isEmpty ? "Image" : alt)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func extractURL(from line: String) -> String {
        guard let openParen = line.range(of: "]("),
              let closeParen = line.range(of: ")", range: openParen.upperBound..<line.endIndex) else { return "" }
        return String(line[openParen.upperBound..<closeParen.lowerBound])
    }

    private func extractAltText(from line: String) -> String {
        guard let start = line.firstIndex(of: "["),
              let end = line.range(of: "](") else { return "" }
        let afterBracket = line.index(after: start)
        guard afterBracket < end.lowerBound else { return "" }
        return String(line[afterBracket..<end.lowerBound])
    }

    private func extractLinkText(from line: String) -> String {
        guard let start = line.firstIndex(of: "["),
              let end = line.range(of: "](") else { return "" }
        let afterBracket = line.index(after: start)
        guard afterBracket < end.lowerBound else { return "" }
        return String(line[afterBracket..<end.lowerBound])
    }

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    toolbarButton(icon: "textformat", label: "Format") { showFormattingPopover = true }
                        .sheet(isPresented: $showFormattingPopover) { formattingPopover }

                    toolbarButton(icon: "slash.circle", label: "Insert") { showSlashCommand.toggle() }

                    toolbarButton(icon: "paperclip", label: "Attach") { showingFilePicker = true }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 18))
                            Text("Photo").font(.system(size: 10, weight: .medium))
                        }
                    }
                    .foregroundColor(.primary)

                    toolbarButton(icon: "sparkles", label: "AI") { showingAI = true }
                        .confirmationDialog("AI Assistant", isPresented: $showingAI) {
                            Button("Summarize") { runAI("Summarize", "Summarize these notes concisely: \(content)") }
                            Button("Action Items") { runAI("Action Items", "Extract action items from: \(content)") }
                            Button("Expand Ideas") { runAI("Expand", "Expand on the key ideas in: \(content)") }
                            Button("Fix Grammar") { runAI("Grammar", "Fix grammar and spelling in: \(content)") }
                            Button("Simplify Language") { runAI("Simplify", "Simplify the language in: \(content)") }
                            Button("Make Professional") { runAI("Professional", "Rewrite in a professional tone: \(content)") }
                            Button("Translate to Spanish") { runAI("Translate", "Translate to Spanish: \(content)") }
                            Button("Generate Outline") { runAI("Outline", "Create a structured outline from: \(content)") }
                            Button("Key Takeaways") { runAI("Takeaways", "Extract key takeaways from: \(content)") }
                            Button("Create Quiz") { runAI("Quiz", "Create a quiz with questions and answers from: \(content)") }
                            Button("Generate Title") { runAI("Title", "Suggest 5 titles for: \(content)") }
                            Button("Add Citations") { runAI("Citations", "Add suggested citations and references for: \(content)") }
                            Button("Explain Like I'm 5") { runAI("ELI5", "Explain this content simply for a beginner: \(content)") }
                            Button("Find Contradictions") { runAI("Contradictions", "Find any contradictions or inconsistencies in: \(content)") }
                            Button("Custom Prompt...") { showingCustomAIInput = true }
                            Button("Cancel", role: .cancel) {}
                        }
                        .sheet(isPresented: $showingCustomAIInput) {
                            customAIInputSheet
                        }

                    toolbarButton(icon: "chart.bar.doc.horizontal", label: "Analytics") { showingAnalytics = true }

                    toolbarButton(icon: "doc.text.badge.plus", label: "Draft") { showingEssayDrafting = true }

                    toolbarButton(icon: "doc.text.viewfinder", label: "Scan") { showingScanNotebooks = true }

                    toolbarButton(icon: "checklist", label: "Tasks") { showingTaskConsolidation = true }

                    toolbarButton(icon: "circle.grid.cross", label: "Mind Map") { showingMindMap = true }

                    toolbarButton(icon: "rectangle.stack.badge.person.crop", label: "Study") { showingFlashcards = true }

                    toolbarButton(icon: "link.circle", label: "Refs") { showingReferences = true }

                    toolbarButton(icon: "mic", label: "Speech") { showingSpeechNotes = true }

                    toolbarButton(icon: "book.closed", label: "Dictionary") { showingDictionary = true }

                    toolbarButton(icon: "wand.and.stars", label: "Suggestions") { showingWordSuggestions = true }

                    toolbarButton(icon: "puzzlepiece.extension", label: "Integrations") { showingIntegrationsPicker = true }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            }
            .background(.ultraThinMaterial)
        }
    }

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label).font(.system(size: 10, weight: .medium))
            }
        }
        .foregroundColor(.primary)
    }

    private var formattingPopover: some View {
        NotebookFormattingView(content: $content, isPresented: $showFormattingPopover)
            .presentationDetents([.height(350), .medium])
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
                Text("Insert").font(.caption2.bold()).foregroundColor(.secondary).padding(.horizontal).padding(.vertical, 12)
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
                .frame(maxHeight: 350)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding()
            .padding(.bottom, 60)
        }
        .background(Color.black.opacity(0.2).onTapGesture { showSlashCommand = false })
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
                        VStack(spacing: 16) {
                            Spacer().frame(height: 40)
                            Text("Processing with AI...")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text(aiTask)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        MarkdownRenderedView(markdown: aiResult)
                            .padding()
                    }
                }
            }
            .aiAnimationLoading(aiLoading)
            .navigationTitle(aiTask.isEmpty ? "AI Result" : aiTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingAIResult = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        UIPasteboard.general.string = aiResult
                    } label: {
                        Label("Copy", systemImage: "doc.on.clipboard")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        content += "\n\n" + aiResult
                        showingAIResult = false
                    } label: {
                        Label("Insert into Page", systemImage: "plus.square.on.square")
                    }
                    .disabled(aiResult.isEmpty || aiLoading)
                }
            }
        }
    }

    private var customAIInputSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Enter your custom prompt")
                    .font(.headline)
                    .padding(.top, 16)

                Text("The AI will process your page content based on your instructions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                TextEditor(text: $customAIPrompt)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topLeading) {
                        if customAIPrompt.isEmpty {
                            Text("e.g. Rewrite this as bullet points, Convert to a table...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 18)
                                .padding(.leading, 14)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle("Custom AI Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCustomAIInput = false
                        customAIPrompt = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Run") {
                        let prompt = customAIPrompt
                        showingCustomAIInput = false
                        customAIPrompt = ""
                        runAI("Custom", "\(prompt)\n\nContent:\n\(content)")
                    }
                    .bold()
                    .disabled(customAIPrompt.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func runIntegration(_ tool: IntegrationTool) {
        aiTask = tool.name
        aiLoading = true
        showingAIResult = true
        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: tool.promptTemplate.replacingOccurrences(of: "{{content}}", with: content),
                    systemPrompt: tool.systemPrompt,
                    model: tool.aiModel
                )
                await MainActor.run { aiResult = result; aiLoading = false }
            } catch {
                await MainActor.run { aiResult = "Error: \(error.localizedDescription)"; aiLoading = false }
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
struct NotebookFormattingView: View {
    @Binding var content: String
    @Binding var isPresented: Bool

    @State private var selectedFont = "System"
    @State private var fontSize: CGFloat = 16
    @State private var lineSpacing: CGFloat = 4
    @State private var characterSpacing: CGFloat = 0
    @State private var paragraphSpacing: CGFloat = 10
    @State private var indentation: CGFloat = 0

    @State private var alignment: TextAlignment = .leading
    @State private var textColor: Color = .primary
    @State private var highlightColor: Color = .yellow

    let fonts = ["System", "Serif", "Monospace", "Rounded", "Georgia", "Helvetica", "Courier"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Text Formatting", systemImage: "textformat")
                    .font(.headline)
                Spacer()
                Button("Done") { isPresented = false }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Appearance", systemImage: "paintbrush.fill")
                            .font(.subheadline.bold()).foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Text Color").font(.caption2).foregroundStyle(.secondary)
                                ColorPicker("Text", selection: $textColor)
                                    .labelsHidden()
                            }

                            VStack(alignment: .leading) {
                                Text("Highlight").font(.caption2).foregroundStyle(.secondary)
                                ColorPicker("Highlight", selection: $highlightColor)
                                    .labelsHidden()
                            }

                            Spacer()

                            Button {
                                applyColor()
                            } label: {
                                Label("Apply Color", systemImage: "paintpalette")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                applyHighlight()
                            } label: {
                                Label("Highlight", systemImage: "highlighter")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Typography", systemImage: "text.cursor")
                            .font(.subheadline.bold()).foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(fonts, id: \.self) { font in
                                    Button(action: { selectedFont = font }) {
                                        Text(font)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedFont == font ? Color.accentColor : Color.secondary.opacity(0.1))
                                            .foregroundColor(selectedFont == font ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        VStack(spacing: 16) {
                            SliderRow(label: "Size", value: $fontSize, range: 10...40, icon: "textformat.size")
                            SliderRow(label: "Line Height", value: $lineSpacing, range: 0...20, icon: "line.3.horizontal")
                            SliderRow(label: "Character Spacing", value: $characterSpacing, range: -2...10, icon: "arrow.left.and.right")
                            SliderRow(label: "Paragraph Spacing", value: $paragraphSpacing, range: 0...40, icon: "paragraphsign")
                            SliderRow(label: "Indentation", value: $indentation, range: 0...50, icon: "arrow.right.to.line")
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Emphasis", systemImage: "bold.italic.underline")
                            .font(.subheadline.bold()).foregroundColor(.secondary)

                        HStack(spacing: 10) {
                            formatButton(icon: "bold", action: { wrap("**") })
                            formatButton(icon: "italic", action: { wrap("_") })
                            formatButton(icon: "underline", action: { wrap("<u>", "</u>") })
                            formatButton(icon: "strikethrough", action: { wrap("~~") })
                            formatButton(icon: "link", action: { insert("[link](url)") })
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Structure", systemImage: "list.bullet.indent")
                            .font(.subheadline.bold()).foregroundColor(.secondary)

                        FlowLayout(["h1", "h2", "h3", "h4", "list", "number", "quote", "code", "table"], spacing: 8) { type in
                            switch type {
                            case "h1": structureButton(label: "H1", action: { insert("\n# ") })
                            case "h2": structureButton(label: "H2", action: { insert("\n## ") })
                            case "h3": structureButton(label: "H3", action: { insert("\n### ") })
                            case "h4": structureButton(label: "H4", action: { insert("\n#### ") })
                            case "list": structureButton(label: "Bullet", icon: "list.bullet", action: { insert("\n- ") })
                            case "number": structureButton(label: "Number", icon: "list.number", action: { insert("\n1. ") })
                            case "quote": structureButton(label: "Quote", icon: "quote.opening", action: { insert("\n> ") })
                            case "code": structureButton(label: "Code", icon: "curlybraces", action: { insert("\n```\n\n```") })
                            case "table": structureButton(label: "Table", icon: "tablecells", action: { insert("\n|  |  |\n|--|--|\n|  |  |\n") })
                            default: EmptyView()
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    struct SliderRow: View {
        let label: String
        @Binding var value: CGFloat
        let range: ClosedRange<CGFloat>
        let icon: String

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
                    Text(label).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(value))").font(.caption.monospaced()).bold()
                }
                Slider(value: $value, in: range)
            }
        }
    }

    private func applyColor() {
        wrap("**", "**")
    }

    private func applyHighlight() {
        wrap("==", "==")
    }

    private func formatButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 40, height: 40)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func alignmentButton(icon: String, align: TextAlignment) -> some View {
        Button(action: { alignment = align }) {
            Image(systemName: icon)
                .foregroundColor(alignment == align ? .accentColor : .primary)
                .frame(width: 40, height: 40)
                .background(alignment == align ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func structureButton(label: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon { Image(systemName: icon) }
                Text(label)
            }
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }

    private func insert(_ text: String) {
        content += text
    }

    private func wrap(_ marker: String) {
        content += " " + marker + "your text" + marker
    }

    private func wrap(_ start: String, _ end: String) {
        content += " " + start + "your text" + end
    }
}

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
                    ShareLink(item: content, preview: SharePreview(title, image: Image(systemName: "doc.text"))) {
                        Label("Export as Plain Text", systemImage: "text.alignleft")
                    }

                    ShareLink(item: content, subject: Text(title), message: Text("Markdown Export")) {
                        Label("Export as Markdown", systemImage: "arrow.down.doc")
                    }

                    if let richText = try? NSAttributedString(markdown: content),
                       let rtfData = try? richText.data(from: NSRange(location: 0, length: richText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                        ShareLink(item: rtfData, preview: SharePreview(title, image: Image(systemName: "textformat"))) {
                            Label("Export as Rich Text", systemImage: "textformat")
                        }
                    }

                    Button(action: { UIPasteboard.general.string = content }) {
                        Label("Copy Page Link", systemImage: "link")
                    }
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

// MARK: - Markdown Rendered View

struct MarkdownRenderedView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum MarkdownBlock {
        case heading(Int, String)
        case paragraph(String)
        case bulletItem(String)
        case numberedItem(Int, String)
        case codeBlock(String)
        case blockquote(String)
        case divider
        case table([[String]])
        case highlight(String)
    }

    private func parseBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = markdown.components(separatedBy: "\n")
        var i = 0
        var currentParagraph = ""

        func flushParagraph() {
            let trimmed = currentParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(.paragraph(trimmed))
            }
            currentParagraph = ""
        }

        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.hasPrefix("```") {
                flushParagraph()
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
                i += 1
                continue
            }

            if trimmedLine.hasPrefix("####") {
                flushParagraph()
                let text = String(trimmedLine.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(4, text))
            } else if trimmedLine.hasPrefix("###") {
                flushParagraph()
                let text = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(3, text))
            } else if trimmedLine.hasPrefix("##") {
                flushParagraph()
                let text = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(2, text))
            } else if trimmedLine.hasPrefix("# ") {
                flushParagraph()
                let text = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(1, text))
            } else if trimmedLine.hasPrefix("---") || trimmedLine.hasPrefix("***") || trimmedLine.hasPrefix("___") {
                flushParagraph()
                blocks.append(.divider)
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                flushParagraph()
                let text = String(trimmedLine.dropFirst(2))
                blocks.append(.bulletItem(text))
            } else if let dotIndex = trimmedLine.firstIndex(of: "."),
                      dotIndex > trimmedLine.startIndex,
                      let num = Int(String(trimmedLine[trimmedLine.startIndex..<dotIndex])),
                      trimmedLine.index(after: dotIndex) < trimmedLine.endIndex,
                      trimmedLine[trimmedLine.index(after: dotIndex)] == " " {
                flushParagraph()
                let textStart = trimmedLine.index(dotIndex, offsetBy: 2)
                let text = textStart < trimmedLine.endIndex ? String(trimmedLine[textStart...]) : ""
                blocks.append(.numberedItem(num, text))
            } else if trimmedLine.hasPrefix("> ") {
                flushParagraph()
                let text = String(trimmedLine.dropFirst(2))
                blocks.append(.blockquote(text))
            } else if trimmedLine.hasPrefix("|") && trimmedLine.hasSuffix("|") {
                flushParagraph()
                var tableRows: [[String]] = []
                while i < lines.count {
                    let tableLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if tableLine.hasPrefix("|") && tableLine.hasSuffix("|") {
                        let cells = tableLine
                            .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                            .components(separatedBy: "|")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                        let isSeparator = cells.allSatisfy { $0.allSatisfy { $0 == "-" || $0 == ":" } }
                        if !isSeparator {
                            tableRows.append(cells)
                        }
                        i += 1
                    } else {
                        break
                    }
                }
                if !tableRows.isEmpty {
                    blocks.append(.table(tableRows))
                }
                continue
            } else if trimmedLine.contains("==") && trimmedLine.range(of: "==.+==", options: .regularExpression) != nil {
                flushParagraph()
                blocks.append(.highlight(trimmedLine))
            } else if trimmedLine.isEmpty {
                flushParagraph()
            } else {
                if !currentParagraph.isEmpty {
                    currentParagraph += " "
                }
                currentParagraph += trimmedLine
            }

            i += 1
        }
        flushParagraph()
        return blocks
    }

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            renderInlineMarkdown(text)
                .font(headingFont(level))
                .fontWeight(.bold)
                .padding(.top, level == 1 ? 8 : 4)

        case .paragraph(let text):
            renderInlineMarkdown(text)
                .font(.body)
                .lineSpacing(4)

        case .bulletItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("\u{2022}")
                    .font(.body)
                    .foregroundColor(.secondary)
                renderInlineMarkdown(text)
                    .font(.body)
            }
            .padding(.leading, 8)

        case .numberedItem(let num, let text):
            HStack(alignment: .top, spacing: 8) {
                Text("\(num).")
                    .font(.body.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(minWidth: 20, alignment: .trailing)
                renderInlineMarkdown(text)
                    .font(.body)
            }
            .padding(.leading, 8)

        case .codeBlock(let code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .blockquote(let text):
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 3)
                renderInlineMarkdown(text)
                    .font(.body.italic())
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .padding(.leading, 4)

        case .divider:
            Divider()
                .padding(.vertical, 4)

        case .table(let rows):
            renderTable(rows)

        case .highlight(let text):
            let cleaned = text.replacingOccurrences(of: "==", with: "")
            Text(cleaned)
                .font(.body)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.yellow.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        default: return .headline
        }
    }

    private func renderInlineMarkdown(_ text: String) -> Text {
        var result = Text("")
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            if remaining.hasPrefix("**") || remaining.hasPrefix("__") {
                let marker = String(remaining.prefix(2))
                remaining = remaining.dropFirst(2)
                if let endRange = remaining.range(of: marker) {
                    let boldText = String(remaining[remaining.startIndex..<endRange.lowerBound])
                    result = result + Text(boldText).bold()
                    remaining = remaining[endRange.upperBound...]
                    continue
                } else {
                    result = result + Text(marker)
                    continue
                }
            }

            if remaining.hasPrefix("*") || remaining.hasPrefix("_") {
                let marker = String(remaining.prefix(1))
                remaining = remaining.dropFirst(1)
                if let endRange = remaining.range(of: marker) {
                    let italicText = String(remaining[remaining.startIndex..<endRange.lowerBound])
                    result = result + Text(italicText).italic()
                    remaining = remaining[endRange.upperBound...]
                    continue
                } else {
                    result = result + Text(marker)
                    continue
                }
            }

            if remaining.hasPrefix("~~") {
                remaining = remaining.dropFirst(2)
                if let endRange = remaining.range(of: "~~") {
                    let strikeText = String(remaining[remaining.startIndex..<endRange.lowerBound])
                    result = result + Text(strikeText).strikethrough()
                    remaining = remaining[endRange.upperBound...]
                    continue
                } else {
                    result = result + Text("~~")
                    continue
                }
            }

            if remaining.hasPrefix("`") {
                remaining = remaining.dropFirst(1)
                if let endRange = remaining.range(of: "`") {
                    let codeText = String(remaining[remaining.startIndex..<endRange.lowerBound])
                    result = result + Text(codeText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.purple)
                    remaining = remaining[endRange.upperBound...]
                    continue
                } else {
                    result = result + Text("`")
                    continue
                }
            }

            if remaining.hasPrefix("==") {
                remaining = remaining.dropFirst(2)
                if let endRange = remaining.range(of: "==") {
                    let highlightText = String(remaining[remaining.startIndex..<endRange.lowerBound])
                    result = result + Text(highlightText)
                        .foregroundColor(.black)
                        .backgroundColor(.yellow)
                    remaining = remaining[endRange.upperBound...]
                    continue
                } else {
                    result = result + Text("==")
                    continue
                }
            }

            if remaining.hasPrefix("[") {
                if let closeBracket = remaining.range(of: "]"),
                   remaining[closeBracket.upperBound...].hasPrefix("("),
                   let closeParen = remaining[closeBracket.upperBound...].range(of: ")") {
                    let linkText = String(remaining[remaining.index(after: remaining.startIndex)..<closeBracket.lowerBound])
                    result = result + Text(linkText)
                        .foregroundColor(.blue)
                        .underline()
                    remaining = remaining[closeParen.upperBound...]
                    continue
                }
            }

            let nextSpecial = findNextSpecialChar(in: remaining)
            let plainEnd = nextSpecial ?? remaining.endIndex
            let plainText = String(remaining[remaining.startIndex..<plainEnd])
            result = result + Text(plainText)
            remaining = remaining[plainEnd...]
        }

        return result
    }

    private func findNextSpecialChar(in text: Substring) -> String.Index? {
        let markers: [String] = ["**", "__", "*", "_", "~~", "`", "==", "["]
        var earliest: String.Index? = nil
        for marker in markers {
            if let range = text.range(of: marker) {
                if range.lowerBound != text.startIndex {
                    if earliest == nil || range.lowerBound < earliest! {
                        earliest = range.lowerBound
                    }
                }
            }
        }
        return earliest
    }

    @ViewBuilder
    private func renderTable(_ rows: [[String]]) -> some View {
        if let header = rows.first {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                        Text(cell)
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                    }
                }
                Divider()
                ForEach(Array(rows.dropFirst().enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(cell)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                    }
                    Divider()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator), lineWidth: 0.5))
        }
    }
}

// MARK: - Text.backgroundColor helper
private extension Text {
    func backgroundColor(_ color: Color) -> Text {
        self.foregroundColor(.black)
    }
}

struct IntegrationsPickerView: View {
    @Binding var isPresented: Bool
    let onSelect: (IntegrationTool) -> Void
    @StateObject private var manager = NotebooksManager.shared

    var body: some View {
        NavigationStack {
            List {
                if manager.integrations.isEmpty {
                    ContentUnavailableView("No Integrations", systemImage: "puzzlepiece", description: Text("Create custom AI tools in the Integrations menu."))
                } else {
                    ForEach(manager.integrations) { tool in
                        Button {
                            onSelect(tool)
                            isPresented = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tool.name).font(.headline)
                                Text(tool.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Integration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
