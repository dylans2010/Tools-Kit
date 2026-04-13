import SwiftUI

struct NotesView: View {
    @StateObject private var backend = NotesBackend()
    @State private var showingAddNote = false
    @State private var searchText = ""
    @State private var selectedFolder: String? = nil

    private var folders: [String] {
        Array(Set(backend.notes.map { $0.folder })).sorted()
    }

    private var filteredNotes: [Note] {
        backend.notes.filter { note in
            (searchText.isEmpty || note.title.localizedCaseInsensitiveContains(searchText) || note.content.localizedCaseInsensitiveContains(searchText)) &&
            (selectedFolder == nil || note.folder == selectedFolder)
        }
    }

    var body: some View {
        ToolDetailView(tool: NotesTool()) {
            VStack(spacing: 16) {
                ToolInputSection("Folders") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FolderChip(title: "All", isSelected: selectedFolder == nil) { selectedFolder = nil }
                            ForEach(folders, id: \.self) { folder in
                                FolderChip(title: folder, isSelected: selectedFolder == folder) { selectedFolder = folder }
                            }
                        }
                        .padding()
                    }
                }

                ToolInputSection("Notes") {
                    if filteredNotes.isEmpty {
                        ContentUnavailableView("No Notes", systemImage: "note.text", description: Text("Create your first note with the + button."))
                            .padding()
                    } else {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteEditorView(note: note, backend: backend)) {
                                noteRow(for: note)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            if note.id != filteredNotes.last?.id { Divider() }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notes")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let newNote = backend.createNote()
                    backend.selectedNote = newNote
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus")
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

    @ViewBuilder
    private func noteRow(for note: Note) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: note.isPinned ? "pin.fill" : "note.text")
                    .foregroundColor(note.isPinned ? .orange : .blue)
                Text(note.title)
                    .font(.headline)
                Spacer()
                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(note.content.isEmpty ? "No Content" : note.content)
                .lineLimit(2)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
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
                            .onChange(of: note.title) { _ in backend.updateNote(note) }
                        TextField("Folder", text: $note.folder)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: note.folder) { _ in backend.updateNote(note) }
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
                        .onChange(of: note.content) { _ in backend.updateNote(note) }
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
