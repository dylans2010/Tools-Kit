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

    private let autosaveDelayNanoseconds: UInt64 = 1_500_000_000

    init(page: NotebookPage, folderID: UUID, notebookID: UUID) {
        self.page = page
        self.folderID = folderID
        self.notebookID = notebookID
        _title = State(initialValue: page.title)
        _content = State(initialValue: page.content)
        _attachments = State(initialValue: page.attachments)
    }

    private enum EditorMode: String, CaseIterable {
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
                    .padding(.top, 14)

                modeSwitcher
                    .padding(.horizontal)
                    .padding(.top, 8)

                aiQuickActions
                    .padding(.horizontal)
                    .padding(.top, 8)

                Group {
                    if editorMode == .notes {
                        notesEditor
                    } else {
                        infiniteCanvas
                    }
                }
                .padding(.top, 8)

                attachmentsSection
                    .padding(.horizontal)
                    .padding(.bottom, editorMode == .notes ? 74 : 16)
            }

            if !aiResult.isEmpty {
                aiOverlay
            }

            if editorMode == .notes && !isPreview {
                formattingToolbar
                    .padding(.bottom, 18)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPreview.toggle()
                    }
                } label: {
                    Image(systemName: isPreview ? "pencil" : "eye")
                }
                .disabled(editorMode == .canvas)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                }

                Button {
                    showingFilePicker = true
                } label: {
                    Image(systemName: "paperclip")
                }

                Button {
                    showingAI = true
                } label: {
                    Image(systemName: "sparkles")
                }
            }
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
        .onChange(of: selectedPhotoItem) { newItem in
            Task { await importPhoto(newItem) }
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            importFiles(result)
        }
        .onAppear(perform: bootstrapCanvas)
        .onDisappear { save() }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
            ? [Color(red: 0.07, green: 0.08, blue: 0.11), Color(red: 0.04, green: 0.05, blue: 0.08)]
            : [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.92, green: 0.95, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topTitleBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Untitled Page", text: $title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .onChange(of: title) { _ in scheduleAutosave() }
            HStack(spacing: 8) {
                Label("\(content.split { $0.isWhitespace }.count) words", systemImage: "textformat.abc")
                Text("•")
                Text("\(attachments.count) attachments")
                Text("•")
                Text("Edited \(page.updatedAt, style: .time)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(EditorMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { editorMode = mode }
                } label: {
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(editorMode == mode ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var notesEditor: some View {
        Group {
            if isPreview {
                ScrollView {
                    Text(renderPreview(content))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Start typing, paste content, or add files/images…")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }
                    TextEditor(text: $content)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 16)
                        .onChange(of: content) { _ in scheduleAutosave() }
                }
            }
        }
    }

    private var infiniteCanvas: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    canvasNotes.append(CanvasNote(text: "New Note", position: CGPoint(x: 320, y: 320)))
                    scheduleAutosave()
                } label: {
                    Label("Add Note", systemImage: "plus.square.on.square")
                }
                .buttonStyle(.bordered)

                HStack(spacing: 8) {
                    Text("Zoom")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $canvasZoom, in: 0.5...1.8)
                        .frame(maxWidth: 160)
                }
                Spacer()
                Text("Infinite Canvas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

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
        .padding(.horizontal)
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

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Attachments", systemImage: "paperclip")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !attachments.isEmpty {
                    Button("Clear") {
                        attachments.removeAll()
                        scheduleAutosave()
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            if attachments.isEmpty {
                Text("No attachments yet. Add images or files from the toolbar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(attachments, id: \.self) { item in
                            HStack(spacing: 6) {
                                Image(systemName: iconForAttachment(item))
                                Text(item)
                                    .lineLimit(1)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private var aiOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI \(aiTask)", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Button { aiResult = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            if aiLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
            } else {
                ScrollView {
                    Group {
                        if let parsed = try? AttributedString(markdown: aiResult) {
                            Text(parsed)
                        } else {
                            Text(aiResult)
                        }
                    }
                    .font(.callout)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)

                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = aiResult
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        content += "\n\n" + aiResult
                        editorMode = .notes
                        scheduleAutosave()
                    } label: {
                        Label("Insert", systemImage: "plus.bubble")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 10)
        .padding()
    }

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
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private var aiQuickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
            .padding(.vertical, 4)
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

    private func runAI(_ task: String, _ prompt: String) {
        aiTask = task
        aiLoading = true
        aiResult = "Loading…"
        Task {
            do {
                let result = try await AIService.shared.processText(
                    prompt: prompt,
                    systemPrompt: "You are a notebook copilot. Return concise markdown with actionable structure and clarity."
                )
                await MainActor.run { aiResult = result; aiLoading = false }
            } catch {
                await MainActor.run { aiResult = "Error: \(error.localizedDescription)"; aiLoading = false }
            }
        }
    }

    private func showIntegrationPicker() {
        if let tool = manager.integrations.first(where: { $0.isEnabled }) {
            let prompt = tool.promptTemplate.replacingOccurrences(of: "{{content}}", with: content)
            runAI(tool.name, prompt)
        }
    }

    private func bootstrapCanvas() {
        guard canvasNotes.isEmpty else { return }
        canvasNotes = [
            CanvasNote(text: "Key Idea", position: CGPoint(x: 220, y: 220)),
            CanvasNote(text: "Details", position: CGPoint(x: 560, y: 320))
        ]
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

private struct CanvasNote: Identifiable {
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
