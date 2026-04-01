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

    var body: some View {
        List {
            Section(header: Text("Folders")) {
                ForEach(folders, id: \.self) { folder in
                    Button(action: {
                        selectedFolder = (selectedFolder == folder) ? nil : folder
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text(folder)
                            Spacer()
                            if selectedFolder == folder {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section(header: Text("Notes")) {
                ForEach(filteredNotes) { note in
                    NavigationLink(destination: NoteEditorView(note: note, backend: backend)) {
                        noteRow(for: note)
                    }
                }
                .onDelete(perform: deleteNotes)
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
                NavigationStack {
                    NoteEditorView(note: note, backend: backend)
                }
            }
        }
    }

    @ViewBuilder
    private func noteRow(for note: Note) -> some View {
        VStack(alignment: .leading) {
            Text(note.title)
                .font(.headline)
            Text(note.content.prefix(50))
                .font(.caption)
                .foregroundColor(.secondary)
            if !note.tags.isEmpty {
                HStack {
                    ForEach(note.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10))
                            .padding(4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = filteredNotes[index]
            backend.deleteNote(note)
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
        NavigationStack {
            List(Array(note.versionHistory.reversed())) { version in
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
}
