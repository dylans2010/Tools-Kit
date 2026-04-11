import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
            (searchText.isEmpty || note.title.localizedCaseInsensitiveContains(searchText)) &&
            (selectedFolder == nil || note.folder == selectedFolder)
        }
    }

    private var pinnedNotes: [Note] {
        filteredNotes.filter { $0.isPinned }
    }

    private var unpinnedNotes: [Note] {
        filteredNotes.filter { !$0.isPinned }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Organize your thoughts into folders and search through your notes easily. Pin important notes to the top for quick access.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FolderChip(title: "All", isSelected: selectedFolder == nil) {
                                selectedFolder = nil
                            }
                            ForEach(folders, id: \.self) { folder in
                                FolderChip(title: folder, isSelected: selectedFolder == folder) {
                                    selectedFolder = folder
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Information & Folders")
            }

            if !pinnedNotes.isEmpty {
                Section(header: Text("Pinned")) {
                    ForEach(pinnedNotes) { note in
                        NavigationLink(destination: NoteEditorView(note: note, backend: backend)) {
                            noteRow(for: note)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                togglePin(note)
                            } label: {
                                Label("Unpin", systemImage: "pin.slash.fill")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }

            Section(header: Text("Notes")) {
                if unpinnedNotes.isEmpty && pinnedNotes.isEmpty {
                    ContentUnavailableView("No Notes", systemImage: "note.text", description: Text("Create your first note by tapping the plus button above."))
                } else {
                    ForEach(unpinnedNotes) { note in
                        NavigationLink(destination: NoteEditorView(note: note, backend: backend)) {
                            noteRow(for: note)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                togglePin(note)
                            } label: {
                                Label("Pin", systemImage: "pin.fill")
                            }
                            .tint(.orange)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
            }
        }
        .navigationTitle("Notes")
        .searchable(text: $searchText)
        .toolbar {
            Button(action: {
                let newNote = backend.createNote()
                backend.selectedNote = newNote
                showingAddNote = true
            }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddNote) {
            if let note = backend.selectedNote {
                if #available(iOS 16.0, macOS 13.0, *) {
                    NavigationStack {
                        NoteEditorView(note: note, backend: backend)
                    }
                } else {
                    NavigationView {
                        NoteEditorView(note: note, backend: backend)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func noteRow(for note: Note) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                Text(note.title)
                    .font(.headline)
            }

            Text(note.content.isEmpty ? "No content" : note.content)
                .lineLimit(2)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if !note.tags.isEmpty {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 8))
                                .padding(3)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func togglePin(_ note: Note) {
        var updated = note
        updated.isPinned.toggle()
        backend.updateNote(updated)
    }

    private func deleteNotes(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = unpinnedNotes[index]
            backend.deleteNote(note)
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
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct NotesTool: Tool {
    let name = "Notes"
    let icon = "note.text"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Organize and manage your personal notes"
    let requiresAPI = false

    var view: AnyView {
        AnyView(NotesView())
    }
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
        VStack {
            TextField("Title", text: $note.title)
                .font(.title)
                .padding(.horizontal)
                .onChange(of: note.title) { _ in backend.updateNote(note) }

            HStack {
                TextField("Folder", text: $note.folder)
                    .font(.subheadline)
                    .padding(8)
                    #if canImport(UIKit)
                    .background(Color(uiColor: .secondarySystemBackground))
                    #else
                    .background(.quaternary)
                    #endif
                    .cornerRadius(8)
                    .onChange(of: note.folder) { _ in backend.updateNote(note) }

                Spacer()

                Button(action: { showingHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            .padding(.horizontal)

            HStack {
                ForEach(note.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                        .onTapGesture {
                            note.tags.removeAll { $0 == tag }
                            backend.updateNote(note)
                        }
                }
                TextField("Add tag...", text: $newTag, onCommit: {
                    if !newTag.isEmpty {
                        note.tags.append(newTag)
                        newTag = ""
                        backend.updateNote(note)
                    }
                })
                .font(.caption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            }
            .padding(.horizontal)

            TextEditor(text: $note.content)
                .padding()
                .border(Color.gray.opacity(0.2))
                .onChange(of: note.content) { _ in
                    // Auto-save logic
                    backend.updateNote(note)
                }

            if !summaryText.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("AI Summary").font(.headline)
                        Spacer()
                        Button(action: { summaryText = "" }) { Image(systemName: "xmark.circle") }
                    }
                    Text(summaryText).font(.subheadline)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            HStack {
                Button(action: {
                    isSummarizing = true
                    backend.summarizeNote(note) { summary in
                        self.summaryText = summary
                        self.isSummarizing = false
                    }
                }) {
                    Label("Summarize", systemImage: "sparkles")
                }
                .disabled(isSummarizing)

                Spacer()

                Button(action: { showingExportActionSheet = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
            .padding()
        }
        .navigationTitle("Edit Note")
        .toolbar {
            Button("Done") {
                dismiss()
            }
        }
        .sheet(isPresented: $showingHistory) {
            VersionHistoryView(note: note)
        }
        .confirmationDialog("Export Note", isPresented: $showingExportActionSheet) {
            Button("Plain Text (.txt)") {
                if let url = backend.exportAsTXT(note: note) {
                    print("Exported to \(url)")
                }
            }
            Button("Markdown (.md)") {
                if let url = backend.exportAsMarkdown(note: note) {
                    print("Exported to \(url)")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct VersionHistoryView: View {
    let note: Note
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }

    private var content: some View {
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
        .toolbar {
            Button("Close") { dismiss() }
        }
    }
}
