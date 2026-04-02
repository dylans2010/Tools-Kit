import SwiftUI

struct SecureNotesView: View {
    @StateObject private var backend = SecureNotesBackend()
    @State private var showingAddNote = false
    @State private var newTitle = ""
    @State private var newContent = ""

    var body: some View {
        Group {
            if backend.isAuthenticated {
                notesList
            } else {
                authView
            }
        }
        .navigationTitle("Secure Notes")
        .sheet(isPresented: $showingAddNote) {
            addNoteSheet
        }
    }

    private var authView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Your notes are encrypted and secured.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: backend.authenticate) {
                Label("Unlock with FaceID / Passcode", systemImage: "faceid")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            if let error = backend.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    private var notesList: some View {
        List {
            ForEach(backend.notes) { note in
                VStack(alignment: .leading) {
                    Text(note.title).font(.headline)
                    Text(note.content).font(.subheadline).lineLimit(2).foregroundColor(.secondary)
                    Text(note.date, style: .date).font(.caption2).foregroundColor(.tertiaryLabel)
                }
            }
            .onDelete(perform: backend.deleteNote)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Lock") {
                    backend.lock()
                }
            }
        }
    }

    private var addNoteSheet: some View {
        NavigationView {
            Form {
                TextField("Title", text: $newTitle)
                TextEditor(text: $newContent)
                    .frame(height: 200)
            }
            .navigationTitle("New Secure Note")
            .toolbar {
                Button("Cancel") { showingAddNote = false }
                Button("Save") {
                    backend.addNote(title: newTitle, content: newContent)
                    newTitle = ""
                    newContent = ""
                    showingAddNote = false
                }
                .disabled(newTitle.isEmpty)
            }
        }
    }
}

struct SecureNotesTool: Tool {
    let name = "Secure Notes"
    let icon = "lock.rectangle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Store private notes behind biometric authentication"
    let requiresAPI = false
    var view: AnyView { AnyView(SecureNotesView()) }
}
