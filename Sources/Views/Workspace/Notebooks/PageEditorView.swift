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

    @State private var editorMode: EditorMode = .notes
    @State private var isPreview = false

    @State private var showingAI = false
    @State private var aiResult = ""
    @State private var aiLoading = false
    @State private var aiTask = ""

    @State private var autosaveTask: Task<Void, Never>? = nil
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingFilePicker = false

    @State private var canvasNotes: [CanvasNote] = []
    @State private var canvasZoom: CGFloat = 1.0

    // Sheet states
    @State private var showingSearch = false
    @State private var showingCompare = false
    @State private var showingComments = false
    @State private var showingLogs = false
    @State private var showingAttachments = false
    @State private var showingPageInfo = false
    @State private var showingCanvasSettings = false
    @State private var showingAIResult = false
    @State private var showingBlockPicker = false
    @State private var showingVersionHistory = false
    @State private var showingCitations = false
    @State private var showingUnsplash = false

    private let autosaveDelayNanoseconds: UInt64 = 1_500_000_000
    private let defaultNoteSpawn = CGPoint(x: 320, y: 320)
    private let bootstrapFirstNote = CGPoint(x: 220, y: 220)
    private let bootstrapSecondNote = CGPoint(x: 560, y: 320)
    private let defaultNotebookAISystemPrompt = "You are a notebook copilot. Return concise markdown with actionable structure and clarity."

    init(page: NotebookPage, folderID: UUID, notebookID: UUID) {
        self.page = page
        self.folderID = folderID
        self.notebookID = notebookID
        _title = State(initialValue: page.title)
        _content = State(initialValue: page.content)
        _attachments = State(initialValue: page.attachments)
    }

    private enum EditorMode: String, CaseIterable, Sendable {
        case notes = "Notes"
        case canvas = "Canvas"

        var icon: String {
            switch self {
            case .notes: return "doc.text"
            case .canvas: return "square.grid.3x3.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topTitleBar
                    .padding(.horizontal)
                    .padding(.top, 10)

                modeSwitcher
                    .padding(.horizontal)
                    .padding(.top, 6)

                Group {
                    if editorMode == .notes {
                        notesEditor
                    } else {
                        infiniteCanvas
                    }
                }
                .padding(.top, 6)
            }

            if editorMode == .notes && !isPreview {
                formattingToolbar
                    .padding(.bottom, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingSearch) {
            NotebookSearchPageView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingCompare) {
            NotebookComparePagesView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingComments) {
            NotebookAddCommentsView(pageID: page.id)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingLogs) {
            NotebookAuditLogsView(pageID: page.id)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAttachments) {
            attachmentsSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingPageInfo) {
            pageInfoSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAIResult) {
            aiResultSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingBlockPicker) {
            blockPickerSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingVersionHistory) {
            Text("Version history is currently unavailable in this build.")
                .foregroundStyle(.secondary)
                .padding()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingCitations) {
            CitationFormatsView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingUnsplash) {
            UnsplashImagesView { photo in
                insertUnsplashImage(photo)
            }
        }
        .sheet(isPresented: $showingCanvasSettings) {
            canvasSettingsSheet
                .presentationDetents([.medium])
        }
        .confirmationDialog("Notebook AI Tools", isPresented: $showingAI, titleVisibility: .visible) {
            Button("Summarize Page") { runAI("Summarize", "Summarize these notes with concise key takeaways and decisions:\n\n\(content)") }
            Button("Create Meeting Minutes") { runAI("Meeting Minutes", "Convert these notes into meeting minutes with agenda, decisions, owners, and action items:\n\n\(content)") }
            Button("Generate Study Guide") { runAI("Study Guide", "Turn this page into a study guide with concepts, memory aids, and quiz prompts:\n\n\(content)") }
            Button("Build Project Plan") { runAI("Project Plan", "Convert these notes into a project plan with milestones, timeline, risks, and checklist:\n\n\(content)") }
            Button("Knowledge Graph") { runAI("Knowledge Graph", "Extract entities and relationships and present as markdown bullets grouped by topic:\n\n\(content)") }
            if !manager.integrations.filter(\.isEnabled).isEmpty {
                Button("Use Integration…") { showingAI = false; showIntegrationPicker() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await importPhoto(newItem) }
        }
        .onChange(of: aiResult) { _, newValue in
            if !newValue.isEmpty && newValue != "Loading…" {
                showingAIResult = true
            }
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            importFiles(result)
        }
        .onAppear(perform: bootstrapCanvas)
        .onDisappear { save() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPreview.toggle()
                }
            } label: {
                Image(systemName: isPreview ? "pencil" : "eye")
            }
            .disabled(editorMode == .canvas)

            Menu {
                Section("Insert") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Photo", systemImage: "photo")
                    }
                    Button { showingUnsplash = true } label: {
                        Label("Unsplash Image", systemImage: "photo.on.rectangle.angled")
                    }
                    Button { showingFilePicker = true } label: {
                        Label("File", systemImage: "paperclip")
                    }
                    Button { showingBlockPicker = true } label: {
                        Label("Block", systemImage: "plus.square")
                    }
                }

                Section("Tools") {
                    Button { showingAI = true } label: {
                        Label("AI Assistant", systemImage: "sparkles")
                    }
                    Button { showingSearch = true } label: {
                        Label("Search Pages", systemImage: "magnifyingglass")
                    }
                    Button { showingCompare = true } label: {
                        Label("Compare Pages", systemImage: "arrow.left.and.right")
                    }
                    Button { showingCitations = true } label: {
                        Label("Citations", systemImage: "quote.opening")
                    }
                }

                Section("Review") {
                    Button { showingComments = true } label: {
                        Label("Comments", systemImage: "bubble.left.and.right")
                    }
                    Button { showingLogs = true } label: {
                        Label("Audit Logs", systemImage: "clock.arrow.circlepath")
                    }
                    Button { showingVersionHistory = true } label: {
                        Label("Version History", systemImage: "clock.badge.checkmark")
                    }
                }

                Section("Page") {
                    Button { showingAttachments = true } label: {
                        Label("Attachments (\(attachments.count))", systemImage: "paperclip")
                    }
                    Button { showingPageInfo = true } label: {
                        Label("Page Info", systemImage: "info.circle")
                    }
                    if editorMode == .canvas {
                        Button { showingCanvasSettings = true } label: {
                            Label("Canvas Settings", systemImage: "slider.horizontal.3")
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
            ? [Color(red: 0.07, green: 0.08, blue: 0.11), Color(red: 0.04, green: 0.05, blue: 0.08)]
            : [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.92, green: 0.95, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Top Title Bar

    private var topTitleBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Untitled Page", text: $title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .onChange(of: title) { _, _ in scheduleAutosave() }

            HStack(spacing: 6) {
                Label("\(content.split { $0.isWhitespace }.count) words", systemImage: "textformat.abc")
                Text("·")
                Text("\(attachments.count) files")
                Text("·")
                Text(page.updatedAt, style: .time)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Mode Switcher

    private var modeSwitcher: some View {
        HStack(spacing: 6) {
            ForEach(EditorMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { editorMode = mode }
                } label: {
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(editorMode == mode ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Notes Editor

    private var notesEditor: some View {
        ScrollView {
            VStack(spacing: 10) {
                aiQuickActions

                if isPreview {
                    Text(renderPreview(content))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    if page.blocks.isEmpty {
                        Text("Start typing, or add blocks from the toolbar…")
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                    }

                    ForEach(page.blocks.indices, id: \.self) { idx in
                        BlockRenderer(
                            block: Binding(
                                get: { page.blocks[idx] },
                                set: { newValue in
                                    var updated = page
                                    updated.blocks[idx] = newValue
                                    manager.updatePage(updated, in: folderID, notebookID: notebookID)
                                }
                            ),
                            onDelete: {
                                manager.deleteBlock(page.blocks[idx].id, from: page.id, folderID: folderID, notebookID: notebookID)
                            },
                            onUpdate: {
                                manager.updatePage(page, in: folderID, notebookID: notebookID)
                            }
                        )
                    }

                    Button {
                        showingBlockPicker = true
                    } label: {
                        Label("Add Block", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Infinite Canvas

    private var infiniteCanvas: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button {
                    canvasNotes.append(CanvasNote(text: "New Note", position: defaultNoteSpawn))
                    scheduleAutosave()
                } label: {
                    Label("Add", systemImage: "plus.square.on.square")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Slider(value: $canvasZoom, in: 0.5...1.8)
                        .frame(maxWidth: 120)
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.secondarySystemBackground).opacity(0.35))
                        .frame(width: 2400, height: 2400)
                        .overlay(canvasGrid)

                    ForEach($canvasNotes) { $note in
                        CanvasStickyNote(note: $note)
                    }
                }
                .scaleEffect(canvasZoom, anchor: .topLeading)
                .padding(20)
            }
        }
    }

    private var canvasGrid: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 48
                var x: CGFloat = 0
                while x <= geo.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += step
                }
            }
            .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
        }
    }

    // MARK: - Formatting Toolbar

    private var formattingToolbar: some View {
        HStack(spacing: 14) {
            toolbarIcon("bold") { wrap("**") }
            toolbarIcon("italic") { wrap("_") }
            toolbarIcon("h1") { insert("# ") }
            toolbarIcon("h2") { insert("## ") }
            toolbarIcon("list.bullet") { insert("- ") }
            toolbarIcon("link") { insert("[text](url)") }
            toolbarIcon("checklist") { insert("- [ ] ") }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    // MARK: - AI Quick Actions

    private var aiQuickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                quickActionChip("Summarize", icon: "text.alignleft") {
                    runAI("Summarize", "Summarize these notes in concise markdown bullets:\n\n\(content)")
                }
                quickActionChip("Action Items", icon: "checklist") {
                    runAI("Action Items", "Extract action items as markdown checklist only:\n\n\(content)")
                }
                quickActionChip("Structure", icon: "square.grid.2x2") {
                    runAI("Structure", "Reorganize these notes into clear markdown sections:\n\n\(content)")
                }
                quickActionChip("Study", icon: "brain.head.profile") {
                    runAI("Study", "Turn this into study guide with key terms and quiz prompts:\n\n\(content)")
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Attachments Sheet

    private var attachmentsSheet: some View {
        NavigationStack {
            List {
                if attachments.isEmpty {
                    ContentUnavailableView("No Attachments", systemImage: "paperclip", description: Text("Add images or files from the toolbar."))
                } else {
                    ForEach(attachments, id: \.self) { item in
                        HStack(spacing: 10) {
                            Image(systemName: iconForAttachment(item))
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 32)
                            Text(item)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { idxs in
                        attachments.remove(atOffsets: idxs)
                        scheduleAutosave()
                    }
                }
            }
            .navigationTitle("Attachments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAttachments = false }.bold()
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !attachments.isEmpty {
                        Button("Clear All", role: .destructive) {
                            attachments.removeAll()
                            scheduleAutosave()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Page Info Sheet

    private var pageInfoSheet: some View {
        NavigationStack {
            List {
                Section("Statistics") {
                    infoRow("Words", value: "\(content.split { $0.isWhitespace }.count)")
                    infoRow("Characters", value: "\(content.count)")
                    infoRow("Lines", value: "\(content.components(separatedBy: .newlines).count)")
                    infoRow("Paragraphs", value: "\(content.components(separatedBy: "\n\n").count)")
                    infoRow("Blocks", value: "\(page.blocks.count)")
                    infoRow("Attachments", value: "\(attachments.count)")
                }

                Section("Timestamps") {
                    infoRow("Created", value: page.createdAt.formatted(date: .long, time: .shortened))
                    infoRow("Modified", value: page.updatedAt.formatted(date: .long, time: .shortened))
                }

                Section("Reading Time") {
                    let wordCount = content.split { $0.isWhitespace }.count
                    let minutes = max(1, wordCount / 200)
                    infoRow("Estimated", value: "\(minutes) min read")
                }
            }
            .navigationTitle("Page Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingPageInfo = false }.bold()
                }
            }
        }
    }

    // MARK: - AI Result Sheet

    private var aiResultSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if aiLoading {
                        HStack {
                            ProgressView()
                            Text("Processing…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        Label("AI \(aiTask)", systemImage: "sparkles")
                            .font(.headline)

                        Group {
                            if let parsed = try? AttributedString(markdown: aiResult) {
                                Text(parsed)
                            } else {
                                Text(aiResult)
                            }
                        }
                        .font(.body)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAIResult = false }.bold()
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = aiResult
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Button {
                            content += "\n\n" + aiResult
                            editorMode = .notes
                            scheduleAutosave()
                            showingAIResult = false
                        } label: {
                            Label("Insert into Page", systemImage: "plus.bubble")
                        }
                        Button {
                            aiResult = ""
                        } label: {
                            Label("Dismiss Result", systemImage: "xmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Block Picker Sheet

    private var blockPickerSheet: some View {
        NavigationStack {
            List {
                Section("Content Blocks") {
                    blockPickerRow("Text", icon: "doc.text", kind: .text)
                    blockPickerRow("Code", icon: "chevron.left.forwardslash.chevron.right", kind: .code)
                    blockPickerRow("Toggle", icon: "chevron.down.circle", kind: .toggle)
                }
                Section("Data Blocks") {
                    blockPickerRow("Database", icon: "tablecells", kind: .database)
                    blockPickerRow("Embed", icon: "link", kind: .embed)
                    blockPickerRow("Widget", icon: "square.grid.2x2", kind: .widget)
                }
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showingBlockPicker = false }
                }
            }
        }
    }

    private func blockPickerRow(_ title: String, icon: String, kind: NotebookBlock.BlockKind) -> some View {
        Button {
            manager.addBlock(to: page.id, folderID: folderID, notebookID: notebookID, kind: kind)
            showingBlockPicker = false
        } label: {
            Label(title, systemImage: icon)
        }
    }

    // MARK: - Canvas Settings Sheet

    private var canvasSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("Zoom") {
                    HStack {
                        Text("Scale: \(String(format: "%.0f%%", canvasZoom * 100))")
                            .font(.subheadline)
                        Spacer()
                        Button("Reset") { canvasZoom = 1.0 }
                            .font(.caption)
                    }
                    Slider(value: $canvasZoom, in: 0.5...1.8)
                }

                Section("Notes") {
                    HStack {
                        Text("Count")
                        Spacer()
                        Text("\(canvasNotes.count)")
                            .foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) {
                        canvasNotes.removeAll()
                    } label: {
                        Label("Clear All Notes", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Canvas Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingCanvasSettings = false }.bold()
                }
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.monospaced())
        }
    }

    private func toolbarIcon(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    private func quickActionChip(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.accentColor.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func insert(_ markdown: String) { content += markdown }

    private func wrap(_ marker: String) { content += "\(marker)text\(marker)" }

    private func renderPreview(_ md: String) -> AttributedString {
        (try? AttributedString(markdown: md)) ?? AttributedString(md)
    }

    private func runAI(_ task: String, _ prompt: String, systemPrompt: String? = nil, model: String? = nil) {
        aiTask = task
        aiLoading = true
        aiResult = "Loading…"
        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: systemPrompt ?? defaultNotebookAISystemPrompt,
                    model: model
                )
                await MainActor.run { aiResult = result; aiLoading = false }
            } catch {
                await MainActor.run { aiResult = "Error: \(error.localizedDescription)"; aiLoading = false }
            }
        }
    }

    private func showIntegrationPicker() {
        if let tool = manager.integrations.first(where: { $0.isEnabled }) {
            runIntegration(tool)
        }
    }

    private func runIntegration(_ tool: IntegrationTool) {
        let attachmentsContext = tool.includeAttachmentsContext ? attachments.joined(separator: ", ") : "Not included"
        var prompt = tool.promptTemplate
            .replacingOccurrences(of: "{{content}}", with: content)
            .replacingOccurrences(of: "{{title}}", with: title)
            .replacingOccurrences(of: "{{attachments}}", with: attachmentsContext)
            .replacingOccurrences(of: "{{word_count}}", with: "\(content.split { $0.isWhitespace }.count)")
            .replacingOccurrences(of: "{{timestamp}}", with: Date().formatted(date: .abbreviated, time: .shortened))

        if !tool.requiredVariables.isEmpty {
            prompt += "\n\nRequired variables:\n" + tool.requiredVariables.map { "- \($0)" }.joined(separator: "\n")
        }

        if !tool.postProcessingRules.isEmpty {
            prompt += "\n\nPost-processing rules:\n" + tool.postProcessingRules.map { "- \($0)" }.joined(separator: "\n")
        }

        prompt += "\n\nOutput style: \(tool.outputStyle.rawValue)."
        runAI(tool.name, prompt, systemPrompt: tool.systemPrompt, model: tool.aiModel)
    }

    private func bootstrapCanvas() {
        guard canvasNotes.isEmpty else { return }
        canvasNotes = [
            CanvasNote(text: "Key Idea", position: bootstrapFirstNote),
            CanvasNote(text: "Details", position: bootstrapSecondNote)
        ]
    }

    private func insertUnsplashImage(_ photo: UnsplashPhoto) {
        let imageURL = photo.urls.regular
        let credit = "Photo by \(photo.user.name) on Unsplash"
        content += "\n\n![\(photo.altDescription ?? "Unsplash image")](\(imageURL))\n*\(credit)*"
        scheduleAutosave()
    }

    private func importPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let name = "image-\(Date().timeIntervalSince1970).jpg"
                attachments.insert(name, at: 0)
                content += "\n\n![\(name)](attachment://\(name))"
                scheduleAutosave()
            }
        } catch {
            // Keep flow silent if picker fails.
        }
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result else { return }
        for url in urls {
            let name = url.lastPathComponent
            if !name.isEmpty {
                attachments.insert(name, at: 0)
                content += "\n\n[\(name)](attachment://\(name))"
            }
        }
        scheduleAutosave()
    }

    private func iconForAttachment(_ name: String) -> String {
        let ext = URL(fileURLWithPath: name).pathExtension.lowercased()
        switch ext {
        case "png", "jpg", "jpeg", "heic", "gif", "webp": return "photo"
        case "pdf": return "doc.richtext"
        case "zip", "gz", "tar": return "archivebox"
        case "mov", "mp4", "m4v": return "film"
        case "mp3", "wav", "m4a": return "music.note"
        default: return "doc"
        }
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
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Page" : title
        updated.content = content
        updated.attachments = attachments
        updated.updatedAt = Date()
        manager.updatePage(updated, in: folderID, notebookID: notebookID)
    }
}

private struct CanvasNote: Identifiable, Sendable {
    let id = UUID()
    var text: String
    var position: CGPoint
}

private struct CanvasStickyNote: View {
    @Binding var note: CanvasNote

    var body: some View {
        TextField("Note", text: $note.text, axis: .vertical)
            .textFieldStyle(.plain)
            .padding(12)
            .frame(width: 220, height: 130, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.yellow.opacity(0.32))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 1)
            )
            .position(note.position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        note.position = value.location
                    }
            )
    }
}

struct BlockRenderer: View {
    @Binding var block: NotebookBlock
    var onDelete: () -> Void
    var onUpdate: () -> Void

    var body: some View {
        WorkspaceSurfaceCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon(for: block.kind))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(block.kind.rawValue.capitalized)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()

                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Block", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                switch block.kind {
                case .text:
                    TextBlockView(block: $block, onUpdate: onUpdate)
                case .code:
                    CodeBlockView(block: $block, onUpdate: onUpdate)
                case .database:
                    DatabaseBlockView(block: $block, onUpdate: onUpdate)
                case .toggle:
                    ToggleBlockView(block: $block, onUpdate: onUpdate)
                case .embed:
                    EmbedBlockView(block: $block, onUpdate: onUpdate)
                case .widget:
                    WidgetBlockView(block: $block, onUpdate: onUpdate)
                }
            }
        }
    }

    private func icon(for kind: NotebookBlock.BlockKind) -> String {
        switch kind {
        case .text: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .database: return "tablecells"
        case .toggle: return "chevron.down.circle"
        case .embed: return "link"
        case .widget: return "square.grid.2x2"
        }
    }
}
