import SwiftUI

struct NotesView: View {
    @StateObject private var backend = NotesBackend()
    @State private var showingAddNote = false
    @State private var searchText = ""
    @State private var selectedFolder: String? = nil
    @State private var viewMode: ViewMode = .grid

    private enum ViewMode { case grid, list }

    private let twoColumns = [GridItem(.flexible()), GridItem(.flexible())]

    private var folders: [String] {
        Array(Set(backend.notes.map { $0.folder })).sorted()
    }

    private var filteredNotes: [Note] {
        backend.notes
            .filter { note in
                (searchText.isEmpty
                    || note.title.localizedCaseInsensitiveContains(searchText)
                    || note.content.localizedCaseInsensitiveContains(searchText))
                && (selectedFolder == nil || note.folder == selectedFolder)
            }
            .sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned }
                return a.updatedAt > b.updatedAt
            }
    }

    var body: some View {
        let notesToShow: [Note] = filteredNotes
        let currentViewMode: ViewMode = viewMode

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Folder filter chips
                if !folders.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FolderChip(title: "All", isSelected: selectedFolder == nil) {
                                selectedFolder = nil
                            }
                            ForEach(folders, id: \.self) { folder in
                                FolderChip(title: folder, isSelected: selectedFolder == folder) {
                                    selectedFolder = folder
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    Divider()
                        .padding(.horizontal)
                }

                // Empty state
                if notesToShow.isEmpty {
                    let message: String = searchText.isEmpty
                        ? "Tap the + button to create your first note."
                        : "No notes match your search."
                    let action: (() -> Void)? = searchText.isEmpty ? { createNote() } : nil

                    EmptyStateView(
                        icon: "note.text",
                        title: "No Notes Yet",
                        message: message,
                        action: action,
                        actionLabel: "New Note"
                    )
                    .padding(.top, 20)
                } else if currentViewMode == .grid {
                    LazyVGrid(columns: twoColumns, spacing: 12) {
                        ForEach(notesToShow) { note in
                            NavigationLink(destination: NoteEditorView(note: note, backend: backend)) {
                                NoteCardView(note: note, onPin: { togglePin(note) }, onDelete: { deleteNote(note) }, onDuplicate: { duplicateNote(note) })
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(notesToShow) { note in
                            NavigationLink(destination: NoteEditorView(note: note, backend: backend)) {
                                NoteListRowView(note: note)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 16)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Notes")
        .searchable(text: $searchText, prompt: "Search notes…")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewMode = viewMode == .grid ? .list : .grid
                        }
                    } label: {
                        Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                    }
                    Button(action: createNote) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            if let note = backend.selectedNote {
                NavigationStack {
                    NoteEditorView(note: note, backend: backend)
                }
            }
        }
    }

    // MARK: - Actions

    private func createNote() {
        let newNote = backend.createNote()
        backend.selectedNote = newNote
        showingAddNote = true
    }

    private func togglePin(_ note: Note) {
        var updated = note
        updated.isPinned.toggle()
        backend.updateNote(updated)
    }

    private func deleteNote(_ note: Note) {
        backend.deleteNote(note)
    }

    private func duplicateNote(_ note: Note) {
        var copy = note
        copy.id = UUID()
        copy.title = "\(note.title) (Copy)"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.isPinned = false
        backend.notes.append(copy)
        backend.updateNote(copy)
    }
}

// MARK: - Note Card (Grid)

private struct NoteCardView: View {
    let note: Note
    let onPin: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    private var accentColor: Color { note.isPinned ? .orange : .blue }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: note.isPinned ? "pin.fill" : "note.text")
                    .font(.caption)
                    .foregroundColor(accentColor)
                Spacer()
                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(2)

            Text(note.content.isEmpty ? "No content" : note.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor.opacity(0.1))
                                .foregroundColor(accentColor)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .contextMenu {
            Button { onPin() } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            Button { onDuplicate() } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Note List Row

private struct NoteListRowView: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                Text(note.content.isEmpty ? "No content" : note.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }
}

struct FolderChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(14)
        }
    }
}

struct NotesTool: Tool {
    let name = "Notes"
    let icon = "note.text"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Organize and manage your personal notes with markdown and AI summaries"
    let requiresAPI = false

    var view: AnyView { AnyView(NotesView()) }
}

struct NoteEditorView: View {
    @State var note: Note
    @ObservedObject var backend: NotesBackend
    @Environment(\.dismiss) var dismiss

    @State private var showingExportActionSheet = false
    @State private var showingHistory = false
    @State private var summaryText = ""
    @State private var isSummarizing = false
    @State private var newTag = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ToolInputSection("Title & Folder") {
                    VStack(spacing: 12) {
                        TextField("Title", text: $note.title)
                            .font(.title3.bold())
                            .onChange(of: note.title) { _, _ in backend.updateNote(note) }
                        TextField("Folder", text: $note.folder)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: note.folder) { _, _ in backend.updateNote(note) }
                    }
                    .padding()
                }

                ToolInputSection("Tags") {
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(note.tags, id: \.self) { tag in
                                    Button {
                                        note.tags.removeAll { $0 == tag }
                                        backend.updateNote(note)
                                    } label: {
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .padding(6)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        TextField("Add Tag", text: $newTag, onCommit: addTag)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }

                ToolInputSection("Editor") {
                    TextEditor(text: $note.content)
                        .frame(minHeight: 260)
                        .padding(8)
                        .onChange(of: note.content) { _, _ in backend.updateNote(note) }
                }

                markdownToolbar

                if !summaryText.isEmpty {
                    ToolInputSection("AI Summary") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(summaryText)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button("Clear Summary", role: .destructive) { summaryText = "" }
                        }
                        .padding()
                    }
                }

                HStack {
                    Button {
                        isSummarizing = true
                        Task {
                            do {
                                summaryText = try await backend.summarizeNote(note)
                            } catch {
                                summaryText = "Failed to summarize: \(error.localizedDescription)"
                            }
                            isSummarizing = false
                        }
                    } label: {
                        if isSummarizing { ProgressView() } else { Label("AI Summary", systemImage: "sparkles") }
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button(action: { showingHistory = true }) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .buttonStyle(.bordered)

                    Button(action: { showingExportActionSheet = true }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Edit Note")
        .toolbar {
            Button("Done") { dismiss() }
        }
        .sheet(isPresented: $showingHistory) {
            VersionHistoryView(note: note)
        }
        .confirmationDialog("Export Note", isPresented: $showingExportActionSheet) {
            Button("Plain Text (.txt)") { _ = backend.exportAsTXT(note: note) }
            Button("Markdown (.md)") { _ = backend.exportAsMarkdown(note: note) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var markdownToolbar: some View {
        ToolInputSection("Markdown Toolbar") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    markdownButton("bold", icon: "bold", wrapper: "**")
                    markdownButton("italic", icon: "italic", wrapper: "*")
                    markdownButton("code", icon: "curlybraces", wrapper: "`")
                    markdownInsertButton("list.bullet", text: "\n- ")
                    markdownInsertButton("quote.bubble", text: "\n> ")
                    markdownInsertButton("link", text: "[title](https://)")
                }
                .padding()
            }
        }
    }

    private func markdownButton(_ title: String, icon: String, wrapper: String) -> some View {
        Button {
            note.content += "\(wrapper)\(title)\(wrapper)"
            backend.updateNote(note)
        } label: {
            Image(systemName: icon)
        }
        .buttonStyle(.bordered)
    }

    private func markdownInsertButton(_ icon: String, text: String) -> some View {
        Button {
            note.content += text
            backend.updateNote(note)
        } label: {
            Image(systemName: icon)
        }
        .buttonStyle(.bordered)
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty else { return }
        note.tags.append(tag)
        newTag = ""
        backend.updateNote(note)
    }
}

struct VersionHistoryView: View {
    let note: Note
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(note.versionHistory.sorted { $0.timestamp > $1.timestamp }) { version in
                VStack(alignment: .leading) {
                    Text(version.timestamp.formatted())
                        .font(.headline)
                    Text(version.content.prefix(100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Version History")
            .toolbar { Button("Close") { dismiss() } }
        }
    }
}
